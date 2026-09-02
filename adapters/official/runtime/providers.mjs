import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { credential, executionEnvironment, handle, packageBytes, shellCommand, shellQuote, writeDownloaded } from './protocol.mjs';

function resourceId(req) { return req.payload.handle.resource_ids[0].id; }
function memoryMb(value) { const match = /^([1-9][0-9]*)([mg])$/i.exec(String(value)); if (!match) throw Object.assign(new Error('memory requirement must use m or g units'), { code: 'RESOLUTION_INVALID' }); return Number(match[1]) * (match[2].toLowerCase() === 'g' ? 1024 : 1); }

async function e2bConnect(req) {
  const { Sandbox } = await import('e2b');
  return Sandbox.connect(resourceId(req), { apiKey: credential(req, 'e2b') });
}

export const e2b = {
  async provision(req) {
    const { Sandbox } = await import('e2b');
    const netNone = (req.payload.resolved_plan?.requirements?.network?.mode || req.profile.network_mode) === 'none';
    const opts = { apiKey: credential(req, 'e2b'), timeoutMs: req.profile.sandbox_timeout_ms || 300_000, allowInternetAccess: !netNone, metadata: { 'workcell.run_id': req.run_id, 'workcell.nonce': req.payload.ownership.nonce } };
    const sandbox = await Sandbox.create(req.profile.template || 'base', opts);
    const h = handle('e2b', req, sandbox.sandboxId, { allow_internet_access: !netNone });
    return { handle: h, resource_inventory: [{ kind: 'sandbox', id: sandbox.sandboxId, state: 'running', ownership: h.ownership }], actual_resolution: { allow_internet_access: !netNone } };
  },
  async prepare(req) { const sb = await e2bConnect(req); await sb.files.write('/tmp/workcell-workspace.tar', await packageBytes(req.payload.workspace_package)); await sb.commands.run("mkdir -p /workspace && tar -xf /tmp/workcell-workspace.tar -C /workspace --strip-components=1"); return { handle: req.payload.handle, workspace_root: '/workspace', observed_package_digest: req.payload.workspace_package.sha256 }; },
  async execute(req) { const sb = await e2bConnect(req); let result; try { result = await sb.commands.run(shellCommand(req.payload.argv), { cwd: req.payload.workdir, envs: executionEnvironment(req), timeoutMs: req.payload.timeout_ms }); } catch (error) { if (Number.isInteger(error?.exitCode)) result = error; else throw error; } return commandData(req, result.exitCode, result.stdout || '', result.stderr || ''); },
  async collect() { return collected(); },
  async export(req) { const sb = await e2bConnect(req); return exportWithCommand(req, async (cmd) => sb.commands.run(cmd), async (remote, local) => writeDownloaded(local, await sb.files.read(remote, { format: 'bytes' }))); },
  async destroy(req) { const { Sandbox } = await import('e2b'); await Sandbox.kill(resourceId(req), { apiKey: credential(req, 'e2b') }); return destroyed(req); },
  async inventory(req) { const { Sandbox } = await import('e2b'); const pager = Sandbox.list({ apiKey: credential(req, 'e2b'), query: { metadata: { 'workcell.run_id': req.run_id } } }); const resources = []; for await (const item of pager) resources.push({ kind: 'sandbox', id: item.sandboxId, state: item.state || 'unknown', ownership: req.payload.ownership }); return { resources, complete: true }; }
};

