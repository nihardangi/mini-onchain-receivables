// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title ReceivableNft
 * @author Nihar Dangi
 *
 * The Receivable NFT contract represents a receivable as a non-fungible token (NFT).
 * Each NFT contains metadata about the receivable, including the amount, due date, issuer, payer, token uri and payment status.
 * The contract allows for minting new receivable NFTs, marking them as paid, and setting the vault that can manage them.
 *
 * Typical flow:
 * 1. Owner of the contract mints a new receivable NFT to a borrower.
 * 2. The borrower can deposit the NFT into the ReceivableVault to receive funds.
 * 3. The payment processor (issuer) marks the receivable as paid when the payment is settled.
 * 4. The borrower can withdraw the NFT from the vault once it is marked as paid.
 *
 * @notice This contract is designed to be simple and minimal, focusing on core functionality for managing receivable NFTs.
*/
contract ReceivableNft is ERC721, Ownable {
    ////////////////
    ///  Events  ///
    ////////////////
    event ReceivableMinted(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 dueDate,
        address indexed issuer,
        address payer,
        string tokenUri,
        address indexed to
    );

    ///////////////
    ///  Types  ///
    ///////////////
    struct Receivable {
        uint256 amount;
        uint256 dueDate;
        address issuer;
        address payer;
        bool paid;
        string tokenUri;
    }

    /////////////////////////
    ///  State Variables  ///
    /////////////////////////
    uint256 private tokenCounter;
    address public receivableVault;
    mapping(uint256 => Receivable) public tokenIdtoReceivable;

    ////////////////////
    ///  Modifiers  ///
    ///////////////////
    modifier onlyReceivableVault() {
        if (msg.sender != receivableVault) {
            revert("Only Receivable Vault can call this function");
        }
        _;
    }

    ////////////////////
    ///  Functions  ///
    ///////////////////
    constructor() ERC721("Receivables", "RCVBL") Ownable(msg.sender) {
        tokenCounter = 0;
    }

    /////////////////////////////////////
    ///  External & Public Functions  ///
    /////////////////////////////////////
    /**
     * @param amount The amount of the receivable.
     * @param dueDate The due date of the receivable as a Unix timestamp.
     * @param issuer The address of the issuer (payment processor) of the receivable.
     * @param payer The address of the payer of the receivable.
     * @param tokenUri The metadata URI associated with the receivable NFT (will point to the image).
     * @param to The address that will receive the minted NFT.
     * @notice Mints a new receivable NFT to the specified address. This function can only be called by the owner.
     */
    function mintNFT(uint256 amount, uint256 dueDate, address issuer, address payer, string memory tokenUri, address to)
        external
        onlyOwner
    {
        tokenIdtoReceivable[tokenCounter] = Receivable({
            amount: amount,
            dueDate: dueDate,
            issuer: issuer,
            payer: payer,
            paid: false,
            tokenUri: tokenUri
        });
        _safeMint(to, tokenCounter);
        emit ReceivableMinted(tokenCounter, amount, dueDate, issuer, payer, tokenUri, to);
        tokenCounter++;
    }

    /**
     * @param _receivableVault The address of the ReceivableVault contract.
     * @notice Sets the address of the ReceivableVault contract. This function can only be called by the owner.
     */
    function setReceivableVault(address _receivableVault) public onlyOwner {
        receivableVault = _receivableVault;
    }

    /**
     * @param tokenId The ID of the receivable NFT to mark as paid.
     * @notice Marks a receivable NFT as paid. This function can only be called by the ReceivableVault.
     */
    function markAsPaid(uint256 tokenId) external onlyReceivableVault {
        tokenIdtoReceivable[tokenId].paid = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenIdtoReceivable[tokenId].tokenUri;
    }
}
