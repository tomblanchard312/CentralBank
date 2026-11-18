# CentralBank Smart Contracts - Makefile
# Provides convenient commands for development and deployment

.PHONY: all build test clean deploy-local deploy-local-v2 deploy-lab deploy-lab-v2 deploy-int deploy-int-v2 deploy-stg deploy-stg-v2 deploy-prd-dry-run deploy-prd-dry-run-v2 help

all: build test

# ============================================
# Development
# ============================================

install:
	forge install foundry-rs/forge-std --no-commit

build:
	forge build

test:
	forge test -vvv

test-gas:
	forge test -vvv --gas-report

coverage:
	forge coverage

fmt:
	forge fmt

fmt-check:
	forge fmt --check

clean:
	forge clean

# ============================================
# Local Development
# ============================================

anvil:
	anvil --chain-id 31337 --block-time 2

deploy-local:
	@echo "Deploying CentralBank (v1 integration path) to local Anvil..."
	forge script script/DeployCentralBank.s.sol:DeployLabEnvironment \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvv

deploy-local-v2:
	@echo "Deploying CentralBank Protocol v2 to local Anvil..."
	forge script script/DeployCentralBankV2.s.sol:DeployLabEnvironmentV2 \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvv

# ============================================
# Lab Environment (Kind + Besu)
# ============================================

port-forward:
	kubectl port-forward svc/besu-validator-rpc -n ledger-ecb-core 8545:8545

deploy-lab:
	@echo "Deploying CentralBank (v1 integration path) to Lab (Kind + Besu)..."
	@echo "Ensure port-forward is running: make port-forward"
	forge script script/DeployCentralBank.s.sol:DeployLabEnvironment \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvv

deploy-lab-v2:
	@echo "Deploying CentralBank Protocol v2 to Lab (Kind + Besu)..."
	@echo "Ensure port-forward is running: make port-forward"
	forge script script/DeployCentralBankV2.s.sol:DeployLabEnvironmentV2 \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvv

# ============================================
# Integration Environment
# ============================================

deploy-int:
	@echo "Deploying CentralBank (v1) to Integration..."
	@test -n "$(INT_RPC_URL)" || (echo "INT_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) forge script script/DeployCentralBank.s.sol:DeployCentralBank \
		--rpc-url $(INT_RPC_URL) \
		--broadcast \
		-vvv

deploy-int-v2:
	@echo "Deploying CentralBank Protocol v2 to Integration..."
	@test -n "$(INT_RPC_URL)" || (echo "INT_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) GOVERNANCE_ADDRESS=$(GOVERNANCE_ADDRESS) \
		forge script script/DeployCentralBankV2.s.sol:DeployCentralBankV2 \
		--rpc-url $(INT_RPC_URL) \
		--broadcast \
		-vvv

# ============================================
# Staging Environment
# ============================================

deploy-stg:
	@echo "Deploying CentralBank (v1) to Staging..."
	@test -n "$(STG_RPC_URL)" || (echo "STG_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	@echo "⚠️  Staging deployment - ensure proper approvals"
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) forge script script/DeployCentralBank.s.sol:DeployCentralBank \
		--rpc-url $(STG_RPC_URL) \
		--broadcast \
		-vvv

deploy-stg-v2:
	@echo "Deploying CentralBank Protocol v2 to Staging..."
	@test -n "$(STG_RPC_URL)" || (echo "STG_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	@echo "⚠️  Staging deployment - ensure proper approvals"
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) GOVERNANCE_ADDRESS=$(GOVERNANCE_ADDRESS) \
		forge script script/DeployCentralBankV2.s.sol:DeployCentralBankV2 \
		--rpc-url $(STG_RPC_URL) \
		--broadcast \
		-vvv

# ============================================
# Production - MANUAL ONLY
# ============================================

deploy-prd-dry-run:
	@echo "⚠️  PRODUCTION DRY RUN (v1) - Review carefully!"
	@test -n "$(PRD_RPC_URL)" || (echo "PRD_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) forge script script/DeployCentralBank.s.sol:DeployCentralBank \
		--rpc-url $(PRD_RPC_URL) \
		-vvv
	@echo ""
	@echo "⚠️  To deploy to production:"
	@echo "   1. Review the simulation above"
	@echo "   2. Get multi-sig approval"
	@echo "   3. Execute via governance process"

deploy-prd-dry-run-v2:
	@echo "⚠️  PRODUCTION DRY RUN (v2) - Review carefully!"
	@test -n "$(PRD_RPC_URL)" || (echo "PRD_RPC_URL not set" && exit 1)
	@test -n "$(DEPLOYER_PRIVATE_KEY)" || (echo "DEPLOYER_PRIVATE_KEY not set" && exit 1)
	DEPLOYER_PRIVATE_KEY=$(DEPLOYER_PRIVATE_KEY) GOVERNANCE_ADDRESS=$(GOVERNANCE_ADDRESS) \
		forge script script/DeployCentralBankV2.s.sol:DeployCentralBankV2 \
		--rpc-url $(PRD_RPC_URL) \
		-vvv
	@echo ""
	@echo "⚠️  To deploy Protocol v2 to production:"
	@echo "   1. Review the simulation above"
	@echo "   2. Confirm GOVERNANCE_ADDRESS equals the deployer"
	@echo "   3. Get multi-sig approval"
	@echo "   4. Execute via governance process"

# ============================================
# Utilities
# ============================================

balance:
	@test -n "$(ADDRESS)" || (echo "ADDRESS not set" && exit 1)
	cast balance $(ADDRESS) --rpc-url $(RPC_URL)

chain-id:
	cast chain-id --rpc-url $(RPC_URL)

cbdt-balance:
	@test -n "$(ADDRESS)" || (echo "ADDRESS not set" && exit 1)
	@test -n "$(DIGITAL_TOKEN_ADDRESS)" || (echo "DIGITAL_TOKEN_ADDRESS not set" && exit 1)
	cast call $(DIGITAL_TOKEN_ADDRESS) "balanceOf(address)(uint256)" $(ADDRESS) --rpc-url $(RPC_URL)

verify:
	@echo "Contract verification not implemented for private networks"

# ============================================
# Help
# ============================================

help:
	@echo "CentralBank Smart Contracts"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Development:"
	@echo "  install       Install Foundry dependencies"
	@echo "  build         Build contracts"
	@echo "  test          Run tests"
	@echo "  test-gas      Run tests with gas report"
	@echo "  coverage      Run coverage"
	@echo "  fmt           Format code"
	@echo "  clean         Clean build artifacts"
	@echo ""
	@echo "Local:"
	@echo "  anvil            Start local Anvil node"
	@echo "  deploy-local     Deploy v1 integration path to local Anvil"
	@echo "  deploy-local-v2  Deploy Protocol v2 to local Anvil"
	@echo ""
	@echo "Lab:"
	@echo "  port-forward     Port-forward to Besu in Kind"
	@echo "  deploy-lab       Deploy v1 to lab environment"
	@echo "  deploy-lab-v2    Deploy Protocol v2 to lab environment"
	@echo ""
	@echo "Environments:"
	@echo "  deploy-int / deploy-int-v2"
	@echo "  deploy-stg / deploy-stg-v2"
	@echo "  deploy-prd-dry-run / deploy-prd-dry-run-v2"
	@echo ""
	@echo "Utilities:"
	@echo "  balance       Check native balance"
	@echo "  cbdt-balance  Check CBDT balance"
	@echo "  chain-id      Get chain ID"
