// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HelperConfig} from "./HelperConfig.s.sol";
import {USDC} from "../src/USDC.sol";
import {Script} from "forge-std/Script.sol";

contract DeployUSDC is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (USDC) {
        HelperConfig helperConfig = new HelperConfig();
        (, address account) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(account);

        USDC usdc = new USDC();
        vm.stopBroadcast();
        return usdc;
    }
}
