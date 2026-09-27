#!/usr/bin/env bash
# Experimental source-runtime gate, separate from the stable Workcell 1.2.1 pin.
set -euo pipefail
cd "$(dirname "$0")/.."
node tests/git_effect_contract.mjs

node tests/git_participant_contract.mjs
