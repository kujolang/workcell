#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import pathlib
import re
import subprocess
import sys
import urllib.parse

root = pathlib.Path(sys.argv[1]).resolve()
tracked = subprocess.run(
    ["git", "-C", str(root), "ls-files", "--cached", "--others", "--exclude-standard", "*.md"],
    check=True,
    capture_output=True,
    text=True,
).stdout.splitlines()
inline = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
reference = re.compile(r"^\s*\[[^\]]+\]:\s*(\S+)", re.MULTILINE)
broken = []

for relative in tracked:
    source = root / relative
    text = source.read_text(encoding="utf-8")
    targets = inline.findall(text) + reference.findall(text)
    for raw in targets:
        raw = raw.strip()
        if raw.startswith("<") and ">" in raw:
            target = raw[1 : raw.index(">")]
        else:
            target = raw.split()[0]
        if not target or target.startswith(("#", "//")):
            continue
        parsed = urllib.parse.urlsplit(target)
        if parsed.scheme or parsed.netloc:
            continue
        path_text = urllib.parse.unquote(parsed.path)
        if not path_text:
            continue
        candidate = (root / path_text.lstrip("/")) if path_text.startswith("/") else (source.parent / path_text)
        if not candidate.resolve().exists():
            broken.append(f"{relative}: {target}")

if broken:
    print("Broken local Markdown links:", file=sys.stderr)
    for item in broken:
        print(f"  {item}", file=sys.stderr)
    raise SystemExit(1)

print(f"Markdown link audit passed: {len(tracked)} tracked files")
PY
