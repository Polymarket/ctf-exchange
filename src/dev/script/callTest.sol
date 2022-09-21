// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2 as console} from "forge-std/Script.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract call_test is Script {
    // returns true
    function run(address _callee) public returns (bool) {
        address from = address(1);
        address to = address(2);
        uint256 value = 1;
        (bool success,) = _callee.call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value));
        return (success);
    }

    // returns false
    function run() public returns (bool) {
        address token = address(new ERC20("", ""));
        address from = address(1);
        address to = address(2);
        uint256 value = 1;
        (bool success,) = token.call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, value));
        return (success);
    }
}
