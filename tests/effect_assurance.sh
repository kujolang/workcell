#!/usr/bin/env bash
# Experimental profile gate on the released Kujo runtime; no contract promotion.
set -euo pipefail
cd "$(dirname "$0")/.."
node tests/git_effect_contract.mjs

node tests/git_participant_contract.mjs
