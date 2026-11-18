#!/usr/bin/env bash
# Walks docs/mvp-demo-checklist.md against a running lab API + .env from lab-mvp-smoke.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_URL="${API_URL:-http://127.0.0.1:3000}"
ENV_FILE="${ENV_FILE:-$ROOT/api/.env}"
RESULTS=()

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd cast

if [[ -z "${NODE_BIN:-}" ]]; then
  if command -v node >/dev/null 2>&1; then
    NODE_BIN="$(command -v node)"
  elif [[ -x "/mnt/c/Program Files/nodejs/node.exe" ]]; then
    NODE_BIN="/mnt/c/Program Files/nodejs/node.exe"
  else
    echo "Missing required command: node" >&2
    exit 1
  fi
fi
node() { "$NODE_BIN" "$@"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — run scripts/lab-mvp-smoke.sh first" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
# shellcheck source=/dev/null
source <(grep -E '^[A-Z0-9_]+=' "$ENV_FILE" | sed 's/\r$//')
set +a

RPC_URL="${BLOCKCHAIN_RPC_URL:-http://127.0.0.1:8545}"
OPERATOR_KEY="${BLOCKCHAIN_OPERATOR_PRIVATE_KEY:?BLOCKCHAIN_OPERATOR_PRIVATE_KEY required}"
TOKEN="${CONTRACT_DIGITAL_TOKEN:?}"
REGISTRY="${CONTRACT_WALLET_REGISTRY:?}"
PAYMENTS="${CONTRACT_CONDITIONAL_PAYMENTS:?}"
PERMISSIONING="${CONTRACT_PERMISSIONING:?}"

pass() {
  RESULTS+=("PASS|$1|$2")
  echo "PASS  $1 — $2"
}

fail() {
  RESULTS+=("FAIL|$1|$2")
  echo "FAIL  $1 — $2" >&2
  exit 1
}

uuid() {
  node -e "console.log(require('crypto').randomUUID())"
}

api() {
  local method="$1"
  local path="$2"
  local key="$3"
  local body="${4:-}"
  local tmp
  tmp="$(mktemp)"
  local code
  if [[ -n "$body" ]]; then
    code="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" "$API_URL$path" \
      -H "Content-Type: application/json" \
      -H "X-API-Key: $key" \
      --data "$body" || true)"
  else
    code="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" "$API_URL$path" \
      -H "X-API-Key: $key" || true)"
  fi
  if [[ "$code" != 200 && "$code" != 201 ]]; then
    echo "HTTP $code for $method $path: $(cat "$tmp")" >&2
    rm -f "$tmp"
    return 22
  fi
  cat "$tmp"
  rm -f "$tmp"
}

# Anvil account #2 / #3 for payer and payee (funded by Anvil defaults).
PAYER_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
PAYEE_KEY="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
PAYER="$(cast wallet address --private-key "$PAYER_KEY")"
PAYEE="$(cast wallet address --private-key "$PAYEE_KEY")"
BANK="0x00000000000000000000000000000000000000b1"
KYC_BANK="$(cast keccak "kyc-bank-mvp")"
KYC_PAYER="$(cast keccak "kyc-payer-mvp")"
KYC_PAYEE="$(cast keccak "kyc-payee-mvp")"

echo "=== Reference MVP demo checklist ==="
echo "API=$API_URL TOKEN=$TOKEN"
echo ""

# 1. API live
LIVE="$(curl -sf "$API_URL/api/v1/health/live" || true)"
echo "$LIVE" | grep -q '"status":"alive"' && pass "1 API live" "$LIVE" || fail "1 API live" "$LIVE"

# 2. Wallet register (bank + payer + payee)
api POST /api/v1/wallets demo-psp-key "$(cat <<JSON
{"wallet":"$BANK","walletType":"BANK","kycHash":"$KYC_BANK","idempotencyKey":"$(uuid)"}
JSON
)" >/tmp/mvp-wallet-bank.json
api POST /api/v1/wallets demo-psp-key "$(cat <<JSON
{"wallet":"$PAYER","walletType":"INDIVIDUAL","linkedBankAccount":"$BANK","kycHash":"$KYC_PAYER","idempotencyKey":"$(uuid)"}
JSON
)" >/tmp/mvp-wallet-payer.json
api POST /api/v1/wallets demo-psp-key "$(cat <<JSON
{"wallet":"$PAYEE","walletType":"INDIVIDUAL","linkedBankAccount":"$BANK","kycHash":"$KYC_PAYEE","idempotencyKey":"$(uuid)"}
JSON
)" >/tmp/mvp-wallet-payee.json
pass "2 Wallet register" "bank+payer+payee registered"

# 3. Mint
MINT_AMOUNT=50000
api POST /api/v1/transfers/mint demo-ecb-key "$(cat <<JSON
{"to":"$PAYER","amount":$MINT_AMOUNT,"justification":"mvp-demo-mint","idempotencyKey":"$(uuid)"}
JSON
)" >/tmp/mvp-mint.json
BAL="$(curl -sf -H "X-API-Key: demo-ecb-key" "$API_URL/api/v1/transfers/balance/$PAYER")"
echo "$BAL" | grep -q "\"balance\":\"$MINT_AMOUNT\"" && pass "3 Mint" "$BAL" || fail "3 Mint" "$BAL"

