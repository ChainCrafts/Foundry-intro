-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest deploy-local deploy-sepolia deploy-zk deploy-zk-sepolia fund-local fund-sepolia withdraw-local withdraw-sepolia check-env clean-artifacts

# Default values
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110

# Default target
all: clean remove install update build

# Help command
help:
	@echo "Available commands:"
	@echo "  all              - Clean, remove, install, update, and build"
	@echo "  clean            - Clean the forge project"
	@echo "  clean-artifacts  - Clean deployment artifacts"
	@echo "  remove           - Remove git modules"
	@echo "  install          - Install dependencies"
	@echo "  update           - Update dependencies"
	@echo "  build            - Build the project"
	@echo "  zkbuild          - Build for zkSync"
	@echo "  test             - Run tests"
	@echo "  zktest           - Run zkSync tests"
	@echo "  snapshot         - Create gas snapshot"
	@echo "  format           - Format code"
	@echo "  anvil            - Start local Anvil node"
	@echo "  zk-anvil         - Start local zkSync node"
	@echo "  deploy-local     - Deploy to local Anvil"
	@echo "  deploy-sepolia   - Deploy to Sepolia testnet"
	@echo "  deploy-zk        - Deploy to local zkSync"
	@echo "  deploy-zk-sepolia- Deploy to zkSync Sepolia"
	@echo "  fund-local       - Fund contract on local network"
	@echo "  fund-sepolia     - Fund contract on Sepolia"
	@echo "  withdraw-local   - Withdraw from contract on local network"
	@echo "  withdraw-sepolia - Withdraw from contract on Sepolia"
	@echo "  check-env        - Check environment variables"

# Environment validation
check-env:
	@echo "Checking environment variables..."
	@if [ -z "$(SEPOLIA_RPC_URL)" ]; then echo "❌ SEPOLIA_RPC_URL not set"; exit 1; fi
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "❌ ETHERSCAN_API_KEY not set"; exit 1; fi
	@if [ -z "$(ACCOUNT)" ]; then echo "❌ ACCOUNT not set (use 'cast wallet import' to create one)"; exit 1; fi
	@echo "✅ Environment variables are set"

# Clean the repo
clean:
	forge clean

# Clean deployment artifacts
clean-artifacts:
	rm -rf broadcast/*/
	rm -rf cache/*/
	@echo "✅ Deployment artifacts cleaned"

# Remove modules
remove:
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install dependencies
install:
	forge install cyfrin/foundry-devops@0.2.2 --no-commit
	forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit
	forge install foundry-rs/forge-std@v1.8.2 --no-commit

# Update Dependencies
update:
	forge update

# Build
build:
	forge build

# Build for zkSync
zkbuild:
	forge build --zksync

# Test
test:
	forge test

# zkSync test
zktest:
	foundryup-zksync && forge test --zksync && foundryup

# Gas snapshot
snapshot:
	forge snapshot

# Format code
format:
	forge fmt

# Start Anvil
anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Start zkSync local node
zk-anvil:
	npx zksync-cli dev start

# Deploy to local Anvil
deploy-local:
	@echo "🚀 Deploying to local Anvil..."
	@forge script script/DeployFundMe.s.sol:DeployFundMe \
		--rpc-url http://localhost:8545 \
		--private-key $(DEFAULT_ANVIL_KEY) \
		--broadcast

# Deploy to Sepolia
deploy-sepolia: check-env
	@echo "🚀 Deploying to Sepolia..."
	@forge script script/DeployFundMe.s.sol:DeployFundMe \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

# Deploy to local zkSync
deploy-zk:
	@echo "🚀 Deploying to local zkSync..."
	@echo "⚠️  Make sure zkSync local node is running (make zk-anvil)"
	@forge create src/FundMe.sol:FundMe \
		--rpc-url http://127.0.0.1:8011 \
		--private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) \
		--constructor-args $$(forge create test/mocks/MockV3Aggregator.sol:MockV3Aggregator \
			--rpc-url http://127.0.0.1:8011 \
			--private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) \
			--constructor-args 8 200000000000 \
			--legacy --zksync | grep "Deployed to:" | awk '{print $$3}') \
		--legacy --zksync

# Deploy to zkSync Sepolia
deploy-zk-sepolia: check-env
	@echo "🚀 Deploying to zkSync Sepolia..."
	@if [ -z "$(ZKSYNC_SEPOLIA_RPC_URL)" ]; then echo "❌ ZKSYNC_SEPOLIA_RPC_URL not set"; exit 1; fi
	@forge create src/FundMe.sol:FundMe \
		--rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) \
		--account $(ACCOUNT) \
		--constructor-args 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF \
		--legacy --zksync

# Fund contract on local network
fund-local:
	@echo "💰 Funding contract on local network..."
	@forge script script/Interactions.s.sol:FundFundMe \
		--rpc-url http://localhost:8545 \
		--private-key $(DEFAULT_ANVIL_KEY) \
		--broadcast

# Fund contract on Sepolia
fund-sepolia: check-env
	@echo "💰 Funding contract on Sepolia..."
	@forge script script/Interactions.s.sol:FundFundMe \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast

# Withdraw from contract on local network
withdraw-local:
	@echo "💸 Withdrawing from contract on local network..."
	@forge script script/Interactions.s.sol:WithdrawFundMe \
		--rpc-url http://localhost:8545 \
		--private-key $(DEFAULT_ANVIL_KEY) \
		--broadcast

# Withdraw from contract on Sepolia
withdraw-sepolia: check-env
	@echo "💸 Withdrawing from contract on Sepolia..."
	@forge script script/Interactions.s.sol:WithdrawFundMe \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast

# Legacy targets for backward compatibility
deploy: deploy-local
fund: fund-local
withdraw: withdraw-local