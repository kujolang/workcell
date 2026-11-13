import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';
import { once } from 'node:events';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// Also run against the actual clean-installed release candidate, not fixture mode.
const root = path.resolve(process.env.WORKCELL_ADAPTER_PACKAGE_ROOT || path.join(import.meta.dirname, '..'));
const require = createRequire(path.join(root, 'package.json'));
const { Sandbox } = await import(require.resolve('e2b'));
const { e2b } = await import(pathToFileURL(path.join(root, 'runtime/providers.mjs')));
const ownership = { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'owned-nonce' };
const metadata = { 'workcell.run_id': ownership.run_id, 'workcell.nonce': ownership.nonce };
const req = { run_id: ownership.run_id, deadline_ms: 10000, profile: { credential_ref: 'env:WORKCELL_TEST_E2B_CREDENTIAL' }, payload: { ownership } };
const owned = id => ({ sandboxId: id, metadata, state: 'running' });
function credential(t) {
  const prior = process.env.WORKCELL_TEST_E2B_CREDENTIAL;
  process.env.WORKCELL_TEST_E2B_CREDENTIAL = 'offline-fixture';
  t.after(() => { if (prior === undefined) delete process.env.WORKCELL_TEST_E2B_CREDENTIAL; else process.env.WORKCELL_TEST_E2B_CREDENTIAL = prior; });
}
function mockPager(t, pages, options = {}) {
  credential(t);
  let calls = 0;
  const pager = { get hasNext() { return options.endless || calls < pages.length; },
    get nextToken() { return options.repeated ? 'repeated' : `page-${calls}`; },
    async nextItems({ signal, requestTimeoutMs }) { assert.ok(signal instanceof AbortSignal); assert.ok(requestTimeoutMs > 0 && requestTimeoutMs <= 30000); return pages[calls++ % pages.length]; } };
  t.mock.method(Sandbox, 'list', args => { assert.equal(args.limit, 100); assert.deepEqual(args.query.metadata, metadata); return pager; });
  return () => calls;
}

test('actual E2B SDK follows multiple HTTP pages and rechecks exact ownership', async t => {
  credential(t);
  const requests = [];
  const server = createServer((request, response) => {
    const url = new URL(request.url, 'http://localhost'); requests.push(url);
    assert.equal(url.pathname, '/v2/sandboxes');
    assert.equal(url.searchParams.get('limit'), '100');
    assert.deepEqual(Object.fromEntries(new URLSearchParams(url.searchParams.get('metadata'))), metadata);
    const page = requests.length;
    const items = page === 1 ? [owned('one'), { ...owned('foreign-run'), metadata: { ...metadata, 'workcell.run_id': 'another-run' } }, { ...owned('foreign-nonce'), metadata: { ...metadata, 'workcell.nonce': 'another-nonce' } }, { sandboxId: 'unmarked' }] : page === 2 ? [] : [owned('one'), owned('two')];
    if (page < 3) response.setHeader('x-next-token', `next-${page}`);
    response.setHeader('Content-Type', 'application/json');
    response.end(JSON.stringify(items.map(({ sandboxId, ...item }) => ({ ...item, sandboxID: sandboxId, templateID: 'fixture', startedAt: '2026-01-01T00:00:00Z', endAt: '2026-01-02T00:00:00Z' }))));
  });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  t.after(() => { server.closeAllConnections(); server.close(); });
  const list = Sandbox.list.bind(Sandbox);
  t.mock.method(Sandbox, 'list', opts => list({ ...opts, apiUrl: `http://127.0.0.1:${server.address().port}` }));
  const result = await e2b.inventory(req);
  assert.deepEqual(result, { complete: true, resources: ['one', 'two'].map(id => ({ kind: 'sandbox', id, state: 'running', ownership })) });
  assert.deepEqual(requests.map(url => url.searchParams.get('nextToken')), [null, 'next-1', 'next-2']);
});

test('terminal empty inventory is complete', async t => {
  const calls = mockPager(t, [[]]);
  assert.deepEqual(await e2b.inventory(req), { resources: [], complete: true });
  assert.equal(calls(), 1);
});

