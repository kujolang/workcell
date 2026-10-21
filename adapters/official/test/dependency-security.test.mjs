import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createRequire } from 'node:module';
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { once } from 'node:events';
import os from 'node:os';
import path from 'node:path';

// The release gate also runs these tests against a clean installed tarball.
const root = path.resolve(process.env.WORKCELL_ADAPTER_PACKAGE_ROOT || path.join(import.meta.dirname, '..'));
const require = createRequire(path.join(root, 'package.json'));
const { quote, parse } = require('shell-quote');
const braces = require('braces');
const guarded = error => error instanceof SyntaxError && error.code === 'ERR_BRACES_DEPTH';

test('bundled shell quoting rejects line termination after a comment token', () => {
  // GHSA-pqg4-j6r4-53mv: never execute the generated string in this regression.
  for (const terminator of ['\n', '\r', '\u2028', '\u2029']) {
    assert.throws(() => quote([{ comment: 'observed' }, `${terminator}echo injected`]), TypeError);
  }
});

test('bundled shell quoting preserves ordinary literal command arguments', () => {
  const args = ['printf', '%s', 'a b', "single'quote", '$literal', ';literal'];
  assert.deepEqual(parse(quote(args)), args);
});

test('every bundled Braces copy is the guarded fork and redirect transport is patched', () => {
  let copies = 0;
  function inspect(directory) {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) inspect(file);
      if (entry.name !== 'package.json' || !file.endsWith('/braces/package.json')) continue;
      const pkg = JSON.parse(readFileSync(file));
      assert.equal(pkg.name, '@kujolang/braces-depth-guard');
      assert.equal(pkg.version, '3.0.3+kujo.1');
      copies++;
    }
  }
  inspect(path.join(root, 'node_modules'));
  assert.ok(copies > 0, 'the guarded fork must be bundled as real files');
  assert.equal(require('follow-redirects/package.json').version, '1.16.1');
});

test('deep braces, parentheses and unclosed patterns fail before stack exhaustion', () => {
  for (const [open, close] of [['{', '}'], ['(', ')']]) {
    for (const input of [open.repeat(4000) + 'x' + close.repeat(4000), open.repeat(4000) + 'x']) {
      for (const fn of [braces, braces.parse, braces.compile, braces.expand, braces.stringify]) {
        assert.throws(() => fn(input, { maxDepth: Infinity }), guarded);
      }
    }
  }
  assert.throws(() => braces(['{a,b}', '{'.repeat(4000)]), guarded);
});

test('direct AST and internal walker entry points retain the depth bound', () => {
  const localRequire = createRequire(require.resolve('braces'));
  for (const operation of ['compile', 'expand', 'stringify']) {
    for (const fn of [braces[operation], localRequire('./lib/' + operation)]) {
      const ast = { type: 'root', nodes: [] };
      let node = ast;
      for (let i = 0; i < 10000; i++) {
        const child = { type: 'brace', nodes: [], parent: node, commas: 1, ranges: 0 };
        node.nodes.push(child); node = child;
      }
      node.nodes.push({ type: 'text', value: 'x' });
      assert.throws(() => fn(ast), guarded);
    }
  }
});

test('normal patterns and Daytona COPY discovery remain compatible', async () => {
  assert.deepEqual(braces.expand('app/{pages,articles}/{a,b}.tsx'), ['app/pages/a.tsx', 'app/pages/b.tsx', 'app/articles/a.tsx', 'app/articles/b.tsx']);
  assert.deepEqual(braces.expand('v{1..3}'), ['v1', 'v2', 'v3']);
  assert.deepEqual(braces.expand('{a,{b,c}}'), ['a', 'b', 'c']);
  assert.deepEqual(braces.expand('\\{literal\\}'), ['{literal}']);
  assert.equal(braces.stringify(braces.parse('a/{b,c}')), 'a/{b,c}');
  assert.throws(() => braces.expand('{1..10000}'), /range limit/);
  const glob = require('fast-glob');
  const micromatch = require('micromatch');
  const { Image } = require('@daytona/sdk');
  const directory = mkdtempSync(path.join(os.tmpdir(), 'workcell-glob-security-'));
  try {
    writeFileSync(path.join(directory, 'a.txt'), 'a');
    writeFileSync(path.join(directory, 'b.txt'), 'b');
    assert.deepEqual(glob.sync('{a,b}.txt', { cwd: directory }).sort(), ['a.txt', 'b.txt']);
    assert.deepEqual((await glob('{a,b}.txt', { cwd: directory })).sort(), ['a.txt', 'b.txt']);
    assert.deepEqual(Image.extractCopySources('COPY {a,b}.txt /app', directory).map(row => path.basename(row[0])).sort(), ['a.txt', 'b.txt']);
    const malicious = '{'.repeat(4000) + 'a,b' + '}'.repeat(4000);
    assert.throws(() => micromatch.braces(malicious), guarded);
    assert.throws(() => glob.sync(malicious, { cwd: directory }), guarded);
    await assert.rejects(async () => glob(malicious, { cwd: directory }), guarded);
    assert.throws(() => Image.extractCopySources(`COPY ${malicious} /app`, directory), guarded);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test('redirects strip object and array credentials without stripping ordinary headers', async () => {
  const transport = require('follow-redirects').http;
  const destination = createServer((req, res) => res.end(JSON.stringify(req.headers)));
  const origin = createServer((req, res) => {
    if (req.url === '/same') return res.end(JSON.stringify(req.headers));
    res.writeHead(302, { location: req.url === '/control'
      ? `http://127.0.0.1:${origin.address().port}/same`
      : `http://127.0.0.1:${destination.address().port}/` });
    res.end();
  });
  const headers = { Authorization: 'fixture-auth', Cookie: 'fixture-cookie', 'Proxy-Authorization': 'fixture-proxy', 'X-Api^Key': 'fixture-caret', 'X-Token|Secret': 'fixture-pipe', 'X-Ordinary': 'keep', 'X-Token': 'keep-neighbor', Secret: 'keep-neighbor' };
  const request = (route, values) => new Promise((resolve, reject) => {
    const req = transport.get(`http://127.0.0.1:${origin.address().port}/${route}`, {
      headers: values, sensitiveHeaders: ['X-Api^Key', 'X-Token|Secret'], timeout: 5000
    }, response => {
      let body = '';
      response.on('data', chunk => { body += chunk; });
      response.on('end', () => { try { resolve(JSON.parse(body)); } catch (error) { reject(error); } });
      response.on('error', reject);
    });
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('local redirect fixture timed out')));
  });
  try {
    destination.listen(0, '127.0.0.1'); await once(destination, 'listening');
    origin.listen(0, '127.0.0.1'); await once(origin, 'listening');
    for (const values of [{ ...headers }, Object.entries(headers).flat()]) {
      const received = await request('cross', values);
      for (const name of ['authorization', 'cookie', 'proxy-authorization', 'x-api^key', 'x-token|secret']) assert.equal(received[name], undefined, name);
      for (const name of ['x-ordinary', 'x-token', 'secret']) assert.ok(received[name]?.startsWith('keep'), name);
    }
    const same = await request('control', { ...headers });
    assert.equal(same.authorization, headers.Authorization);
    assert.equal(same['x-api^key'], headers['X-Api^Key']);
  } finally {
    origin.closeAllConnections(); destination.closeAllConnections();
    await Promise.all([origin, destination].map(server => new Promise(resolve => server.close(resolve))));
  }
});
