// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HelperConfig} from "./HelperConfig.s.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {Script} from "forge-std/Script.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract DeployTokenVault is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public returns (TokenVault, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address usdcToken, address account) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(account);
        TokenVault tv = new TokenVault(ERC20(usdcToken));
        vm.stopBroadcast();
        return (tv, helperConfig);
    }
}
