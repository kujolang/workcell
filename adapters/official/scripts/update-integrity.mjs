#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const check = process.argv.includes('--check');
const providers = ['e2b', 'vercel-sandbox', 'daytona'];
const protectedFiles = ['runtime/adapter.mjs', 'runtime/protocol.mjs', 'runtime/providers.mjs', 'package.json', 'package-lock.json'];

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
