#!/usr/bin/env python3
"""Opt-in real Docker policy qualification. No image build/pull or host candidate execution."""
import json, os, pathlib, subprocess, tempfile, time, uuid
root = pathlib.Path(__file__).resolve().parent.parent
image = os.environ['WORKCELL_READONLY_IMAGE']
kujo = os.environ.get('KUJO', 'kujo')
def run(argv, **kw):
    result = subprocess.run(argv, capture_output=True, text=True, timeout=40, **kw)
    if result.returncode: raise RuntimeError(f'{argv[0]} failed ({result.returncode}): {result.stderr}')
    return result
security = run(['docker', 'info', '--format', '{{json .SecurityOptions}}']).stdout
assert 'rootless' in security and 'seccomp' in security, security
run(['docker', 'image', 'inspect', image]) # Existing image only; Docker run uses --pull never.
with tempfile.TemporaryDirectory(prefix='workcell-readonly-', dir=root) as temp:
    source = pathlib.Path(temp); source.chmod(0o777)
    (source/'probe').write_text('trusted fixture\n'); (source/'probe').chmod(0o666)
    ident = 'readonly-' + uuid.uuid4().hex
    env = dict(os.environ, WORKCELL_READONLY_DIR=temp, WORKCELL_READONLY_RUN=ident)
    policy = json.loads(run([kujo, 'run', str(root/'tests/readonly_workspace_policy.kujo')], cwd=root, env=env).stdout)
    args = policy['docker_args']; assert args[:2] == ['docker', 'run']
    args[2:2] = ['--detach']
    name = policy['container_name']
    try:
        run(args)
        observed = json.loads(run(['docker', 'inspect', name]).stdout)[0]
        binds = [m for m in observed['Mounts'] if m['Type'] == 'bind']
        assert len(binds) == 1 and binds[0]['Destination'] == '/workspace' and binds[0]['RW'] is False
        assert observed['HostConfig']['ReadonlyRootfs'] and observed['HostConfig']['NetworkMode'] == 'none'
        for uid in ['0:0', '65534:65534']:
            denied = subprocess.run(['docker', 'exec', '--user', uid, name, 'sh', '-c', 'touch /workspace/forged'], capture_output=True, text=True, timeout=10)
            assert denied.returncode != 0 and 'Read-only file system' in denied.stderr, denied
        assert not (source/'forged').exists()
        print(json.dumps({'schema':'workcell-readonly-workspace-qualification/v1','ok':True,'imageId':observed['Image'],'workspaceRW':False,'rootless':True,'uids':['0:0','65534:65534'],'policy':policy}))
    finally:
        subprocess.run(['docker', 'rm', '-f', name], check=True, capture_output=True, timeout=30)
