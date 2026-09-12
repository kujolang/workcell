"""Exercise the real host-process boundary without a daemon or Internet access."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
KUJO = os.environ.get("KUJO", "kujo")
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    docker = root / "docker"
    docker.write_text('''#!/usr/bin/env python3
import json, os, sys
assert sys.argv[1:3] == ["run", "--pull=never"]
assert os.environ["DOCKER_HOST"] == "unix:///fixture-selected.sock"
assert os.environ["DOCKER_CONTEXT"] == "fixture-context"
assert os.environ["DOCKER_CONFIG"] == os.environ["WORKCELL_EXPECT_CONFIG"]
assert os.environ["DOCKER_CERT_PATH"] == "/fixture-certs"
assert os.environ["DOCKER_TLS_VERIFY"] == "1"
assert "WORKCELL_UNDECLARED_SECRET" not in os.environ
assert "HOME" not in os.environ and "HTTP_PROXY" not in os.environ
for name in ["HTTP_PROXY", "HTTPS_PROXY", "FTP_PROXY", "ALL_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "ftp_proxy", "all_proxy", "no_proxy"]:
    assert name + "=" in sys.argv
assert not any(arg.startswith("DOCKER_") for arg in sys.argv)
print("selected endpoint preserved; undeclared environment excluded")
''')
    docker.chmod(0o700)
    probe = root / "probe.kujo"
    probe.write_text('''from src.domain.definition import default_definition
from src.policy.policy import build_policy
from src.runtime.docker import run_container
mut definition := default_definition()
mut environment := definition["environment"]
environment["allow"] := ["WORKCELL_EXPECT_CONFIG"]
definition["environment"] := environment
let policy := build_policy(definition,"endpoint-fixture","/tmp")
let result := run_container(definition,policy,{})
assert(result["ok"] && result["success"],to_json(result))
print("Docker endpoint process contract passed")
''')
    for engine in ([], ["--interpreter"]):
        for explicit_config in (False, True):
            env = {**os.environ, "PATH": str(root) + os.pathsep + os.environ["PATH"],
                   "DOCKER_HOST": "unix:///fixture-selected.sock", "DOCKER_CONTEXT": "fixture-context",
                   "DOCKER_CERT_PATH": "/fixture-certs", "DOCKER_TLS_VERIFY": "1",
                   "WORKCELL_UNDECLARED_SECRET": "fixture-not-forwarded", "HTTP_PROXY": "http://fixture.invalid"}
            env.pop("DOCKER_CONFIG", None)
            env["WORKCELL_EXPECT_CONFIG"] = os.environ["HOME"] + "/.docker"
            if explicit_config:
                env["DOCKER_CONFIG"] = str(root / "selected-config")
                env["WORKCELL_EXPECT_CONFIG"] = env["DOCKER_CONFIG"]
            result = subprocess.run([KUJO, "run", *engine, str(probe)], cwd=ROOT,
                                    env=env, capture_output=True, text=True, timeout=60)
            assert result.returncode == 0, result.stdout + result.stderr
print("Docker endpoint: both engines, explicit/default config, no implicit pull or undeclared environment passed")
