// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Helper library to compute polymarket proxy wallet addresses
library PolyProxyLib {
    /// @notice Gets the polymarket proxy address for a signer
    /// @param signer - Address of the signer
    function getProxyWalletAddress(address signer, address implementation, address deployer)
        internal
        pure
        returns (address proxyWallet)
    {
        return _computeCreate2Address(deployer, implementation, keccak256(abi.encodePacked(signer)));
    }

    function _computeCreate2Address(address from, address target, bytes32 salt) internal pure returns (address) {
        bytes32 bytecodeHash = keccak256(_computeCreationCode(from, target));
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), from, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }

    function _computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
        bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
        bytes memory buffer = new bytes(99);
        assembly {
            mstore(add(buffer, 0x20), 0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
            mstore(add(buffer, 0x2d), mul(deployer, 0x01000000000000000000000000))
            mstore(add(buffer, 0x41), 0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
            mstore(add(buffer, 0x60), mul(target, 0x01000000000000000000000000))
            mstore(add(buffer, 116), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
        // clone = bytes.concat(buffer, consData);
        clone = abi.encodePacked(buffer, consData);
        return clone;
    }
}
