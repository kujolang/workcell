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
for (let offset = 0; offset < files.length; offset += 128) {
  const batch = files.slice(offset, offset + 128);
  const digests = await Promise.all(batch.map(async (relative) => createHash('sha256').update(await readFile(path.join(root, relative))).digest('hex')));
  for (let index = 0; index < batch.length; index += 1) aggregate.update(batch[index]).update('\0').update(digests[index]).update('\n');
}
if (aggregate.digest('hex') !== expected) {
  console.error('WorkCell adapter dependency integrity check failed');
  process.exit(70);
}