# 4. Payer-signed transfer
TRANSFER_AMOUNT=2500
SIGNED_TRANSFER="$(
  cd "$ROOT/api" && node --input-type=module <<NODE
import { Wallet, JsonRpcProvider, Interface } from 'ethers';
import { readFileSync } from 'node:fs';

const env = Object.fromEntries(
  readFileSync(${JSON.stringify("$ENV_FILE")}, 'utf8')
    .split(/\\r?\\n/)
    .filter((l) => /^[A-Z0-9_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1)];
    }),
);
const provider = new JsonRpcProvider(env.BLOCKCHAIN_RPC_URL);
const payer = new Wallet(${JSON.stringify("$PAYER_KEY")}, provider);
const token = new Interface([
  'function transfer(address to, uint256 amount) returns (bool)',
]);
const data = token.encodeFunctionData('transfer', [${JSON.stringify("$PAYEE")}, ${TRANSFER_AMOUNT}n]);
const nonce = await provider.getTransactionCount(payer.address, 'pending');
const network = await provider.getNetwork();
const fee = await provider.getFeeData();
const raw = await payer.signTransaction({
  to: env.CONTRACT_DIGITAL_TOKEN,
  data,
  chainId: network.chainId,
  nonce,
  gasLimit: 300000n,
  maxFeePerGas: fee.maxFeePerGas ?? 1_000_000_000n,
  maxPriorityFeePerGas: fee.maxPriorityFeePerGas ?? 1_000_000_000n,
  value: 0n,
  type: 2,
});
process.stdout.write(raw);
NODE
)"
api POST /api/v1/transfers demo-bank-key "$(cat <<JSON
{"from":"$PAYER","to":"$PAYEE","amount":$TRANSFER_AMOUNT,"idempotencyKey":"$(uuid)","signedTransaction":"$SIGNED_TRANSFER"}
JSON
)" >/tmp/mvp-transfer.json
pass "4 Payer-signed transfer" "amount=$TRANSFER_AMOUNT"

# 5. Waterfall — lower holding limit below balance, then sweep
cast send "$REGISTRY" "setCustomLimit(address,uint256)" "$PAYER" 1000 \
  --rpc-url "$RPC_URL" --private-key "$OPERATOR_KEY" >/tmp/mvp-limit.txt
api POST /api/v1/transfers/waterfall demo-ecb-key "$(cat <<JSON
{"wallet":"$PAYER"}
JSON
)" >/tmp/mvp-waterfall.json
pass "5 Waterfall" "$(cat /tmp/mvp-waterfall.json)"

# 6. Conditional payment create + confirm delivery
# Re-raise limit so remaining balance can escrow; mint a bit more if needed.
cast send "$REGISTRY" "setCustomLimit(address,uint256)" "$PAYER" 300000 \
  --rpc-url "$RPC_URL" --private-key "$OPERATOR_KEY" >/tmp/mvp-limit2.txt
api POST /api/v1/transfers/mint demo-ecb-key "$(cat <<JSON
{"to":"$PAYER","amount":10000,"justification":"mvp-demo-cp-fund","idempotencyKey":"$(uuid)"}
JSON
)" >/tmp/mvp-mint2.json

CP_AMOUNT=1000
CP_IDEM="$(uuid)"
EXPIRES_AT=$(( $(date +%s) + 7200 ))
CONDITION_DATA="$(cast keccak "mvp-delivery")"
PROOF="$(cast keccak "mvp-delivery-proof")"
ARBITER="$(cast wallet address --private-key "$OPERATOR_KEY")"

# Approve ConditionalPayments to pull from payer
cast send "$TOKEN" "approve(address,uint256)" "$PAYMENTS" "$CP_AMOUNT" \
  --rpc-url "$RPC_URL" --private-key "$PAYER_KEY" >/tmp/mvp-approve.txt

SIGNED_CP="$(
  cd "$ROOT/api" && node --input-type=module <<NODE
import { Wallet, JsonRpcProvider, Interface, keccak256, toUtf8Bytes } from 'ethers';
import { readFileSync } from 'node:fs';

