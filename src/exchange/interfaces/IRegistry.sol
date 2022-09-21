// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IRegistryEE {
    error InvalidComplement();
    error InvalidTokenId();
    error AlreadyRegistered();

    /// @notice Emitted when a token is registered
    event TokenRegistered(uint256 indexed token0, uint256 indexed token1, bytes32 indexed conditionId);
}

abstract contract IRegistry is IRegistryEE {
    function getConditionId(uint256 tokenId) public view virtual returns (bytes32);

    function getComplement(uint256 tokenId) public view virtual returns (uint256);

    function validateTokenId(uint256 tokenId) public view virtual;

    function validateComplement(uint256 token0, uint256 token1) public view virtual;
}
