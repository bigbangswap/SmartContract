// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor(
        uint256 initialSupply
    ) ERC20("USD Tether", "USDT") {
        _mint(msg.sender, initialSupply);
    }
}
