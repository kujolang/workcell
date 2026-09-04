#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { gunzipSync } from 'node:zlib';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

const root = path.resolve(process.argv[2] || '.');
const expected = (await readFile(path.join(root, 'runtime/dependencies.sha256'), 'utf8')).trim();
const encodedFiles = (await readFile(path.join(root, 'runtime/dependencies.files.gz.b64'), 'utf8')).trim();
const files = gunzipSync(Buffer.from(encodedFiles, 'base64')).toString('utf8').trim().split('\n').filter(Boolean);
const aggregate = createHash('sha256');
for (const relative of files) {
  const digest = createHash('sha256').update(await readFile(path.join(root, relative))).digest('hex');
  aggregate.update(relative).update('\0').update(digest).update('\n');
}
if (aggregate.digest('hex') !== expected) {
  console.error('WorkCell adapter dependency integrity check failed');
  process.exit(70);
}