async function vercelConnect(req) { const { Sandbox } = await import('@vercel/sandbox'); return Sandbox.get({ name: resourceId(req), resume: true }); }
export const vercel = {
  async provision(req) { const { Sandbox } = await import('@vercel/sandbox'); credential(req, 'vercel-sandbox'); const requirements = req.payload.resolved_plan.requirements || {}; const mode = requirements.network?.mode || 'none'; const networkPolicy = mode === 'none' ? 'deny-all' : mode === 'allowlist' ? { allow: requirements.network.allow || [] } : 'allow-all'; const compute = requirements.compute || {}; const resources = { vcpus: compute.cpus, memory: memoryMb(compute.memory) }; const sandbox = await Sandbox.create({ name: `wc-${req.run_id.slice(3, 26)}`, persistent: false, timeout: requirements.execution?.timeout_ms || 300_000, image: req.profile.image, resources, networkPolicy, tags: { 'workcell-run-id': req.run_id, 'workcell-nonce': req.payload.ownership.nonce } }); const h = handle('vercel-sandbox', req, sandbox.name, { network_policy: networkPolicy, resources }); return { handle: h, resource_inventory: [{ kind: 'sandbox', id: sandbox.name, state: 'running', ownership: h.ownership }], actual_resolution: { network_policy: networkPolicy, resources } }; },
  async prepare(req) { const sb = await vercelConnect(req); await sb.writeFiles([{ path: '/tmp/workcell-workspace.tar', content: await packageBytes(req.payload.workspace_package) }]); await sb.runCommand('sh', ['-lc', 'mkdir -p /workspace && tar -xf /tmp/workcell-workspace.tar -C /workspace --strip-components=1']); return { handle: req.payload.handle, workspace_root: '/workspace', observed_package_digest: req.payload.workspace_package.sha256 }; },
  async execute(req) { const sb = await vercelConnect(req); const result = await sb.runCommand({ cmd: req.payload.argv[0], args: req.payload.argv.slice(1), cwd: req.payload.workdir, env: executionEnvironment(req), timeoutMs: req.payload.timeout_ms }); return commandData(req, result.exitCode, await result.stdout(), await result.stderr()); },
  async collect() { return collected(); },
  async export(req) { const sb = await vercelConnect(req); return exportWithCommand(req, async (cmd) => sb.runCommand('sh', ['-lc', cmd]), async (remote, local) => writeDownloaded(local, await sb.readFileToBuffer({ path: remote }))); },
  async destroy(req) { const sb = await vercelConnect(req); await sb.stop(); return destroyed(req); },
  async inventory(req) { const { Sandbox } = await import('@vercel/sandbox'); const pager = await Sandbox.list({ tags: { 'workcell-run-id': req.run_id } }); const resources = []; for await (const item of pager) resources.push({ kind: 'sandbox', id: item.name, state: item.status, ownership: req.payload.ownership }); return { resources, complete: true }; }
};

