import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { access, mkdtemp, readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { Readable } from 'node:stream';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { archiveDownloadLimit, writeBoundedStream } from '../runtime/protocol.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const requirements = ['lifecycle.provision','lifecycle.terminate','lifecycle.destroy','lifecycle.inventory','workspace.stage','workspace.collect_delta','process.argv','process.exit_status','execution.timeout','logs.bounded','artifact.selective_export','environment.explicit','credentials.redacted_transport','evidence.provider_identity','ownership.markers'].map((id) => ({ id, requested: true, required: true, value: true }));

function call(provider, operation, payload = {}, profile = { fixture_mode: true }, environment = {}) {
  const req = { contract: 'workcell-backend/v1alpha1', request_id: `test-${operation}`, run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', operation, deadline_ms: 10000, profile, payload };
  const result = spawnSync(path.join(root, provider, `workcell-backend-${provider}`), ['protocol'], { input: `${JSON.stringify(req)}\n`, encoding: 'utf8', env: environment });
  assert.equal(result.status, 0);
  const lines = result.stdout.trim().split('\n').map(JSON.parse);
  return { req, events: lines.filter((x) => x.type === 'event'), result: lines.at(-1) };
}

for (const provider of ['e2b', 'vercel-sandbox', 'daytona']) {
  test(`${provider} describes and resolves offline`, () => {
    assert.equal(call(provider, 'describe').result.data.adapter.id, provider);
    const resolved = call(provider, 'resolve', { requirements, intent: {} });
    assert.equal(resolved.result.ok, true);
    assert.equal(resolved.result.data.capabilities.length, requirements.length);
    assert.ok(resolved.result.data.capabilities.every((x) => x.acceptance === 'accepted'));
  });
  test(`${provider} fixture lifecycle preserves ownership`, () => {
    const ownership = { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'nonce-test' };
    const provisioned = call(provider, 'provision', { ownership, resolved_plan: {}, idempotency_key: 'test' }).result.data;
    assert.deepEqual(provisioned.handle.ownership, ownership);
    const executed = call(provider, 'execute', { handle: provisioned.handle, argv: ['true'], workdir: '/workspace', environment: {}, timeout_ms: 1000 });
    assert.equal(executed.result.data.terminal.exit_code, 0);
    assert.equal(executed.events.length, 1);
    const destroyed = call(provider, 'destroy', { handle: provisioned.handle, expected_ownership: ownership }).result.data;
    assert.deepEqual(destroyed.remaining, []);
  });
}

test('live mode never accepts missing provider credentials', () => {
  const result = call('e2b', 'provision', { ownership: { run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', nonce: 'nonce-test' }, resolved_plan: {} }, { credential_ref: 'env:E2B_API_KEY' });
  assert.equal(result.result.ok, false);
  assert.equal(result.result.error.code, 'AUTH_MISSING');
  assert.equal(result.stdout?.includes?.('secret'), undefined);
});

test('profile validation rejects unknown provider fields before provisioning', () => {
  const result = call('e2b', 'resolve', { requirements, intent: {} }, { fixture_mode: true, vendor_escape_hatch: true });
  assert.equal(result.result.ok, false);
  assert.equal(result.result.error.code, 'PROFILE_INVALID');
});

test('adapter errors redact workload and provider secrets', () => {
  const req = { contract: 'workcell-backend/v1alpha1', request_id: 'test-redaction', run_id: 'wc-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', operation: 'execute', deadline_ms: 10000, profile: { credential_ref: 'env:E2B_API_KEY' }, payload: { secret_channel: ['WORKLOAD_TOKEN'] } };
  const result = spawnSync(path.join(root, 'e2b', 'workcell-backend-e2b'), ['protocol'], { input: `${JSON.stringify(req)}\n`, encoding: 'utf8', env: { E2B_API_KEY: 'provider-secret-value', WORKLOAD_TOKEN: 'workload-secret-value' } });
  assert.equal(result.stdout.includes('provider-secret-value'), false);
  assert.equal(result.stdout.includes('workload-secret-value'), false);
});

test('adapter log events redact raw and encoded workload secrets', () => {
  const secret = 'workload-secret-value';
  const providerSecret = 'provider-secret-value';
  const encoded = Buffer.from(secret).toString('base64');
  const execution = call('e2b', 'execute', { handle: { resource_ids: [], ownership: {} }, argv: ['true'], workdir: '/workspace', environment: {}, secret_channel: ['WORKLOAD_TOKEN'], timeout_ms: 1000 }, { fixture_mode: true, fixture_stdout: `raw=${secret} encoded=${encoded} provider=${providerSecret}` }, { E2B_API_KEY: providerSecret, WORKLOAD_TOKEN: secret });
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
