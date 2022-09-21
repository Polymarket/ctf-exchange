// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20 as BaseERC20} from "solmate/tokens/ERC20.sol";

/// @dev always has 18 decimals
contract ERC20 is BaseERC20 {
    constructor(string memory _name, string memory _symbol) BaseERC20(_name, _symbol, 18) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
