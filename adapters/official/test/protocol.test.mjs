import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, copyFile, mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { test } from 'node:test';
import { Readable } from 'node:stream';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { archiveDownloadLimit, writeBoundedStream } from '../runtime/protocol.mjs';
import { boundLogs, ownedMetadata, parseWorkspaceStatus } from '../runtime/providers.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const adapterEntry = path.join(root, 'runtime', 'adapter.mjs');
const requirements = ['lifecycle.provision','lifecycle.terminate','lifecycle.destroy','lifecycle.inventory','workspace.stage','workspace.collect_delta','process.argv','process.exit_status','execution.timeout','logs.bounded','artifact.selective_export','environment.explicit','credentials.redacted_transport','evidence.provider_identity','ownership.markers'].map((id) => ({ id, requested: true, required: true, value: true }));

function call(provider, operation, payload = {}, profile = { fixture_mode: true }, environment = {}) {
  const req = { contract: 'workcell-backend/v1alpha1', request_id: `test-${operation}`, run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', operation, deadline_ms: 10000, profile, payload };
  const result = spawnSync(path.join(root, provider, `workcell-backend-${provider}`), ['protocol'], { input: `${JSON.stringify(req)}\n`, encoding: 'utf8', env: { PATH: process.env.PATH, ...environment } });
  assert.equal(result.status, 0);
  const lines = result.stdout.trim().split('\n').map(JSON.parse);
  return { req, events: lines.filter((x) => x.type === 'event'), result: lines.at(-1) };
}

function callAsync(provider, runId, operation, payload, profile = { fixture_mode: true }) {
  const req = { contract: 'workcell-backend/v1alpha1', request_id: `load-${runId}-${operation}`, run_id: runId, operation, deadline_ms: 10000, profile, payload };
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [adapterEntry, provider, 'protocol'], { stdio: ['pipe', 'pipe', 'pipe'], env: {} });
    let stdout = '';
    let stderr = '';
    child.stdout.setEncoding('utf8').on('data', (chunk) => { stdout += chunk; });
    child.stderr.setEncoding('utf8').on('data', (chunk) => { stderr += chunk; });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code !== 0) return reject(new Error(`fixture adapter exited ${code}: ${stderr}`));
      const lines = stdout.trim().split('\n').map(JSON.parse);
      resolve(lines.at(-1));
    });
    child.stdin.end(`${JSON.stringify(req)}\n`);
  });
}

for (const provider of ['e2b', 'vercel-sandbox', 'daytona']) {
  test(`${provider} describes and resolves offline`, () => {
    assert.equal(call(provider, 'describe').result.data.adapter.id, provider);
    const resolved = call(provider, 'resolve', { requirements, intent: {} });
    assert.equal(resolved.result.ok, true);
    assert.equal(resolved.result.data.capabilities.length, requirements.length);
    assert.ok(resolved.result.data.capabilities.every((x) => x.acceptance === 'accepted'));
    assert.equal(resolved.result.data.cost.status, 'unknown');
    assert.equal(resolved.result.data.cost.amount, null);
  });
  test(`${provider} fixture lifecycle preserves ownership`, () => {
    const ownership = { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'nonce-test' };
    const provisioned = call(provider, 'provision', { ownership, resolved_plan: {}, idempotency_key: 'test' }).result.data;
    assert.deepEqual(provisioned.handle.ownership, ownership);
    const executed = call(provider, 'execute', { handle: provisioned.handle, attempt_id: 'attempt-1', argv: ['true'], workdir: '/workspace', environment: {}, secret_channel: [], timeout_ms: 1000, max_output_bytes: 65536 });
    assert.equal(executed.result.data.terminal.exit_code, 0);
    assert.equal(executed.events.length, 1);
    const destroyed = call(provider, 'destroy', { handle: provisioned.handle, expected_ownership: ownership, idempotency_key: 'test-destroy' }).result.data;
    assert.deepEqual(destroyed.remaining, []);
  });
}

test('live mode never accepts missing provider credentials', () => {
  const result = call('e2b', 'provision', { ownership: { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'nonce-test' }, resolved_plan: {}, idempotency_key: 'test-provision' }, { credential_ref: 'env:E2B_API_KEY' });
  assert.equal(result.result.ok, false);
  assert.equal(result.result.error.code, 'AUTH_MISSING');
  assert.equal(result.stdout?.includes?.('secret'), undefined);
});

test('profile validation rejects unknown provider fields before provisioning', () => {
  const result = call('e2b', 'resolve', { requirements, intent: {} }, { fixture_mode: true, vendor_escape_hatch: true });
  assert.equal(result.result.ok, false);
  assert.equal(result.result.error.code, 'PROFILE_INVALID');
});

test('profile validation rejects routing fields an adapter does not implement', () => {
  const result = call('e2b', 'resolve', { requirements, intent: {} }, { fixture_mode: true, region: 'us-east' });
  assert.equal(result.result.ok, false);
  assert.equal(result.result.error.code, 'PROFILE_INVALID');
});

