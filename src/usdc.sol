// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@solmate/tokens/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC", 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
