// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ReceivableNft} from "./ReceivableNFT.sol";
import {USDC} from "./usdc.sol";

/*
     * @title ReceivableVault
     * @author Nihar Dangi
     *
     * The system is designed to be as minimal as possible. 
     * It has been assumed that the receivable amount will be in our mock USDC value.
     *     
     *
     * @notice This contract is the core of the Receivable Vault system. It handles all the logic
     * for depositing and withdrawing Receivable NFTs, as well as depositing and withdrawing assets.     
*/
contract ReceivableVault is ERC4626 {
    event ReceivableDeposited(uint256 tokenId, uint256 amount, address depositor);
    event ReceivableMarkedAsPaid(uint256 tokenId, address issuer);
    event ReceivableWithdrawn(uint256 tokenId, address receiver);

    ReceivableNft public immutable nftCollection;
    uint256 liquidAssets;
    uint256 outstandingAssets;
    address usdc;
    uint256 feeBasisPoints;
    mapping(uint256 => address) public receivableDepositor;

    constructor(ERC20 asset, address _nftCollection, uint256 _feeBasisPoints) ERC4626(asset, "vaultUSDC", "vUSDC") {
        usdc = address(asset);
        nftCollection = ReceivableNft(_nftCollection);
        feeBasisPoints = _feeBasisPoints;
    }

    function depositNFT(uint256 tokenId) external {
        (uint256 amount,,,, bool paid,) = nftCollection.tokenIdtoReceivable(tokenId);
        if (paid) {
            revert("Receivable is already paid, can't deposit");
        }
        receivableDepositor[tokenId] = msg.sender;
        // Transfer the NFT from msg.sender to this contract
        nftCollection.safeTransferFrom(msg.sender, address(this), tokenId);
        // Subtract fee and calculate new amount
        uint256 fee = (amount * feeBasisPoints) / 10000;
        uint256 newAmount = amount - fee;
        // Transfer USDC from this contract to msg.sender
        USDC(usdc).transfer(msg.sender, newAmount);
        liquidAssets -= newAmount;
        outstandingAssets += newAmount;
        emit ReceivableDeposited(tokenId, amount, msg.sender);
    }

    function markAsPaid(uint256 tokenId) external {
        (uint256 amount,, address issuer,, bool paid,) = nftCollection.tokenIdtoReceivable(tokenId);
        require(msg.sender == issuer, "Only the issuer can mark as paid");
        require(!paid, "Receivable is already marked as paid");
        nftCollection.markAsPaid(tokenId);
        emit ReceivableMarkedAsPaid(tokenId, msg.sender);
        // Pending: Reduce value of valuated assets and increase liquid assets in the vault
        outstandingAssets -= amount;
        liquidAssets += amount;
    }

    function withdraw(uint256 shares, address receiver) public {
        uint256 currShares = balanceOf[msg.sender];
        // checks that the deposited amount is greater than zero.
        require(shares > 0, "withdraw must be greater than zero");
        // Checks that the _receiver address is not zero.
        require(receiver != address(0), "Zero Address");
        // checks that the caller is a shareholder
        require(currShares > 0, "Not a shareHolder");
        // checks that the caller has more shares than they are trying to withdraw.
        require(currShares >= shares, "Not enough shares");
        // calling the redeem function of ERC-4626 to perform all the functionality
        redeem(shares, receiver, msg.sender);
    }

    function withdrawNFT(uint256 tokenId, address receiver) external {
        if (msg.sender != receivableDepositor[tokenId]) {
            revert("Only the depositor can withdraw the NFT");
        }
        (,,,, bool paid,) = nftCollection.tokenIdtoReceivable(tokenId);
        if (!paid) {
            revert("Receivable is not paid yet, can't withdraw");
        }
        // transfer the NFT to the receiver
        nftCollection.safeTransferFrom(address(this), receiver, tokenId);
        emit ReceivableWithdrawn(tokenId, receiver);
    }

    function totalAssets() public view override returns (uint256) {
        return liquidAssets + outstandingAssets;
    }
}

// Lender deposits assets into the vault, hoping to earn yield.
// Borrower deposits receivable NFT into the vault and gets assets in USDC minus fee.
// Payment processor (i.e the issuer in receivable) is responsible to mark the receivable as paid when the payment has been settled.
// When the receivable is paid, the borrower can withdraw the NFT from the vault.
// Lender can withdraw their assets plus yield at anytime from the vault.

// Issuer calls vault to mark the receivable as paid.
// Vault calls the markAsPaid function in the ReceivableNFT contract.
// Vault updates its accounting to reflect the payment received.