test('live resolution keeps operator guarantees claimed and unobserved', () => {
  const result = call('e2b', 'resolve', { requirements: [{ id: 'compute.cpu_limit', requested: true, required: true, value: 2 }], intent: {} }, { guarantees: { 'compute.cpu_limit': 2 } });
  const state = result.result.data.capabilities[0];
  assert.equal(state.acceptance, 'accepted');
  assert.equal(state.enforcement.status, 'operator-claimed');
  assert.equal(state.observation.status, 'not-observed');
});

test('vercel memory requires an exact operator guarantee', () => {
  const wanted = [{ id: 'compute.memory_limit', requested: true, required: true, value: '512m' }];
  const rejected = call('vercel-sandbox', 'resolve', { requirements: wanted, intent: {} }, {});
  assert.equal(rejected.result.data.capabilities[0].acceptance, 'rejected');
  const accepted = call('vercel-sandbox', 'resolve', { requirements: wanted, intent: {} }, { guarantees: { 'compute.memory_limit': '512m' } });
  assert.equal(accepted.result.data.capabilities[0].enforcement.status, 'operator-claimed');
});

test('adapter errors redact workload and provider secrets', () => {
  const req = { contract: 'workcell-backend/v1alpha1', request_id: 'test-redaction', run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', operation: 'execute', deadline_ms: 10000, profile: { credential_ref: 'env:E2B_API_KEY' }, payload: { handle: {}, attempt_id: 'attempt-1', argv: ['true'], workdir: '/workspace', environment: {}, secret_channel: ['WORKLOAD_TOKEN'], timeout_ms: 1000, max_output_bytes: 65536 } };
  const result = spawnSync(path.join(root, 'e2b', 'workcell-backend-e2b'), ['protocol'], { input: `${JSON.stringify(req)}\n`, encoding: 'utf8', env: { E2B_API_KEY: 'provider-secret-value', WORKLOAD_TOKEN: 'workload-secret-value' } });
  assert.equal(result.stdout.includes('provider-secret-value'), false);
  assert.equal(result.stdout.includes('workload-secret-value'), false);
});

test('adapter log events redact raw and encoded workload secrets', () => {
  const secret = 'workload-secret-value';
  const providerSecret = 'provider-secret-value';
  const encoded = Buffer.from(secret).toString('base64');
  const execution = call('e2b', 'execute', { handle: { resource_ids: [], ownership: {} }, attempt_id: 'attempt-1', argv: ['true'], workdir: '/workspace', environment: {}, secret_channel: ['WORKLOAD_TOKEN'], timeout_ms: 1000, max_output_bytes: 65536 }, { fixture_mode: true, fixture_stdout: `raw=${secret} encoded=${encoded} provider=${providerSecret}` }, { E2B_API_KEY: providerSecret, WORKLOAD_TOKEN: secret });
  assert.equal(execution.events.length, 1);
  const decoded = Buffer.from(execution.events[0].bytes_base64, 'base64').toString('utf8');
  assert.equal(decoded.includes(secret), false);
  assert.equal(decoded.includes(encoded), false);
  assert.equal(decoded.includes(providerSecret), false);
  assert.equal(decoded, 'raw=[REDACTED] encoded=[REDACTED] provider=[REDACTED]');
});

test('artifact transport streams within an explicit bound', async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'workcell-adapter-stream-'));
  const destination = path.join(directory, 'artifacts.tar');
  const result = await writeBoundedStream(destination, Readable.from([Buffer.from('abc'), Buffer.from('def')]), 6);
  assert.equal(result.bytes, 6);
  assert.equal((await readFile(destination)).toString('utf8'), 'abcdef');
  assert.ok(archiveDownloadLimit({ max_bytes: 10, max_files: 1 }) > 10);
});

test('artifact transport aborts and removes an oversized partial file', async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'workcell-adapter-stream-'));
  const destination = path.join(directory, 'artifacts.tar');
  await assert.rejects(writeBoundedStream(destination, Readable.from([Buffer.alloc(4), Buffer.alloc(4)]), 7), { code: 'ARTIFACT_LIMIT' });
  await assert.rejects(access(destination));
});

test('provider log normalization enforces one combined byte bound', () => {
  const bounded = boundLogs('abcdef', 'ghij', 8);
  assert.equal(Buffer.byteLength(bounded.stdout) + Buffer.byteLength(bounded.stderr), 8);
  assert.equal(bounded.stdout, 'abcdef');
  assert.equal(bounded.stderr, 'gh');
  assert.equal(bounded.truncated, true);
});

test('workspace delta parser preserves modified, untracked, and rename paths', () => {
  assert.deepEqual(parseWorkspaceStatus(' M changed.txt\0?? new.txt\0R  old.txt\0renamed.txt\0'), ['changed.txt', 'new.txt', 'old.txt', 'renamed.txt']);
  assert.throws(() => parseWorkspaceStatus('malformed\0'), { code: 'WORKSPACE_COLLECT' });
});

