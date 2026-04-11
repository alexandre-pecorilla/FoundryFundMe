# The full Makefile for the course is here => https://raw.githubusercontent.com/Cyfrin/foundry-fund-me-cu/refs/heads/main/Makefile


-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--account $(WALLET_ACCOUNT) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvvv