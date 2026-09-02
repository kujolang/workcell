import { mkdir, open, readFile, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';

export const CONTRACT = 'workcell-backend/v1alpha1';
const PROVIDERS = {
  e2b: { version: '2.46.1', api: 'e2b-sdk/2.46.1', substrate: 'provider-claimed-firecracker', credential: 'E2B_API_KEY' },
  'vercel-sandbox': { version: '3.2.1', api: '@vercel/sandbox/3.2.1', substrate: 'provider-claimed-firecracker', credential: 'VERCEL_OIDC_TOKEN' },
  daytona: { version: '0.207.1', api: '@daytonaio/sdk/0.207.1', substrate: 'provider-reported-sandbox-class', credential: 'DAYTONA_API_KEY' }
};

export function envelope(req, ok, data = {}, error = undefined, status = ok ? 'ok' : 'failed') {
  const value = { contract: CONTRACT, request_id: req.request_id, run_id: req.run_id, operation: req.operation, type: 'result', ok, status, retryable: Boolean(error?.retryable), data };
  if (!ok) value.error = { code: error?.code || 'ADAPTER_INTERNAL', message: error?.message || 'adapter operation failed', provider_code: error?.provider_code || '' };
  return value;
}

export function event(req, sequence, stream, bytes) {
  return { contract: CONTRACT, request_id: req.request_id, run_id: req.run_id, operation: req.operation, type: 'event', event: 'log', sequence, stream, bytes_base64: Buffer.from(bytes).toString('base64'), provider_timestamp: null, ordering: 'per-stream' };
}

export function identity(provider) {
  const p = PROVIDERS[provider];
  return { adapter: provider, adapter_version: p.version, provider, provider_api: p.api, substrate: p.substrate };
}

export function describe(provider) {
  const p = PROVIDERS[provider];
  return { adapter: { id: provider, version: p.version, build: 'official-node' }, contract_versions: [CONTRACT], profile_schema: `workcell-${provider}-profile/v1alpha1`, credential_refs: [`env:${p.credential}`], static_capability_hints: ['lifecycle.provision', 'lifecycle.destroy', 'lifecycle.inventory', 'workspace.stage', 'process.argv', 'artifact.selective_export'] };
}

const BASE = new Set(['lifecycle.provision', 'lifecycle.terminate', 'lifecycle.destroy', 'lifecycle.inventory', 'workspace.stage', 'workspace.collect_delta', 'process.argv', 'process.exit_status', 'execution.timeout', 'logs.bounded', 'artifact.selective_export', 'environment.explicit', 'credentials.redacted_transport', 'evidence.provider_identity', 'ownership.markers']);
const DIRECT = {
  e2b: new Set([...BASE, 'network.none']),
  'vercel-sandbox': new Set([...BASE, 'compute.cpu_limit', 'compute.memory_limit', 'network.none', 'network.custom']),
  daytona: new Set([...BASE, 'compute.cpu_limit', 'compute.memory_limit', 'network.none', 'network.custom', 'image.oci'])
};

const COMMON_PROFILE_KEYS = new Set(['credential_ref', 'endpoint', 'fixture_exit_code', 'fixture_mode', 'fixture_stderr', 'fixture_stdout', 'guarantees', 'policy', 'provider_project', 'region']);
const PROVIDER_PROFILE_KEYS = {
  e2b: new Set(['sandbox_timeout_ms', 'template']),
  'vercel-sandbox': new Set(['image']),
  daytona: new Set([])
};

export function validateProfile(provider, profile) {
  if (!profile || typeof profile !== 'object' || Array.isArray(profile)) throw Object.assign(new Error('adapter profile must be an object'), { code: 'PROFILE_INVALID' });
  const allowed = new Set([...COMMON_PROFILE_KEYS, ...PROVIDER_PROFILE_KEYS[provider]]);
  const unknown = Object.keys(profile).filter((key) => !allowed.has(key));
  if (unknown.length > 0) throw Object.assign(new Error(`unknown ${provider} profile field(s): ${unknown.sort().join(', ')}`), { code: 'PROFILE_INVALID' });
  for (const field of ['endpoint', 'provider_project', 'region']) {
    if (profile[field] && provider !== 'daytona') throw Object.assign(new Error(`${provider} does not implement profile field ${field}`), { code: 'PROFILE_INVALID' });
  }
  if (profile.provider_project && provider === 'daytona') throw Object.assign(new Error('daytona does not implement profile field provider_project'), { code: 'PROFILE_INVALID' });
}

export function resolve(provider, req) {
  validateProfile(provider, req.profile);
  const fixture = req.profile.fixture_mode === true;
  const guarantees = req.profile.guarantees || {};
  const caps = (req.payload.requirements || []).map((wanted) => {
    const direct = fixture || DIRECT[provider].has(wanted.id);
    const guaranteed = Object.hasOwn(guarantees, wanted.id) && JSON.stringify(guarantees[wanted.id]) === JSON.stringify(wanted.value);
    const accepted = direct || guaranteed;
    return {
      id: wanted.id,
      support: direct ? 'supported' : guaranteed ? 'conditional' : 'unknown',
      requested: wanted.requested !== false,
      acceptance: accepted ? 'accepted' : 'rejected',
      resolved: accepted ? wanted.value : null,
      enforcement: accepted ? { status: fixture ? 'workcell-enforced' : guaranteed ? 'operator-claimed' : 'provider-claimed', authority: fixture ? 'offline-fixture' : guaranteed ? 'operator-profile' : PROVIDERS[provider].api, evidence: fixture ? 'deterministic fixture' : guaranteed ? 'explicit operator guarantee' : 'documented SDK request mapping' } : { status: 'unknown', authority: PROVIDERS[provider].api, evidence: 'no verified mapping' },
      observation: { status: fixture ? 'observed' : 'not-observed', method: fixture ? 'fixture' : 'resolution-only', result: fixture ? 'configured' : accepted ? 'not yet executed' : 'not-configured' },
      limitations: accepted ? [] : ['provider adapter cannot prove this requirement from the selected profile']
    };
  });
  return { identity: identity(provider), capabilities: caps, resolved_plan: req.payload.intent || {}, volatile_fields: ['provider_resource_id', 'region', 'startup_time'] };
}

export function credential(req, provider) {
  const ref = req.profile.credential_ref || `env:${PROVIDERS[provider].credential}`;
  if (!ref.startsWith('env:')) throw Object.assign(new Error('official adapter currently requires an env: credential reference'), { code: 'AUTH_UNSUPPORTED' });
  const name = ref.slice(4);
  if (!/^[A-Z_][A-Z0-9_]*$/.test(name)) throw Object.assign(new Error('credential environment reference is invalid'), { code: 'AUTH_INVALID' });
  const value = process.env[name];
  if (!value) throw Object.assign(new Error(`required credential ${name} is unavailable`), { code: 'AUTH_MISSING' });
  return value;
}

export function handle(provider, req, resourceId, state = {}) {
  const digest = createHash('sha256').update(JSON.stringify(req.profile)).digest('hex');
  return { backend: provider, adapter_version: PROVIDERS[provider].version, provider, profile_fingerprint: `sha256:${digest}`, resource_ids: [{ kind: 'sandbox', id: resourceId }], ownership: req.payload.ownership || req.payload.handle?.ownership, provider_state: state };
}

export function executionEnvironment(req) {
  const result = { ...(req.payload.environment || {}) };
  for (const name of req.payload.secret_channel || []) {
    if (!/^[A-Z_][A-Z0-9_]*$/.test(name)) throw Object.assign(new Error('secret environment reference is invalid'), { code: 'AUTH_INVALID' });
    if (!process.env[name]) throw Object.assign(new Error(`required secret ${name} is unavailable`), { code: 'AUTH_MISSING' });
    result[name] = process.env[name];
  }
  return result;
}

function secretValues(req, provider) {
  const names = [...(req?.payload?.secret_channel || [])];
  const credentialRef = req?.profile?.credential_ref || '';
  if (credentialRef.startsWith('env:')) names.push(credentialRef.slice(4));
  else if (provider && PROVIDERS[provider]) names.push(PROVIDERS[provider].credential);
  return names.map((name) => process.env[name]).filter(Boolean);
}

export function redactOutput(req, output, provider) {
  let value = String(output ?? '');
  for (const secret of secretValues(req, provider)) {
    value = value.replaceAll(secret, '[REDACTED]');
    if (secret.length >= 8) value = value.replaceAll(Buffer.from(secret).toString('base64'), '[REDACTED]');
  }
  return value;
}

export function redactError(req, error, provider) {
  let message = String(error?.message || error).slice(0, 2048);
  return redactOutput(req, message, provider);
}

export function shellQuote(value) { return `'${String(value).replaceAll("'", "'\\''")}'`; }
export function shellCommand(argv) { return argv.map(shellQuote).join(' '); }

export async function localTar(directory, archive, names) {
  await mkdir(path.dirname(archive), { recursive: true });
  await new Promise((resolve, reject) => {
    const child = spawn('tar', ['-cf', archive, '-C', directory, '--', ...names], { stdio: ['ignore', 'ignore', 'pipe'] });
    let stderr = '';
    child.stderr.on('data', (chunk) => { stderr += chunk; });
    child.on('error', reject);
    child.on('exit', (code) => code === 0 ? resolve() : reject(new Error(`tar failed: ${stderr.slice(0, 512)}`)));
  });
}

export async function fixture(provider, req) {
  const resourceId = `${provider}-${req.run_id}`;
  const owned = handle(provider, req, resourceId, { fixture: true });
  if (req.operation === 'provision') return { handle: owned, resource_inventory: [{ kind: 'sandbox', id: resourceId, state: 'running', ownership: owned.ownership }], actual_resolution: {} };
  if (req.operation === 'prepare') return { handle: req.payload.handle, workspace_root: '/workspace', observed_package_digest: req.payload.workspace_package.sha256 };
  if (req.operation === 'execute') {
    const stdout = redactOutput(req, req.profile.fixture_stdout ?? `${provider} fixture\n`, provider);
    const stderr = redactOutput(req, req.profile.fixture_stderr ?? '', provider);
    return { events: [stdout ? { stream: 'stdout', bytes: stdout } : null, stderr ? { stream: 'stderr', bytes: stderr } : null].filter(Boolean), data: { handle: req.payload.handle, command_id: 'fixture-command', terminal: { status: 'exited', exit_code: Number(req.profile.fixture_exit_code || 0), signal: null, reason: 'fixture-exit', timed_out: false, cancelled: false, certainty: 'terminal' }, logs: { stdout_bytes: Buffer.byteLength(stdout), stderr_bytes: Buffer.byteLength(stderr), truncated: false, complete: true, ordering: 'per-stream' } } };
  }
  if (req.operation === 'collect') return { terminal: { status: 'exited', exit_code: 0, signal: null, reason: 'fixture-exit', timed_out: false, cancelled: false, certainty: 'terminal' }, logs: { complete: true, ordering: 'per-stream' }, workspace_delta: { files: [], complete: true }, metrics: {}, attempt_inventory: [] };
  if (req.operation === 'export') return { archive: null, manifest: { declared: req.payload.declarations || [], files: [] }, failures: [], cleanup_resources: [] };
  if (req.operation === 'inventory') return { resources: [{ kind: 'sandbox', id: resourceId, state: 'running', ownership: req.payload.ownership }], complete: true };
  if (req.operation === 'destroy') return { items: (req.payload.handle.resource_ids || []).map((r) => ({ ...r, status: 'removed' })), remaining: [] };
  if (req.operation === 'cancel') return { cancel_result: 'requested', terminal_certainty: 'unknown' };
  throw Object.assign(new Error(`fixture operation ${req.operation} is unsupported`), { code: 'UNSUPPORTED' });
}

export async function readRequest() {
  let text = '';
  for await (const chunk of process.stdin) text += chunk;
  if (Buffer.byteLength(text) > 1_048_576) throw Object.assign(new Error('request exceeded one MiB'), { code: 'PROTOCOL_VIOLATION' });
  const req = JSON.parse(text);
  const envelopeFields = ['contract', 'request_id', 'run_id', 'operation', 'deadline_ms', 'profile', 'payload'];
  if (Object.keys(req).some((key) => !envelopeFields.includes(key)) || envelopeFields.some((key) => !Object.hasOwn(req, key)) || req.contract !== CONTRACT || typeof req.request_id !== 'string' || !/^wc-[0-9a-f]{32}$/.test(req.run_id) || !Number.isSafeInteger(req.deadline_ms) || req.deadline_ms <= 0 || !plainObject(req.profile) || !plainObject(req.payload)) throw Object.assign(new Error('request envelope is invalid'), { code: 'PROTOCOL_VIOLATION' });
  validatePayload(req.operation, req.payload, req.run_id);
  return req;
}

function plainObject(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function text(value) { return typeof value === 'string' && value.length > 0 && value.length <= 4096 && !value.includes('\0'); }
function ownFields(value, allowed, required = allowed) { return plainObject(value) && Object.keys(value).every((key) => allowed.includes(key)) && required.every((key) => Object.hasOwn(value, key)); }
function strings(value, max) { return Array.isArray(value) && value.length <= max && value.every(text); }
function ownership(value, runId) { return ownFields(value, ['run_id', 'nonce']) && value.run_id === runId && text(value.nonce); }

function validatePayload(operation, payload, runId) {
  let valid = false;
  if (operation === 'describe') valid = ownFields(payload, [], []);
  else if (operation === 'resolve') valid = ownFields(payload, ['requirements', 'intent']) && Array.isArray(payload.requirements) && payload.requirements.length <= 256 && plainObject(payload.intent);
  else if (operation === 'provision') valid = ownFields(payload, ['resolved_plan', 'ownership', 'idempotency_key']) && plainObject(payload.resolved_plan) && ownership(payload.ownership, runId) && text(payload.idempotency_key);
  else if (operation === 'prepare') valid = ownFields(payload, ['handle', 'workspace_package', 'execution_prerequisites', 'idempotency_key'], ['handle', 'workspace_package', 'idempotency_key']) && plainObject(payload.handle) && plainObject(payload.workspace_package) && text(payload.workspace_package.sha256) && text(payload.idempotency_key);
  else if (operation === 'execute') valid = ownFields(payload, ['handle', 'attempt_id', 'argv', 'workdir', 'environment', 'secret_channel', 'timeout_ms', 'max_output_bytes']) && plainObject(payload.handle) && text(payload.attempt_id) && strings(payload.argv, 1024) && payload.argv.length > 0 && text(payload.workdir) && payload.workdir.startsWith('/') && plainObject(payload.environment) && strings(payload.secret_channel, 1024) && Number.isSafeInteger(payload.timeout_ms) && payload.timeout_ms > 0 && Number.isSafeInteger(payload.max_output_bytes) && payload.max_output_bytes > 0;
  else if (operation === 'cancel') valid = ownFields(payload, ['handle', 'command_id', 'idempotency_key']) && plainObject(payload.handle) && text(payload.command_id) && text(payload.idempotency_key);
  else if (operation === 'collect') valid = ownFields(payload, ['handle', 'attempt_id', 'stream_cursor']) && plainObject(payload.handle) && text(payload.attempt_id);
  else if (operation === 'export') valid = ownFields(payload, ['handle', 'declarations', 'limits', 'exporter_version', 'destination', 'idempotency_key']) && plainObject(payload.handle) && strings(payload.declarations, 10000) && plainObject(payload.limits) && text(payload.exporter_version) && text(payload.destination) && text(payload.idempotency_key);
  else if (operation === 'destroy') valid = ownFields(payload, ['handle', 'expected_ownership', 'idempotency_key']) && plainObject(payload.handle) && ownership(payload.expected_ownership, runId) && text(payload.idempotency_key);
  else if (operation === 'inventory') valid = ownFields(payload, ['ownership']) && ownership(payload.ownership, runId);
  if (!valid) throw Object.assign(new Error(`request ${operation || 'unknown'} payload is invalid`), { code: 'PROTOCOL_VIOLATION' });
}

export function archiveDownloadLimit(limits = {}) {
  const contentBytes = Number.isInteger(limits.max_bytes) && limits.max_bytes > 0 ? limits.max_bytes : 1_000_000_000;
  const files = Number.isInteger(limits.max_files) && limits.max_files > 0 ? limits.max_files : 100_000;
  const metadataBytes = Math.min((files * 2048) + 1_048_576, 268_435_456);
  return contentBytes + metadataBytes;
}

export async function writeBoundedStream(filePath, stream, maxBytes) {
  if (!Number.isSafeInteger(maxBytes) || maxBytes <= 0) throw Object.assign(new Error('download bound is invalid'), { code: 'ARTIFACT_LIMIT' });
  await mkdir(path.dirname(filePath), { recursive: true });
  const file = await open(filePath, 'w', 0o600);
  let bytes = 0;
  try {
    for await (const chunk of stream) {
      const data = Buffer.from(chunk);
      bytes += data.length;
      if (bytes > maxBytes) {
        if (typeof stream.destroy === 'function') stream.destroy();
        else if (typeof stream.cancel === 'function') await stream.cancel();
        throw Object.assign(new Error(`artifact archive exceeded transport bound ${maxBytes}`), { code: 'ARTIFACT_LIMIT' });
      }
      await file.write(data);
    }
    await file.sync();
  } catch (error) {
    await file.close().catch(() => {});
    await rm(filePath, { force: true }).catch(() => {});
    throw error;
  }
  await file.close();
  return { path: filePath, bytes };
}

export async function packageBytes(packageValue) { return readFile(packageValue.archive_path); }
