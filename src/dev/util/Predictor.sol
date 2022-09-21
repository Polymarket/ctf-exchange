// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {vm} from "./vm.sol";
import {Ascii} from "./Ascii.sol";

// modified from https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
library Predictor {
    function addressFrom(address _origin, uint256 _nonce) public pure returns (address) {
        if (_nonce == 0x00) return addressHash(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80)));
        if (_nonce <= 0x7f) {
            return addressHash(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(uint8(_nonce))));
        }
        if (_nonce <= 0xff) {
            return addressHash(abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce)));
        }
        if (_nonce <= 0xffff) {
            return addressHash(abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce)));
        }
        if (_nonce <= 0xffffff) {
            return addressHash(abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce)));
        }
        return addressHash(abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce))); // more than 2^32 nonces not realisti);
    }

    function addressHash(bytes memory _digest) public pure returns (address) {
        return address(uint160(uint256(keccak256(_digest))));
    }
}
