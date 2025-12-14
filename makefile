include .env
export

BASE_SEPOLIA_ARGS := --rpc-url $(RPC_URL_BASE_SEPOLIA) \
					 --account defaultKey \
					 --broadcast \
					 --verify \
					 --etherscan-api-key $(ETHERSCAN_API) \

deployTestnet:
	@forge clean
	@echo "Deploying SongDB to Base testnet"
	@forge script script/SongDB.s.sol:SongDBScript $(BASE_SEPOLIA_ARGS)

unitTest:
	@echo "Running SongDB unit tests"
	@forge 	test --match-path \
			test/unit/$(TEST_TYPE)/SongDB.t.sol \
			--summary --detailed --gas-report -vvvvv --show-progress