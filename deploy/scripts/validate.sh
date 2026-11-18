#!/bin/bash
set -euo pipefail

# Validation script for CBDT deployment

echo "Validating deployment prerequisites..."

# Check tools
echo "Checking tools..."
command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "docker-compose not found"; exit 1; }

if [[ "${CENTRALBANK_ENV:-}" != "local" ]]; then
    command -v terraform >/dev/null 2>&1 || { echo "terraform not found"; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; exit 1; }
fi

# Check environment variables
echo "Checking environment variables..."
[[ -n "${CENTRALBANK_ENV:-}" ]] || { echo "CENTRALBANK_ENV not set"; exit 1; }
[[ -n "${CENTRALBANK_ROLE:-}" ]] || { echo "CENTRALBANK_ROLE not set"; exit 1; }

# Check keys
echo "Checking keys..."
required_keys=("CENTRALBANK_ROOT_CA_KEY" "CENTRALBANK_ISSUER_KEY" "CENTRALBANK_ACQUIRER_KEY" "CENTRALBANK_PSP_KEY")
for key in "${required_keys[@]}"; do
    if [[ -z "${!key:-}" ]]; then
        key_file="$PROJECT_ROOT/keys/${key}.pem"
        [[ -f "$key_file" ]] || { echo "$key not found in env or file"; exit 1; }
    fi
done

echo "Validation passed."