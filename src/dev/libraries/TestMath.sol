// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library TestMath {
    // these binary operators implicitly cast smaller uints
    // into uint256 before the operatiuon
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return _x * _y;
    }

    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return _x + _y;
    }
}
