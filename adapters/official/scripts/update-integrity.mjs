#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { gzipSync } from 'node:zlib';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const check = process.argv.includes('--check');
const providers = ['e2b', 'vercel-sandbox', 'daytona'];
const protectedFiles = ['runtime/adapter.mjs', 'runtime/protocol.mjs', 'runtime/providers.mjs', 'package.json', 'package-lock.json', 'runtime/verify-dependencies.mjs', 'runtime/dependencies.sha256', 'runtime/dependencies.files.gz.b64'];
const run = promisify(execFile);

async function digest(relative) {
  return createHash('sha256').update(await readFile(path.join(root, relative))).digest('hex');
}

async function replace(relative, pattern, replacement) {
  const file = path.join(root, relative);
  const before = await readFile(file, 'utf8');
  const after = before.replace(pattern, replacement);
  if (after === before && !pattern.test(before)) throw new Error(`integrity field not found: ${relative}`);
  if (check && after !== before) throw new Error(`stale integrity metadata: ${relative}`);
  if (!check && after !== before) await writeFile(file, after);
}

async function dependencyManifest() {
  const { stdout } = await run('npm', ['pack', '--dry-run', '--json'], { cwd: root, maxBuffer: 64 * 1024 * 1024 });
  const packed = JSON.parse(stdout)[0].files.map((entry) => entry.path).filter((entry) => entry.startsWith('node_modules/')).sort();
  if (packed.length === 0) throw new Error('official adapter package contains no bundled dependencies');
  const aggregate = createHash('sha256');
  for (const relative of packed) aggregate.update(relative).update('\0').update(await digest(relative)).update('\n');
  return { digest: aggregate.digest('hex'), files: packed };
}

const dependencies = await dependencyManifest();
const dependencyHash = `${dependencies.digest}\n`;
const dependencyPath = path.join(root, 'runtime/dependencies.sha256');
const currentDependencyHash = await readFile(dependencyPath, 'utf8');
if (check && currentDependencyHash !== dependencyHash) throw new Error('stale dependency integrity metadata');
if (!check && currentDependencyHash !== dependencyHash) await writeFile(dependencyPath, dependencyHash);
const dependencyFiles = `${gzipSync(`${dependencies.files.join('\n')}\n`, { level: 9, mtime: 0 }).toString('base64')}\n`;
const dependencyFilesPath = path.join(root, 'runtime/dependencies.files.gz.b64');
const currentDependencyFiles = await readFile(dependencyFilesPath, 'utf8');
if (check && currentDependencyFiles !== dependencyFiles) throw new Error('stale dependency file manifest');
if (!check && currentDependencyFiles !== dependencyFiles) await writeFile(dependencyFilesPath, dependencyFiles);

for (const relative of protectedFiles) {
  const hash = await digest(relative);
  await replace('runtime/verify-integrity.sh', new RegExp(`verify "${relative.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}" "[0-9a-f]{64}"`), `verify "${relative}" "${hash}"`);
}

const verifierHash = await digest('runtime/verify-integrity.sh');
for (const provider of providers) {
  const executable = `${provider}/workcell-backend-${provider}`;
  await replace(executable, /EXPECTED_VERIFY="[0-9a-f]{64}"/, `EXPECTED_VERIFY="${verifierHash}"`);
  const manifestPath = path.join(root, provider, 'manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  manifest.digest = `sha256:${await digest(executable)}`;
  const encoded = `${JSON.stringify(manifest)}\n`;
  const current = await readFile(manifestPath, 'utf8');
  if (check && encoded !== current) throw new Error(`stale integrity metadata: ${provider}/manifest.json`);
  if (!check && encoded !== current) await writeFile(manifestPath, encoded);
}
