import { mkdir, readFile, writeFile } from 'node:fs/promises';
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

function validateProfile(provider, profile) {
  const allowed = new Set([...COMMON_PROFILE_KEYS, ...PROVIDER_PROFILE_KEYS[provider]]);
  const unknown = Object.keys(profile).filter((key) => !allowed.has(key));
  if (unknown.length > 0) throw Object.assign(new Error(`unknown ${provider} profile field(s): ${unknown.sort().join(', ')}`), { code: 'PROFILE_INVALID' });
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
      enforcement: accepted ? { status: fixture ? 'workcell-enforced' : 'provider-claimed', authority: fixture ? 'offline-fixture' : guaranteed ? 'operator-profile' : PROVIDERS[provider].api, evidence: fixture ? 'deterministic fixture' : 'SDK request and provider response' } : { status: 'unknown', authority: PROVIDERS[provider].api, evidence: 'no verified mapping' },
      observation: { status: accepted ? 'observed' : 'not-observed', method: fixture ? 'fixture' : 'request-resolution', result: accepted ? 'configured' : 'not-configured' },
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
  if (req.contract !== CONTRACT || !req.request_id || !req.run_id || !req.operation || typeof req.profile !== 'object' || typeof req.payload !== 'object') throw Object.assign(new Error('request envelope is invalid'), { code: 'PROTOCOL_VIOLATION' });
  return req;
}

export async function writeDownloaded(filePath, bytes) {
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, Buffer.from(bytes));
  return { path: filePath, bytes: Buffer.byteLength(Buffer.from(bytes)) };
}

export async function packageBytes(packageValue) { return readFile(packageValue.archive_path); }
