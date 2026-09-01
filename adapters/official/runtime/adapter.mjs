#!/usr/bin/env node
import { describe, envelope, event, fixture, readRequest, resolve } from './protocol.mjs';
import { daytona, e2b, vercel } from './providers.mjs';

const provider = process.argv[2];
const implementations = { e2b, 'vercel-sandbox': vercel, daytona };

let req;
try {
  if (process.argv[3] !== 'protocol') throw Object.assign(new Error('usage: adapter <provider> protocol'), { code: 'USAGE' });
  req = await readRequest();
  let value;
  if (req.operation === 'describe') value = describe(provider);
  else if (req.operation === 'resolve') value = resolve(provider, req);
  else if (req.profile.fixture_mode === true) value = await fixture(provider, req);
  else {
    const fn = implementations[provider]?.[req.operation];
    if (!fn) throw Object.assign(new Error(`operation ${req.operation} is unsupported`), { code: 'UNSUPPORTED' });
    value = await fn(req);
  }
  const events = value?.events || [];
  events.forEach((entry, index) => process.stdout.write(`${JSON.stringify(event(req, index, entry.stream, entry.bytes))}\n`));
  process.stdout.write(`${JSON.stringify(envelope(req, true, value?.data || value))}\n`);
} catch (error) {
  const fallback = req || { request_id: '', run_id: '', operation: '' };
  process.stdout.write(`${JSON.stringify(envelope(fallback, false, {}, { code: error.code || 'ADAPTER_INTERNAL', message: String(error.message || error).slice(0, 2048), provider_code: error.name || '', retryable: Boolean(error.retryable) }))}\n`);
}
