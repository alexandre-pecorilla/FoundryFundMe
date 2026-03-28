// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Deploy mocks when we are on a local anvil chain
// keep track of the contract addresses across the different chains

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed; // ETH/USD Price Feed contract address
    }

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            // check if the current chain is sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // get the chainlink Price Feed contract address on Sepolia
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    // get the mock Price Feed contract address on Anvil
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // address(0) is the default value for an unset address in Solidity.
        // If a mock was already deployed during this script run,
        // return the existing config to avoid deploying duplicates.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // Deploy the mock contract and the mock address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
