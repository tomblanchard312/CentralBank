#!/usr/bin/env bash
set -euo pipefail
export PATH="/root/.foundry/bin:$HOME/.foundry/bin:$PATH"
pkill -f '[a]nvil' 2>/dev/null || true
nohup anvil --host 0.0.0.0 --port 8545 --chain-id 31337 >/tmp/centralbank-anvil.log 2>&1 &
echo $! >/tmp/centralbank-anvil.pid
for _ in $(seq 1 40); do
  if curl -sf -X POST http://127.0.0.1:8545 \
    -H 'content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' >/dev/null; then
    echo ANVIL_READY
    exit 0
  fi
  sleep 0.25
done
echo ANVIL_FAILED >&2
exit 1
