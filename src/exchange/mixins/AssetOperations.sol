// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { IAssets } from "../interfaces/IAssets.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

/// @title Asset Operations
/// @notice Operations on the CTF and Collateral assets
abstract contract AssetOperations is IAssetOperations, IAssets {
    bytes32 public constant parentCollectionId = bytes32(0);

    function _getBalance(uint256 tokenId) internal override returns (uint256) {
        if (tokenId == 0) return IERC20(getCollateral()).balanceOf(address(this));
        return IERC1155(getCtf()).balanceOf(address(this), tokenId);
    }

    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferCTF(from, to, id, value);
    }

    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCollateral();
        if (from == address(this)) TransferHelper._transferERC20(token, to, value);
        else TransferHelper._transferFromERC20(token, from, to, value);
    }

    function _transferCTF(address from, address to, uint256 id, uint256 value) internal {
        TransferHelper._transferFromERC1155(getCtf(), from, to, id, value);
    }

    function _mint(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
        IConditionalTokens(getCtf()).splitPosition(
            IERC20(getCollateral()), parentCollectionId, conditionId, partition, amount
        );
    }

    function _merge(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(getCtf()).mergePositions(
            IERC20(getCollateral()), parentCollectionId, conditionId, partition, amount
        );
    }
}