test('recovery inventory requires both run and nonce ownership markers', () => {
  const ownership = { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'nonce-test' };
  assert.equal(ownedMetadata({ run: ownership.run_id, nonce: ownership.nonce }, ownership, 'run', 'nonce'), true);
  assert.equal(ownedMetadata({ run: ownership.run_id, nonce: 'wrong' }, ownership, 'run', 'nonce'), false);
  assert.equal(ownedMetadata(undefined, ownership, 'run', 'nonce'), false);
});

test('official manifests pin their executable wrapper digests', async () => {
  for (const provider of ['e2b', 'vercel-sandbox', 'daytona']) {
    const manifest = JSON.parse(await readFile(path.join(root, provider, 'manifest.json'), 'utf8'));
    const executable = await readFile(path.join(root, provider, manifest.executable));
    assert.equal(manifest.digest, `sha256:${createHash('sha256').update(executable).digest('hex')}`);
  }
});

test('official runtime integrity verification fails closed on tampering', async () => {
  const temporaryRoot = await mkdtemp(path.join(os.tmpdir(), 'workcell-adapter-integrity-'));
  await mkdir(path.join(temporaryRoot, 'runtime'));
  for (const relative of ['runtime/adapter.mjs', 'runtime/protocol.mjs', 'runtime/providers.mjs', 'package.json', 'package-lock.json']) {
    await copyFile(path.join(root, relative), path.join(temporaryRoot, relative));
  }
  const verifier = path.join(root, 'runtime', 'verify-integrity.sh');
  assert.equal(spawnSync(verifier, [temporaryRoot], { encoding: 'utf8' }).status, 0);
  await writeFile(path.join(temporaryRoot, 'runtime', 'protocol.mjs'), '// tampered\n');
  const tampered = spawnSync(verifier, [temporaryRoot], { encoding: 'utf8' });
  assert.equal(tampered.status, 70);
  assert.match(tampered.stderr, /integrity check failed/);
});

test('protocol parser fails closed for a deterministic malformed corpus', () => {
  const valid = { contract: 'workcell-backend/v1alpha1', request_id: 'fuzz-request', run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', operation: 'describe', deadline_ms: 1000, profile: {}, payload: {} };
  const corpus = [
    '', '{', 'null', '[]', 'true',
    JSON.stringify({ ...valid, contract: 'workcell-backend/v0' }),
    JSON.stringify({ ...valid, run_id: 'wc-bad' }),
    JSON.stringify({ ...valid, deadline_ms: 0 }),
    JSON.stringify({ ...valid, vendor: true }),
    JSON.stringify({ ...valid, operation: 'exec' }),
    JSON.stringify({ ...valid, payload: [] }),
    JSON.stringify({ ...valid, profile: { unknown: true } }),
    `${' '.repeat(1_048_577)}{}`
  ];
  for (const input of corpus) {
    const result = spawnSync(process.execPath, [adapterEntry, 'e2b', 'protocol'], { input, encoding: 'utf8', env: {} });
    assert.equal(result.status, 0);
    const lines = result.stdout.trim().split('\n');
    assert.equal(lines.length, 1);
    const frame = JSON.parse(lines[0]);
    assert.equal(frame.ok, false);
    assert.ok(['PROTOCOL_VIOLATION', 'PROFILE_INVALID'].includes(frame.error.code));
    assert.equal(result.stderr, '');
  }
});

test('concurrent fixture lifecycles remain ownership-isolated and leak-free', async () => {
  const runs = Array.from({ length: 8 }, (_, index) => {
    const runId = `wc-${String(index + 1).padStart(32, '0')}`;
    return { runId, ownership: { run_id: runId, nonce: `load-${index + 1}` } };
  });
  const provisioned = await Promise.all(runs.map(({ runId, ownership }) => callAsync('e2b', runId, 'provision', { ownership, resolved_plan: {}, idempotency_key: `${runId}:provision` })));
  assert.ok(provisioned.every((frame) => frame.ok));
  assert.equal(new Set(provisioned.map((frame) => frame.data.handle.resource_ids[0].id)).size, runs.length);
  const inventories = await Promise.all(runs.map(({ runId, ownership }) => callAsync('e2b', runId, 'inventory', { ownership })));
  assert.ok(inventories.every((frame) => frame.ok && frame.data.complete && frame.data.resources.length === 1));
  const destroyed = await Promise.all(runs.map(({ runId, ownership }, index) => callAsync('e2b', runId, 'destroy', { handle: provisioned[index].data.handle, expected_ownership: ownership, idempotency_key: `${runId}:destroy` })));
  assert.ok(destroyed.every((frame) => frame.ok && frame.data.remaining.length === 0));
  const empty = await Promise.all(runs.map(({ runId, ownership }) => callAsync('e2b', runId, 'inventory', { ownership })));
  assert.ok(empty.every((frame) => frame.ok && frame.data.complete && frame.data.resources.length === 0));
});