function daytonaClient(req) { return import('@daytona/sdk').then(({ Daytona }) => new Daytona({ apiKey: credential(req, 'daytona'), apiUrl: req.profile.endpoint || undefined, target: req.profile.region || undefined, otelEnabled: false })); }
async function daytonaConnect(req) { const client = await daytonaClient(req); return { client, sandbox: await client.get(resourceId(req)) }; }
export const daytona = {
  async provision(req) { const client = await daytonaClient(req); const requirements = req.payload.resolved_plan.requirements || {}; const mode = requirements.network?.mode || 'none'; const compute = requirements.compute || {}; const resources = { cpu: compute.cpus, memory: Math.max(1, Math.ceil(memoryMb(compute.memory) / 1024)) }; const params = { name: `wc-${req.run_id.slice(3, 26)}`, image: req.payload.resolved_plan.workload?.image?.reference || 'debian:12.9', resources, ephemeral: true, autoDeleteInterval: 0, ttlMinutes: Math.max(1, Math.ceil((requirements.execution?.timeout_ms || 300_000) / 60_000)), labels: { 'workcell.run_id': req.run_id, 'workcell.nonce': req.payload.ownership.nonce }, networkBlockAll: mode === 'none', domainAllowList: mode === 'allowlist' ? (requirements.network.allow || []).join(',') : undefined }; const sandbox = await client.create(params, { timeout: 120 }); const h = handle('daytona', req, sandbox.id, { sandbox_class: sandbox.class || null, network_mode: mode, resources }); return { handle: h, resource_inventory: [{ kind: 'sandbox', id: sandbox.id, state: sandbox.state || 'started', ownership: h.ownership }], actual_resolution: { sandbox_class: sandbox.class || null, network_mode: mode, resources } }; },
  async prepare(req) { const { sandbox } = await daytonaConnect(req); await sandbox.fs.uploadFile(req.payload.workspace_package.archive_path, '/tmp/workcell-workspace.tar'); await sandbox.process.executeCommand("mkdir -p /workspace && tar -xf /tmp/workcell-workspace.tar -C /workspace --strip-components=1"); return { handle: req.payload.handle, workspace_root: '/workspace', observed_package_digest: req.payload.workspace_package.sha256 }; },
  async execute(req) { const { sandbox } = await daytonaConnect(req); const result = await sandbox.process.executeCommand(shellCommand(req.payload.argv), req.payload.workdir, executionEnvironment(req), Math.ceil(req.payload.timeout_ms / 1000)); return commandData(req, result.exitCode, result.result || '', ''); },
  async collect() { return collected(); },
  async export(req) { const { sandbox } = await daytonaConnect(req); return exportWithCommand(req, async (cmd) => sandbox.process.executeCommand(cmd, '/workspace'), async (remote, local) => { await sandbox.fs.downloadFile(remote, local); const value = await readFile(local); return { path: local, bytes: value.length }; }); },
  async destroy(req) { const { sandbox } = await daytonaConnect(req); await sandbox.delete(60, true); return destroyed(req); },
  async inventory(req) { const client = await daytonaClient(req); const resources = []; for await (const item of client.list({ labels: { 'workcell.run_id': req.run_id } })) resources.push({ kind: 'sandbox', id: item.id, state: item.state || 'unknown', ownership: req.payload.ownership }); return { resources, complete: true }; }
};

function commandData(req, exitCode, stdout, stderr) { return { events: [stdout ? { stream: 'stdout', bytes: stdout } : null, stderr ? { stream: 'stderr', bytes: stderr } : null].filter(Boolean), data: { handle: req.payload.handle, command_id: `${req.run_id}-command`, terminal: { status: 'exited', exit_code: exitCode, signal: null, reason: 'provider-exit', timed_out: false, cancelled: false, certainty: 'terminal' }, logs: { stdout_bytes: Buffer.byteLength(stdout), stderr_bytes: Buffer.byteLength(stderr), truncated: false, complete: true, ordering: 'per-stream' } } }; }
function collected() { return { terminal: { status: 'unknown', exit_code: null, signal: null, reason: 'execute-result-authoritative', timed_out: false, cancelled: false, certainty: 'unknown' }, logs: { complete: true, ordering: 'per-stream' }, workspace_delta: { files: [], complete: false }, metrics: {}, attempt_inventory: [] }; }
function destroyed(req) { return { items: req.payload.handle.resource_ids.map((r) => ({ ...r, status: 'removed' })), remaining: [] }; }
async function exportWithCommand(req, run, download) { const declared = req.payload.declarations || []; if (declared.length === 0) return { archive: null, manifest: { declared, files: [] }, failures: [], cleanup_resources: [] }; for (const item of declared) if (!/^[A-Za-z0-9._/-]+$/.test(item) || item.includes('..') || item.startsWith('/')) throw Object.assign(new Error('artifact declaration is unsafe'), { code: 'PATH_UNSAFE' }); const remote = `/tmp/workcell-artifacts-${req.run_id}.tar`; await run(`tar -cf ${shellQuote(remote)} -C /workspace -- ${declared.map(shellQuote).join(' ')}`); const local = path.join(req.payload.destination, 'artifacts.tar'); const archive = await download(remote, local); return { archive, manifest: { declared, files: [] }, failures: [], cleanup_resources: [] }; }
