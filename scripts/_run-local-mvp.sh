#!/usr/bin/env bash
# Single-session local MVP runner for WSL (Anvil + smoke + API + checklist).
set -euo pipefail

export PATH="/root/.foundry/bin:$HOME/.foundry/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v node >/dev/null 2>&1; then
  echo "Bootstrapping Node 20 into /tmp for this WSL session..."
  NODE_VER="v20.18.1"
  curl -fsSL "https://nodejs.org/dist/${NODE_VER}/node-${NODE_VER}-linux-x64.tar.xz" -o /tmp/node.tar.xz
  tar -xJf /tmp/node.tar.xz -C /tmp
  export PATH="/tmp/node-${NODE_VER}-linux-x64/bin:$PATH"
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing $1" >&2; exit 1; }; }
need forge
need anvil
need cast
need curl
need node
need npm

pkill -f '[a]nvil' 2>/dev/null || true
pkill -f 'tsx src/index.ts' 2>/dev/null || true

nohup anvil --host 0.0.0.0 --port 8545 --chain-id 31337 >/tmp/centralbank-anvil.log 2>&1 &
ANVIL_PID=$!

for _ in $(seq 1 40); do
  if curl -sf -X POST http://127.0.0.1:8545 \
    -H 'content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' >/dev/null; then
    break
  fi
  sleep 0.25
done

KEEP_ANVIL=1 bash scripts/lab-mvp-smoke.sh

cp api/.env.lab api/.env
sed -i 's/^ALLOW_DEMO_IDENTITIES=.*/ALLOW_DEMO_IDENTITIES=true/' api/.env || true
grep -q '^ALLOW_DEMO_IDENTITIES=' api/.env || echo 'ALLOW_DEMO_IDENTITIES=true' >> api/.env

cd api
# Windows checkouts often have win32 native deps; reinstall for this Linux/WSL session.
if [[ ! -d node_modules ]] || [[ -d node_modules/@esbuild/win32-x64 ]]; then
  rm -rf node_modules
  npm ci --legacy-peer-deps
fi

nohup npx tsx src/index.ts >/tmp/centralbank-api.log 2>&1 &
API_PID=$!
cd "$ROOT"

for _ in $(seq 1 60); do
  if curl -sf http://127.0.0.1:3000/api/v1/health/live >/dev/null; then
    echo "API live"
    break
  fi
  sleep 1
done

if ! curl -sf http://127.0.0.1:3000/api/v1/health/live >/dev/null; then
  echo "API failed to start" >&2
  cat /tmp/centralbank-api.log >&2 || true
  kill "$API_PID" "$ANVIL_PID" 2>/dev/null || true
  exit 1
fi

set +e
bash scripts/lab-mvp-demo-checklist.sh
STATUS=$?
set -e

kill "$API_PID" 2>/dev/null || true
kill "$ANVIL_PID" 2>/dev/null || true

if [[ "$STATUS" -ne 0 ]]; then
  exit "$STATUS"
fi
echo "LOCAL_MVP_OK"
