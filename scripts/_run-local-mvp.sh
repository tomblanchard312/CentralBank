#!/usr/bin/env bash
# Local orchestration under WSL: Anvil + smoke + Windows API + checklist.
set -euo pipefail
export PATH="/root/.foundry/bin:$HOME/.foundry/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NODE_WIN="/mnt/c/Program Files/nodejs/node.exe"
if [[ ! -x "$NODE_WIN" ]]; then
  echo "Windows Node not found at $NODE_WIN" >&2
  exit 1
fi
export NODE_BIN="$NODE_WIN"

pkill -f '[a]nvil' 2>/dev/null || true

nohup anvil --host 0.0.0.0 --port 8545 --chain-id 31337 >/tmp/centralbank-anvil.log 2>&1 &
ANVIL_PID=$!

cleanup() {
  kill "$ANVIL_PID" 2>/dev/null || true
  cmd.exe /c "taskkill /F /IM node.exe /FI \"WINDOWTITLE eq *tsx*\" " >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in $(seq 1 40); do
  if curl -sf -X POST http://127.0.0.1:8545 \
    -H 'content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' >/dev/null; then
    break
  fi
  sleep 0.25
done

export KEEP_ANVIL=1
bash scripts/lab-mvp-smoke.sh

cp api/.env.lab api/.env

# Convert WSL paths to Windows paths for the Windows-hosted API process.
WIN_PARAMS="$(wslpath -w "$ROOT/envs/lab/ecb-core/parameters.json")"
WIN_PROFILE="$(wslpath -w "$ROOT/profiles/eurosystem-reference.json")"
sed -i "s|^PARAMETERS_FILE=.*|PARAMETERS_FILE=${WIN_PARAMS}|" api/.env
sed -i "s|^PROFILE_FILE=.*|PROFILE_FILE=${WIN_PROFILE}|" api/.env
sed -i 's|^BLOCKCHAIN_RPC_URL=.*|BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545|' api/.env
if grep -q '^ALLOW_DEMO_IDENTITIES=' api/.env; then
  sed -i 's/^ALLOW_DEMO_IDENTITIES=.*/ALLOW_DEMO_IDENTITIES=true/' api/.env
else
  echo 'ALLOW_DEMO_IDENTITIES=true' >> api/.env
fi

cd api
if [[ ! -d node_modules ]]; then
  cmd.exe /c "cd /d $(wslpath -w "$ROOT/api") && npm.cmd ci --legacy-peer-deps"
fi

# Launch API on Windows Node so localhost:8545 mirrored networking works.
cmd.exe /c "cd /d $(wslpath -w "$ROOT/api") && start /b cmd /c \"npx.cmd tsx src/index.ts > %TEMP%\\centralbank-api.log 2>&1\""
cd "$ROOT"

for _ in $(seq 1 90); do
  if curl -sf http://127.0.0.1:3000/api/v1/health/live >/dev/null; then
    echo "API live"
    break
  fi
  sleep 1
done
if ! curl -sf http://127.0.0.1:3000/api/v1/health/live >/dev/null; then
  echo "API failed to become live" >&2
  cmd.exe /c "type %TEMP%\\centralbank-api.log" || true
  exit 1
fi

export ENV_FILE="$ROOT/api/.env"
bash scripts/lab-mvp-demo-checklist.sh
echo "LOCAL_MVP_OK"