test('page limit bounds nonterminating inventory without claiming completeness', async t => {
  const pages = Array.from({ length: 10 }, (_, page) => Array.from({ length: 100 }, (_, item) => owned(`owned-${page}-${item}`)));
  const calls = mockPager(t, pages, { endless: true });
  const result = await e2b.inventory(req);
  assert.equal(calls(), 10); assert.equal(result.complete, false); assert.equal(result.resources.length, 1000);
});

test('exactly ten exhausted pages may be complete', async t => {
  const calls = mockPager(t, Array.from({ length: 10 }, (_, i) => [owned(`owned-${i}`)]));
  const result = await e2b.inventory(req);
  assert.equal(calls(), 10); assert.equal(result.complete, true); assert.equal(result.resources.length, 10);
});

test('repeated continuation stops early as incomplete', async t => {
  const calls = mockPager(t, [[]], { endless: true, repeated: true });
  assert.equal((await e2b.inventory(req)).complete, false); assert.equal(calls(), 2);
});

test('oversized and malformed pages fail closed', async t => {
  for (const page of [Array.from({ length: 101 }, () => owned('one')), {}, [null], [{ ...owned('one'), sandboxId: '' }]]) {
    await t.test(JSON.stringify(page).slice(0, 40), async child => {
      mockPager(child, [page]);
      await assert.rejects(e2b.inventory(req), { code: 'INVENTORY_INVALID' });
    });
  }
});

test('provider failure after an owned page is not a complete partial result', async t => {
  credential(t); let calls = 0;
  t.mock.method(Sandbox, 'list', () => ({ hasNext: true, async nextItems() { if (calls++) throw new Error('provider failure'); return [owned('one')]; } }));
  await assert.rejects(e2b.inventory(req), /provider failure/); assert.equal(calls, 2);
});

test('total deadline aborts even a nonresponsive page and never advances', async t => {
  credential(t); let calls = 0, signal;
  t.mock.method(Sandbox, 'list', () => ({ hasNext: true, nextItems(opts) { calls++; signal = opts.signal; return new Promise(() => {}); } }));
  await assert.rejects(e2b.inventory({ ...req, deadline_ms: 25 }), { code: 'INVENTORY_TIMEOUT' });
  assert.equal(calls, 1); assert.equal(signal.aborted, true);
});

test('invalid pagination state cannot become an empty complete inventory', async t => {
  credential(t); t.mock.method(Sandbox, 'list', () => ({ hasNext: undefined }));
  await assert.rejects(e2b.inventory(req), { code: 'INVENTORY_INVALID' });
});


test('one deadline and abort signal cover all pages, not a fresh budget per page', async t => {
  credential(t); let calls = 0, signal;
  t.mock.method(Sandbox, 'list', () => ({ hasNext: true, async nextItems(opts) {
    calls++;
    if (calls === 1) { signal = opts.signal; await new Promise(resolve => setTimeout(resolve, 10)); return [owned('one')]; }
    assert.equal(opts.signal, signal);
    return new Promise(() => {});
  } }));
  await assert.rejects(e2b.inventory({ ...req, deadline_ms: 80 }), { code: 'INVENTORY_TIMEOUT' });
  assert.equal(calls, 2); assert.equal(signal.aborted, true);
});

test('actual SDK aborts an outstanding HTTP page at the inventory deadline', async t => {
  credential(t);
  let closed;
  const disconnected = new Promise(resolve => { closed = resolve; });
  const server = createServer((request, response) => { response.on('close', closed); });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  t.after(() => { server.closeAllConnections(); server.close(); });
  const list = Sandbox.list.bind(Sandbox);
  t.mock.method(Sandbox, 'list', opts => list({ ...opts, apiUrl: `http://127.0.0.1:${server.address().port}` }));
  await assert.rejects(e2b.inventory({ ...req, deadline_ms: 500 }));
  await Promise.race([disconnected, new Promise((_, reject) => {
    const timer = setTimeout(() => reject(new Error('SDK did not close the aborted page')), 2000);
    t.after(() => clearTimeout(timer));
  })]);
});
