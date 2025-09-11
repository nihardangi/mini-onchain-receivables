-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
else ifeq ($(findstring --network fuji,$(ARGS)),--network fuji)
	NETWORK_ARGS := --rpc-url $(FUJI_RPC_URL) --account $(ACCOUNT) --broadcast --verify --chain-id 43113 --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43114/etherscan' --etherscan-api-key $(SNOWTRACE_API_KEY) -vvvv
else ifeq ($(findstring --network baseSepolia,$(ARGS)),--network baseSepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --chain-id 84532 --etherscan-api-key $(BASESCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployTokenVault.s.sol:DeployTokenVault $(NETWORK_ARGS)

# NETWORK_ARGS := --rpc-url $(FUJI_RPC_URL) --account $(ACCOUNT) --broadcast --verify --chain-id 43113 --etherscan-api-key $(SNOWTRACE_API_KEY) -vvvv	
# NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --chain-id 84532 --etherscan-api-key $(BASESCAN_API_KEY) -vvvv

# Deploy on Sepolia
# forge script script/DeployRathSwapRouter.s.sol:DeployRathSwapRouter --rpc-url $SEPOLIA_RPC_URL --fork-url $SEPOLIA_RPC_URL --account $ACCOUNT --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv

# Deploy on Base Sepolia
# forge script script/DeployRathSwapRouter.s.sol:DeployRathSwapRouter --rpc-url $BASE_SEPOLIA_RPC_URL --account $ACCOUNT --broadcast --verify --chain-id 84532 --etherscan-api-key $BASESCAN_API_KEY -vvvv

# Deploy on Avalanche Fuji
# forge script script/DeployRathSwapRouter.s.sol:DeployRathSwapRouter --rpc-url $FUJI_RPC_URL --account $ACCOUNT --broadcast --verify --chain-id 43113 --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan' --etherscan-api-key $SNOWTRACE_API_KEY -vvvv


# Verify contract on Fuji
# forge verify-contract 0x23BA06d21386495201412E8941c7B40fE2eAe8B6 src/TestToken.sol:TestToken --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version v0.8.28 --constructor-args $(cast abi-encode "constructor(string memory name, string memory symbol)" Floki FLOKI)

# forge verify-contract 0x6622e617d5F67A814a9D43ff2e05C451701B4E24 src/RathSwapRouter.sol:RathSwapRouter --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version v0.8.28 --constructor-args $(cast abi-encode "constructor(address _gatewayMinter, address _tokenSwap, address _owner)" 0x0022222ABE238Cc2C7Bb1f21003F0a260052475B 0x8940188c233A75CB88e1be5a4A90d392B54a9601 0xED2C3b451e15f57bf847c60b65606eCFB73C85d9)


# forge script script/DeployUSDC.s.sol:DeployUSDC --rpc-url $SEPOLIA_RPC_URL --fork-url $SEPOLIA_RPC_URL --account $ACCOUNT --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
