#!/usr/bin/env bash
set -euo pipefail
export PATH="/root/.foundry/bin:$HOME/.foundry/bin:$PATH"
echo "WSL curl:"
curl -s -X POST http://127.0.0.1:8545 -H 'content-type: application/json' --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' || echo FAIL
echo
echo "pgrep:"; pgrep -a anvil || echo NO_ANVIL
echo "log tail:"; tail -n 20 /tmp/centralbank-anvil.log 2>/dev/null || true
