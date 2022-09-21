// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";

/// @title pToken Factory contract
interface IInitializable {
    function initialize(bytes memory _data) external;
}

contract Factory {
    address immutable pTokenFactory;
    address immutable implementation;

    constructor(address _pTokenFactory, address _implementation) {
        pTokenFactory = _pTokenFactory;
        implementation = _implementation;
    }

    function deploy(bytes calldata _data) external returns (address) {
        address clone = Clones.cloneDeterministic(implementation, keccak256(abi.encodePacked(msg.sender)));
        IInitializable(clone).initialize(_data);
        return clone;
    }
}
