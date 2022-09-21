// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IOwnable {
    error OnlyOwner();
}

///@notice Ownable with transfer and accept
///@notice We might not use this for anything.
abstract contract Ownable is IOwnable {
    address public owner;
    address public nextOwner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function transferOwnership(address _nextOwner) external onlyOwner {
        nextOwner = _nextOwner;
    }

    function acceptOwnership() external {
        if (msg.sender != nextOwner) revert();
        owner = msg.sender;
    }
}
