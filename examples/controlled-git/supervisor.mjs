// Offline process-crash harness only. Kujo owns admission, Git action and evidence.
// Host/operator supplies root and attempt; these arguments are NOT a public request API.
import fs from 'node:fs';
import {spawn, spawnSync} from 'node:child_process';
async function supervise() {
  const [root, attempt] = process.argv.slice(2);
  if (!/^[1-9][0-9]{0,8}$/.test(attempt ?? '')) throw Error('invalid attempt');
  const file = fs.openSync(root + '/config.json', fs.constants.O_RDONLY | fs.constants.O_NOFOLLOW);
  let config;
  try {
    if (!fs.fstatSync(file).isFile() || fs.fstatSync(file).size > 8192) throw Error('config bound');
    const buffer = Buffer.alloc(8193), size = fs.readSync(file, buffer, 0, buffer.length, 0);
    if (size > 8192) throw Error('config bound');
    config = JSON.parse(buffer.subarray(0, size).toString('utf8'));
  } finally {fs.closeSync(file);}
  const child = spawn(config.runtime, ['run', 'examples/controlled-git/participant.kujo', root, attempt], {cwd: config.cwd, env: {PATH: process.env.PATH}, stdio: ['ignore', 'pipe', 'pipe']});
  let output = Buffer.alloc(0), errors = Buffer.alloc(0), killed = false, failed = false;
  const timer = setTimeout(() => {failed = true; child.kill('SIGKILL');}, 15000);
  child.stdout.on('data', b => {
    if (output.length + b.length > 8192) {failed = true; child.kill('SIGKILL'); return;}
    output = Buffer.concat([output, b]);
    if (output.toString('utf8').includes('CRASH_BOUNDARY\n') && !killed) {killed = true; child.kill('SIGKILL');}
  });
  child.stderr.on('data', b => {
    if (errors.length + b.length > 8192) {failed = true; child.kill('SIGKILL'); return;}
    errors = Buffer.concat([errors, b]);
  });
  const [code, signal] = await new Promise(resolve => {
    child.on('error', () => {failed = true;});
    child.on('close', (code, signal) => resolve([code, signal]));
  });
  clearTimeout(timer);
  if (failed || errors.length || (killed ? signal !== 'SIGKILL' : code !== 0)) return {ok:false,outcome:'transport_failed'};
  if (!killed) {
    const reply = JSON.parse(output.toString('utf8'));
    if (reply.ok !== true) return {ok:false,outcome:reply.outcome === 'not_admitted' ? 'not_admitted' : 'completion_unknown'};
  }
  const outcome = killed ? 'completion_lost' : 'completed';
  const record = spawnSync(config.runtime, ['run', 'examples/controlled-git/record.kujo', root, attempt, outcome], {cwd: config.cwd, env: {PATH: process.env.PATH}, encoding: 'utf8', timeout: 15000, maxBuffer: 8192});
  if (record.status !== 0 || record.stderr) return {ok:false,outcome:'evidence_unavailable'};
  return JSON.parse(record.stdout);
}
try {console.log(JSON.stringify(await supervise()));}
catch {console.log('{"ok":false,"outcome":"transport_failed"}');}
