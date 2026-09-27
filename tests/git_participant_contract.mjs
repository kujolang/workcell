// Real concurrent processes. Host setup is test-only; mutation/admission are Kujo.
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';
import crypto from 'node:crypto'; import assert from 'node:assert/strict'; import {spawn,spawnSync} from 'node:child_process';
const runtime=process.env.KUJO_BIN||process.env.KUJO||'kujo',cwd=process.cwd(),root=fs.mkdtempSync(path.join(os.tmpdir(),'git-participant-'));
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');const json=x=>JSON.stringify(x&&typeof x==='object'?Object.fromEntries(Object.keys(x).sort().map(k=>[k,x[k]])):x);
function cmd(exe,args,input){const r=spawnSync(exe,args,{cwd,input,encoding:'utf8',timeout:15000,maxBuffer:8192});assert.equal(r.status,0,r.stderr);return r.stdout.trim();}
const write=(n,x)=>fs.writeFileSync(root+'/'+n,json(x));
try {
 const repo=root+'/private.git';cmd('git',['init','--bare','--quiet',repo]);const git=(args,input)=>cmd('git',['--git-dir='+repo,...args],input);
 const old=git(['hash-object','-w','--stdin'],'old'),next=git(['hash-object','-w','--stdin'],'PRIVATE_CONTENT_CANARY');const now=Math.floor(Date.now()/1000);
 const intent={operation:'update',target_sha256:sha('target'),scope_sha256:sha('scope'),key_sha256:sha('fixture-key'),request_sha256:sha(next),precondition_sha256:sha(old),valid_from:now-5,valid_until:now+1800};git(['update-ref','refs/kujo-targets/'+intent.target_sha256,old]);
 write('config.json',{repo,intent,old_oid:old,new_oid:next,boundary:''});
 write('git-ticket-1.json',{participant_id:'local-git-process',participant_call_id:'call-1',workcell_effect_id:'workcell-effect-1',dispatch_run_id:'run-1',dispatch_step_id:'step-1',dispatch_attempt_id:'1',dispatch_effect_id:'effect-1',transaction_sha256:sha(json(intent)),valid_until:now+120,preservation:{subject:{run_id:'run-1',step_id:'step-1',attempt_id:'1'}}});write('git-current-ticket.json',{attempt:'1'});write('git-request-1.json',{call_id:'call-1'});
 function invoke(){return new Promise((resolve,reject)=>{const p=spawn(runtime,['run','examples/controlled-git/participant.kujo',root,'1'],{cwd,env:{PATH:process.env.PATH}});let out='',err='';const timer=setTimeout(()=>p.kill('SIGKILL'),15000);p.stdout.on('data',b=>{out+=b;if(out.length>8192)p.kill('SIGKILL');});p.stderr.on('data',b=>{err+=b;if(err.length>8192)p.kill('SIGKILL');});p.on('error',reject);p.on('close',code=>{clearTimeout(timer);try{assert.equal(code,0);assert.equal(err,'');resolve(JSON.parse(out));}catch(e){reject(e);}});});}
 const answers=await Promise.all([invoke(),invoke(),invoke(),invoke()]);assert.equal(answers.filter(a=>a.ok).length,1);assert.equal(answers.filter(a=>!a.ok).length,3);assert.equal(fs.readFileSync(root+'/git-participant-invocations','utf8'),'1\n');assert.equal(git(['rev-parse','refs/kujo-targets/'+intent.target_sha256]),next);assert.equal(git(['for-each-ref','--format=%(refname)','refs/kujo-effects']).split('\n').length,1);
 assert(!JSON.stringify(answers).includes('PRIVATE_CONTENT_CANARY'));
 console.log(JSON.stringify({ok:true,concurrent_processes:4,admitted:1,denied:3,logical_effects:1}));
} finally {fs.rmSync(root,{recursive:true,force:true});}
