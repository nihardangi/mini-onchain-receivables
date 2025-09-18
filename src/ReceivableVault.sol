// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ReceivableNft} from "./ReceivableNFT.sol";
import {USDC} from "./usdc.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/*
     * @title ReceivableVault
     * @author Nihar Dangi
     *
     * The system is designed to be as minimal as possible. 
     * It has been assumed that the receivable amount will be in our mock USDC value.
     *     
     * Typical flow:
     * 1. Lender deposits assets into the vault, hoping to earn yield.
     * 2. Borrower deposits receivable NFT into the vault and gets assets in USDC minus borrowing fee.
     * 3. Payment processor (i.e the issuer in receivable) is responsible to mark the receivable as paid when the payment has been settled.
     * 4. When the receivable is paid, the borrower can withdraw the NFT from the vault.
     * 5. Lender can withdraw their assets plus yield at anytime from the vault.
     *
     * @notice This contract is the core of the Receivable Vault system. It handles all the logic
     * for depositing and withdrawing Receivable NFTs, as well as depositing and withdrawing assets.
*/
contract ReceivableVault is ERC4626, IERC721Receiver {
    ////////////////
    ///  Events  ///
    ////////////////
    event ReceivableDeposited(uint256 tokenId, uint256 amount, address depositor);
    event ReceivableMarkedAsPaid(uint256 tokenId, address issuer);
    event ReceivableWithdrawn(uint256 tokenId, address receiver);

    /////////////////////////
    ///  State Variables  ///
    /////////////////////////
    ReceivableNft public immutable nftCollection;
    uint256 liquidAssets;
    uint256 outstandingAssets;
    address usdc;
    uint256 feeBasisPoints;
    mapping(uint256 => address) public receivableDepositor;

    ////////////////////
    ///  Functions  ///
    ///////////////////
    constructor(ERC20 asset, address _nftCollection, uint256 _feeBasisPoints) ERC4626(asset, "vaultUSDC", "vUSDC") {
        usdc = address(asset);
        nftCollection = ReceivableNft(_nftCollection);
        feeBasisPoints = _feeBasisPoints;
    }

    /////////////////////////////////////
    ///  External & Public Functions  ///
    /////////////////////////////////////
    /*
     * @param assets: The amount of the underlying asset to deposit
     * @param receiver: The address that will receive the minted shares
     * @notice This function will deposit your assets and mint your shares in the vault.
     */
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        // calling the deposit function ERC-4626 library to perform all the functionality
        shares = super.deposit(assets, receiver);
        liquidAssets += assets;
    }

    /*
     * @param tokenId: The ID of the receivable NFT to deposit
     * @notice This function will deposit your receivable NFT and transfer USDC minus fee to the depositor.
     */
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
        outstandingAssets += amount;
        emit ReceivableDeposited(tokenId, amount, msg.sender);
    }

    /*
     * @param tokenId: The ID of the receivable NFT that is being marked as paid
     * @notice This function will mark the receivable NFT as paid. 
     * Only the issuer of the receivable can call this function.     
     * Vault calls the markAsPaid function in the ReceivableNFT contract.
     * Vault updates its accounting to reflect the payment received.        
     */
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

    /*
     * @param shares: The amount of shares to withdraw
     * @param receiver: The address that will receive the deposited assets
     * @notice This function will allow a lender to withdraw their assets plus yield from the vault.
     */
    function withdraw(uint256 shares, address receiver) external {
        uint256 currShares = balanceOf[msg.sender];
        // checks that the deposited amount is greater than zero.
        require(shares > 0, "withdraw must be greater than zero");
        // Checks that the _receiver address is not zero.
        require(receiver != address(0), "Zero Address");
        // checks that the caller is a shareholder
        require(currShares > 0, "Not a shareHolder");
        // checks that the caller has more shares than they are trying to withdraw.
        require(currShares >= shares, "Not enough shares");
        uint256 assets = previewRedeem(shares);
        // calling the redeem function of ERC-4626 to perform all the functionality
        redeem(shares, receiver, msg.sender);
        liquidAssets -= assets;
    }

    /*
     * @param tokenId: The ID of the receivable NFT to withdraw
     * @param receiver: The address that will receive the withdrawn NFT
     * @notice This function will allow a borrower to withdraw their receivable NFT from the vault once it is marked as paid.
     */
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

    /*
     * @return The total assets in the vault (liquid + outstanding)
     * @notice This function returns the total assets in the vault, which is the sum of liquid assets and outstanding assets.
     */
    function totalAssets() public view override returns (uint256) {
        return liquidAssets + outstandingAssets;
    }

    /*
     * @return The liquid assets in the vault
     * @notice This function returns the liquid assets in the vault.
     */
    function getLiquidAssets() external view returns (uint256) {
        return liquidAssets;
    }

    /*
     * @return The outstanding assets in the vault
     * @notice This function returns the outstanding assets in the vault.
     */
    function getOutstandingAssets() external view returns (uint256) {
        return outstandingAssets;
    }

    /*
     * @notice This function is called whenever an ERC721 token is transferred to this contract via safeTransferFrom.
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.     
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
