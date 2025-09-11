// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {DeployTokenVault} from "../script/DeployTokenVault.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {USDC} from "../src/USDC.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract TokenVaultTest is Test {
    DeployTokenVault deployer;
    TokenVault tokenVault;
    HelperConfig helperConfig;
    address usdc;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() external {
        deployer = new DeployTokenVault();
        (tokenVault, helperConfig) = deployer.deployContract();
        // Fund users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        (usdc,) = helperConfig.activeNetworkConfig();

        // Fund the users with USDC tokens
        // And approve the TokenVault to spend USDC on behalf of user1 and user2
        // Deal 1000 USDC to user1
        vm.startPrank(user1);
        USDC(usdc).mint(user1, 1000 ether);
        USDC(usdc).approve(address(tokenVault), 1000 ether);
        vm.stopPrank();
        // Deal 1000 USDC to user2
        vm.startPrank(user2);
        USDC(usdc).mint(user2, 1000 ether);
        USDC(usdc).approve(address(tokenVault), 1000 ether);
        vm.stopPrank();
    }

    //
    function testDepositFunction() external {
        // Deposit some USDC into the TokenVault from user1
        vm.startPrank(user1);
        tokenVault.deposit(100);
        // Simulate yield earned by the vault
        USDC(usdc).transfer(address(tokenVault), 50);
        vm.stopPrank();

        assertEq(ERC20(tokenVault).balanceOf(user1), 100);

        // Deposit some USDC into the TokenVault from user2
        vm.startPrank(user2);
        tokenVault.deposit(100);
        vm.stopPrank();

        assertEq(ERC20(tokenVault).balanceOf(user2), 66);

        vm.startPrank(user2);
        tokenVault.withdraw(66, user2);
        vm.stopPrank();

        assertEq(ERC20(tokenVault).balanceOf(user2), 0);
        assertEq(USDC(address(usdc)).balanceOf(user2), 1000 ether);
        // 1000000000000000000000
        // 100000000000000000000
    }
}
