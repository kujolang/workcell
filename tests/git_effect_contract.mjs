import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
const runtime=process.env.KUJO_BIN||process.env.KUJO||'kujo';
const root=fs.mkdtempSync(path.resolve('tests/tmp-git-assurance-'));
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
function command(program,args,input){const r=spawnSync(program,args,{encoding:'utf8',input,timeout:15000});assert.equal(r.status,0,r.stderr);assert.equal(r.stderr,'');return r.stdout.trim();}
try{
 const repo=path.join(root,'owned.git');command('git',['init','--bare','--quiet',repo]);
 const old=command('git',['--git-dir='+repo,'hash-object','-w','--stdin'],'old');
 const next=command('git',['--git-dir='+repo,'hash-object','-w','--stdin'],'SECRET_CANARY_NEVER_IN_ASSURANCE');
 const now=Math.floor(Date.now()/1000),intent={operation:'update',target_sha256:sha('target'),scope_sha256:sha('account-environment-run-step'),key_sha256:sha('key'),request_sha256:sha(next),precondition_sha256:sha(old),valid_from:now-1,valid_until:now+60};
 const config={repo,old_oid:old,new_oid:next,intent};
 const write=()=>fs.writeFileSync(path.join(root,'config.json'),JSON.stringify(config));write();
 const adapter=mode=>JSON.parse(command(runtime,['run','examples/effect-assurance/adapter.kujo',root,mode]));
 command('git',['--git-dir='+repo,'update-ref','refs/kujo-targets/'+intent.target_sha256,old]);
 assert.equal(adapter('observe').observation.observed_state,'not_started');
 assert.equal(adapter('apply').ok,true);assert.equal(adapter('apply').ok,true);
 const proof=adapter('observe');assert.equal(proof.observation.observed_state,'committed');assert.ok(!JSON.stringify(proof).includes('CANARY'));
 assert.equal(command('git',['--git-dir='+repo,'for-each-ref','--format=%(refname)','refs/kujo-effects/']).split('\n').length,1);
 config.intent.valid_until=now;config.intent.valid_from=now-30;write();assert.equal(adapter('apply').ok,false);
 config.intent.valid_until=now+60;config.intent.valid_from=now-1;config.intent.request_sha256=sha('other');write();assert.equal(adapter('apply').ok,false);
 config.intent.request_sha256=sha(next);write();
 command('git',['--git-dir='+repo,'update-ref','refs/kujo-targets/'+intent.target_sha256,old]);
 assert.equal(adapter('observe').ok,false);assert.equal(adapter('apply').ok,false);
 console.log('PASS Git effect: real atomic ref transaction, duplicate, input conflict, expiry, moved target, privacy');
}finally{fs.rmSync(root,{recursive:true,force:true});}
