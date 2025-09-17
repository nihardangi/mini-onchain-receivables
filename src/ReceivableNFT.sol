// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ReceivableNft is ERC721, Ownable {
    event ReceivableMinted(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 dueDate,
        address indexed issuer,
        address payer,
        string tokenUri,
        address indexed to
    );

    struct Receivable {
        uint256 amount;
        uint256 dueDate;
        address issuer;
        address payer;
        bool paid;
        string tokenUri;
    }

    uint256 private tokenCounter;
    address public receivableVault;
    mapping(uint256 => Receivable) public tokenIdtoReceivable;

    modifier onlyReceivableVault() {
        if (msg.sender != receivableVault) {
            revert("Only Receivable Vault can call this function");
        }
        _;
    }

    constructor() ERC721("Receivables", "RCVBL") Ownable(msg.sender) {
        tokenCounter = 0;
    }

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

    function setReceivableVault(address _receivableVault) external onlyOwner {
        receivableVault = _receivableVault;
    }

    function markAsPaid(uint256 tokenId) external onlyReceivableVault {
        tokenIdtoReceivable[tokenId].paid = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenIdtoReceivable[tokenId].tokenUri;
    }
}
