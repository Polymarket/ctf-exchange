// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

abstract contract INonceManager {
    function incrementNonce() external virtual;

    function isValidNonce(address user, uint256 userNonce) public view virtual returns (bool);
}