const env = Object.fromEntries(
  readFileSync(${JSON.stringify("$ENV_FILE")}, 'utf8')
    .split(/\\r?\\n/)
    .filter((l) => /^[A-Z0-9_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1)];
    }),
);
const provider = new JsonRpcProvider(env.BLOCKCHAIN_RPC_URL);
const payer = new Wallet(${JSON.stringify("$PAYER_KEY")}, provider);
const iface = new Interface([
  'function createConditionalPayment(address payee,uint256 amount,uint8 conditionType,bytes32 conditionData,uint256 expiresAt,address arbiter,bytes32 idempotencyKey) returns (bytes32)',
]);
const idem = ${JSON.stringify("$CP_IDEM")};
const key = /^0x[a-fA-F0-9]{64}$/.test(idem) ? idem : keccak256(toUtf8Bytes(idem));
const data = iface.encodeFunctionData('createConditionalPayment', [
  ${JSON.stringify("$PAYEE")},
  ${CP_AMOUNT}n,
  0,
  ${JSON.stringify("$CONDITION_DATA")},
  ${EXPIRES_AT},
  ${JSON.stringify("$ARBITER")},
  key,
]);
const nonce = await provider.getTransactionCount(payer.address, 'pending');
const network = await provider.getNetwork();
const fee = await provider.getFeeData();
const raw = await payer.signTransaction({
  to: env.CONTRACT_CONDITIONAL_PAYMENTS,
  data,
  chainId: network.chainId,
  nonce,
  gasLimit: 500000n,
  maxFeePerGas: fee.maxFeePerGas ?? 1_000_000_000n,
  maxPriorityFeePerGas: fee.maxPriorityFeePerGas ?? 1_000_000_000n,
  value: 0n,
  type: 2,
});
process.stdout.write(raw);
NODE
)"

CP_CREATE="$(api POST /api/v1/payments demo-bank-key "$(cat <<JSON
{"payer":"$PAYER","payee":"$PAYEE","amount":$CP_AMOUNT,"conditionType":"DELIVERY","conditionData":"$CONDITION_DATA","expiresAt":$EXPIRES_AT,"arbiter":"$ARBITER","idempotencyKey":"$CP_IDEM","signedTransaction":"$SIGNED_CP"}
JSON
)")"
PAYMENT_ID="$(node -e "const j=JSON.parse(process.argv[1]); if(!j?.data?.paymentId) process.exit(2); process.stdout.write(j.data.paymentId)" "$CP_CREATE")"

SIGNED_CONFIRM="$(
  cd "$ROOT/api" && node --input-type=module <<NODE
import { Wallet, JsonRpcProvider, Interface } from 'ethers';
import { readFileSync } from 'node:fs';

const env = Object.fromEntries(
  readFileSync(${JSON.stringify("$ENV_FILE")}, 'utf8')
    .split(/\\r?\\n/)
    .filter((l) => /^[A-Z0-9_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1)];
    }),
);
const provider = new JsonRpcProvider(env.BLOCKCHAIN_RPC_URL);
const payer = new Wallet(${JSON.stringify("$PAYER_KEY")}, provider);
const iface = new Interface([
  'function confirmDelivery(bytes32 paymentId, bytes32 proof)',
]);
const data = iface.encodeFunctionData('confirmDelivery', [
  ${JSON.stringify("$PAYMENT_ID")},
  ${JSON.stringify("$PROOF")},
]);
const nonce = await provider.getTransactionCount(payer.address, 'pending');
const network = await provider.getNetwork();
const fee = await provider.getFeeData();
const raw = await payer.signTransaction({
  to: env.CONTRACT_CONDITIONAL_PAYMENTS,
  data,
  chainId: network.chainId,
  nonce,
  gasLimit: 400000n,
  maxFeePerGas: fee.maxFeePerGas ?? 1_000_000_000n,
  maxPriorityFeePerGas: fee.maxPriorityFeePerGas ?? 1_000_000_000n,
  value: 0n,
  type: 2,
});
process.stdout.write(raw);
NODE
)"

api POST "/api/v1/payments/$PAYMENT_ID/confirm-delivery" demo-bank-key "$(cat <<JSON
{"paymentId":"$PAYMENT_ID","proof":"$PROOF","payer":"$PAYER","signedTransaction":"$SIGNED_CONFIRM"}
JSON
)" >/tmp/mvp-cp-confirm.json
pass "6 Conditional payment" "paymentId=$PAYMENT_ID"

# 7. Freeze / pause
api POST /api/v1/transfers/freeze demo-ecb-key "$(cat <<JSON
{"account":"$PAYEE","reason":"mvp-demo-freeze"}
JSON
)" >/tmp/mvp-freeze.json
api POST /api/v1/admin/system/pause demo-ecb-key >/tmp/mvp-pause.json
api POST /api/v1/admin/system/unpause demo-ecb-key >/tmp/mvp-unpause.json
api POST /api/v1/transfers/unfreeze demo-ecb-key "$(cat <<JSON
{"account":"$PAYEE"}
JSON
)" >/tmp/mvp-unfreeze.json
pass "7 Freeze / pause" "freeze+pause+unpause+unfreeze"

# 8. Profile coherence — good pair loads; bad pair fails closed
(
  cd "$ROOT/api"
  npx vitest run test/profile-coherence.test.ts >/tmp/mvp-profile.out 2>&1
)
pass "8 Profile coherence" "profile-coherence.test.ts"

# 9. Reconciliation lab unit tests
(
  cd "$ROOT/tools/reconciliation-ref"
  npm ci --silent
  CENTRALBANK_ENV=test npm test
) >/tmp/mvp-recon.out 2>&1
pass "9 Reconciliation lab" "CENTRALBANK_ENV=test npm test"

echo ""
echo "=== All checklist items passed ==="
for row in "${RESULTS[@]}"; do
  echo "$row"
done
