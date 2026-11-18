#!/usr/bin/env bash
set -euo pipefail
curl -sf -X POST http://127.0.0.1:8545 \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
echo
test -f /mnt/c/Users/TomBlanchard/CentralBank/api/.env.lab && echo HAS_ENV
