// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@solmate/tokens/ERC4626.sol";

contract TokenVault is ERC4626 {
    mapping(address => uint256) shareHolders;

    constructor(ERC20 asset) ERC4626(asset, "vaultUSDC", "vUSDC") {}

    function deposit(uint256 assets) public {
        require(assets > 0, "Must deposit more than 0 assets");
        // calling the deposit function ERC-4626 library to perform all the functionality
        super.deposit(assets, msg.sender);
        // Increase the share of the user
        shareHolders[msg.sender] += assets;
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    // returns total balance of user
    function totalAssetsOfUser(address _user) public view returns (uint256) {
        return asset.balanceOf(_user);
    }

    function withdraw(uint256 shares, address receiver) public {
        // checks that the deposited amount is greater than zero.
        require(shares > 0, "withdraw must be greater than Zero");
        // Checks that the _receiver address is not zero.
        require(receiver != address(0), "Zero Address");
        // checks that the caller is a shareholder
        require(shareHolders[msg.sender] > 0, "Not a shareHolder");
        // checks that the caller has more shares than they are trying to withdraw.
        require(shareHolders[msg.sender] >= shares, "Not enough shares");
        // calculate 10% yield on the shares
        // uint256 yield = (shares * 10) / 100;
        // total amount to be withdrawn
        // uint256 totalAssetAmount = shares + yield;
        // calling the redeem function of ERC-4626 to perform all the functionality
        redeem(shares, receiver, msg.sender);
        // Decrease the share of the user
        shareHolders[msg.sender] -= shares;
    }
}
