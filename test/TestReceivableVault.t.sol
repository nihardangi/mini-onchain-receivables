// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployReceivableVault} from "../script/DeployReceivableVault.s.sol";
import {ReceivableVault} from "../src/ReceivableVault.sol";
import {ReceivableNft} from "../src/ReceivableNft.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {USDC} from "../src/USDC.sol";
import {console} from "forge-std/console.sol";

contract TestReceivableVault is Test {
    DeployReceivableVault deployer;
    ReceivableVault receivableVault;
    ReceivableNft receivableNft;
    HelperConfig helperConfig;
    address usdc;
    address lender1 = makeAddr("lender1");
    address lender2 = makeAddr("lender2");
    address borrower1 = makeAddr("borrower1");

    address processor1 = makeAddr("processor1");
    address payer1 = makeAddr("payer1");

    uint256 constant FEE_BASIS_POINTS = 100; // 1% fee
    uint256 constant seedAmount = 1000 ether;

    function setUp() external {
        deployer = new DeployReceivableVault();
        (receivableVault, receivableNft, helperConfig) = deployer.deployContract();

        (usdc,) = helperConfig.activeNetworkConfig();

        vm.startPrank(DEFAULT_SENDER);
        // Set the receivable vault in the receivable NFT contract
        receivableNft.setReceivableVault(address(receivableVault));
        // Fund the lenders with USDC tokens
        USDC(usdc).mint(lender1, seedAmount);
        USDC(usdc).mint(lender2, seedAmount);
        // Fund the payer with USDC tokens
        USDC(usdc).mint(payer1, seedAmount);
        vm.stopPrank();

        // Approve the TokenVault to spend USDC on behalf of lender1 and lender2
        vm.startPrank(lender1);
        USDC(usdc).approve(address(receivableVault), 1000 ether);
        vm.stopPrank();

        vm.startPrank(lender2);
        USDC(usdc).approve(address(receivableVault), 1000 ether);
        vm.stopPrank();
    }

    function depositAssets(address lender, uint256 depositAmount) private {
        // uint256 depositAmount = 100 ether;
        // Lender 1 deposits 100 USDC into the receivable vault
        vm.startPrank(lender);
        receivableVault.deposit(depositAmount, lender);
        vm.stopPrank();
    }

    function mintNFT() private {
        // Owner mints Receivable NFT for borrower1.
        vm.startPrank(DEFAULT_SENDER);
        uint256 amount = 50 ether;
        receivableNft.mintNFT(amount, block.timestamp + 30 days, processor1, payer1, "tokenUri", borrower1);
        vm.stopPrank();
    }

    function depositNFT(uint256 tokenId) private {
        // Borrower1 deposits the receivable NFT into the vault
        vm.startPrank(borrower1);
        receivableNft.approve(address(receivableVault), tokenId);
        receivableVault.depositNFT(tokenId);
        vm.stopPrank();
    }

    function testEntireFlowExecution() external {
        // ------------------------------LENDER DEPOSITING ASSETS INTO THE VAULT--------------------------------
        uint256 lender1DepositAmount = 100 ether;
        uint256 lender2DepositAmount = 50 ether;
        uint256 depositAmount = lender1DepositAmount + lender2DepositAmount;
        depositAssets(lender1, lender1DepositAmount);
        depositAssets(lender2, lender2DepositAmount);
        assertEq(USDC(usdc).balanceOf(address(receivableVault)), depositAmount);

        uint256 rcvAmount = 50 ether; // Amount in the receivable NFT

        // ------------------------------MINTING RECEIVABLE NFT--------------------------------
        mintNFT();
        uint256 expectedNFTs = 1;
        uint256 tokenId = 0;
        // Check the NFT balance and owner
        assertEq(receivableNft.balanceOf(borrower1), expectedNFTs);
        assertEq(receivableNft.ownerOf(tokenId), borrower1);

        // ------------------------------DEPOSITING RECEIVABLE NFT--------------------------------
        depositNFT(tokenId);
        // Check the NFT balance and owner after depositing the NFT into the vault
        assertEq(receivableNft.balanceOf(borrower1), tokenId);
        assertEq(receivableNft.balanceOf(address(receivableVault)), expectedNFTs);
        assertEq(receivableNft.ownerOf(tokenId), address(receivableVault));

        // Subtract fee and calculate new amount
        uint256 fee = (rcvAmount * FEE_BASIS_POINTS) / 10000;
        uint256 newAmount = rcvAmount - fee;
        console.log("newAmount", newAmount);

        // Compare liquid assets
        assertEq(receivableVault.getLiquidAssets(), depositAmount - newAmount);
        // Compare outstanding assets
        assertEq(receivableVault.getOutstandingAssets(), rcvAmount);
        // Compare balance of borrower1 after depositing the NFT
        assertEq(USDC(usdc).balanceOf(borrower1), newAmount);

        // ------------------------------ISSUER MARKING RECEIVABLE AS PAID--------------------------------
        // Simulate time after 7 days
        vm.warp(block.timestamp + 7 days);
        // Payer makes the payment to the vault
        vm.startPrank(payer1);
        USDC(usdc).transfer(address(receivableVault), rcvAmount);
        vm.stopPrank();
        // Issuer marks receivable as paid
        vm.startPrank(processor1);
        receivableVault.markAsPaid(tokenId);
        vm.stopPrank();

        // Check the receivable is actually marked as paid
        (,,,, bool paid,) = receivableNft.tokenIdtoReceivable(tokenId);
        assertEq(paid, true);
        // Compare liquid assets after payment
        assertEq(receivableVault.getLiquidAssets(), depositAmount - newAmount + rcvAmount);
        assertEq(USDC(usdc).balanceOf(address(receivableVault)), depositAmount + rcvAmount - newAmount);
        // Compare outstanding assets after payment
        assertEq(receivableVault.getOutstandingAssets(), 0);

        // Borrower1 withdraws the NFT after payment is done
        vm.startPrank(borrower1);
        receivableVault.withdrawNFT(tokenId, borrower1);
        vm.stopPrank();

        // Check the NFT balance and owner after withdrawing
        assertEq(receivableNft.balanceOf(borrower1), expectedNFTs);
        assertEq(receivableNft.ownerOf(tokenId), borrower1);

        // ------------------------------LENDER2 WITHDRAWS ASSETS FROM THE VAULT--------------------------------
        vm.startPrank(lender2);
        uint256 lender2Shares = receivableVault.balanceOf(lender2);
        uint256 totalShares = receivableVault.totalSupply();
        uint256 totalAssets = receivableVault.totalAssets();
        receivableVault.withdraw(lender2Shares, lender2);
        vm.stopPrank();

        uint256 expectedAssets = (lender2Shares * totalAssets) / totalShares;
        assertEq(USDC(usdc).balanceOf(lender2), seedAmount - lender2DepositAmount + expectedAssets);
        assertEq(receivableVault.balanceOf(lender2), 0);
        // Check the liquid assets after lender2 withdraws
        assertEq(receivableVault.getLiquidAssets(), depositAmount + (rcvAmount - newAmount) - expectedAssets);
    }
}
