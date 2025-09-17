// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HelperConfig} from "./HelperConfig.s.sol";
import {ReceivableNft} from "../src/ReceivableNft.sol";
import {ReceivableVault} from "../src/ReceivableVault.sol";
import {Script} from "forge-std/Script.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract DeployReceivableVault is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (ReceivableVault, ReceivableNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address usdc, address account) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(account);
        ReceivableNft receivableNft = new ReceivableNft();
        ReceivableVault receivableVault = new ReceivableVault(ERC20(usdc), address(receivableNft), 100);
        vm.stopBroadcast();
        return (receivableVault, receivableNft, helperConfig);
    }
}
