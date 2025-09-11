// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";
import {TokenVault} from "../src/TokenVault.sol";

contract HelperConfig is Script {
    // Ethereum Sepolia addresses for USDC and TokenVault
    address private constant SEPOLIA_USDC_TEST_TOKEN_ADDRESS = 0xE44a136D4008945169E2b4365757dD3eD3c2209C;
    // address private constant SEPOLIA_TOKEN_VAULT_ADDRESS = 0x62C9baFDA1fCa3777476E19d8E96e1611d0d434D;

    address private constant PROD_DEPLOYER_ADDRESS = 0xED2C3b451e15f57bf847c60b65606eCFB73C85d9;

    address private constant ANVIL_DEPLOYER_ADDRESS = DEFAULT_SENDER;

    struct NetworkConfig {
        address usdcToken;
        // uint256 feeBasisPoints;
        address account;
    }

    // struct RathSwapRouterNetworkConfig {
    //     address gatewayMinter;
    //     address tokenSwap;
    //     address owner;
    //     address account;
    // }

    NetworkConfig public activeNetworkConfig;
    // RathSwapRouterNetworkConfig public activeRathSwapRouterNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory networkConfig = NetworkConfig({
            usdcToken: SEPOLIA_USDC_TEST_TOKEN_ADDRESS,
            // feeBasisPoints: 100,
            account: PROD_DEPLOYER_ADDRESS
        });

        return networkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.usdcToken != address(0)) {
            return activeNetworkConfig;
        }
        MockERC20 erc20Mock = new MockERC20("USDC", "USDC", 18);
        return NetworkConfig({usdcToken: address(erc20Mock), account: ANVIL_DEPLOYER_ADDRESS});
    }
}
