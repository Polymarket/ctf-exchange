// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { SafeTransferLib, ERC20 } from "common/libraries/SafeTransferLib.sol";

/// @title TransferHelper
/// @notice Helper method to transfer tokens
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @param token    - The contract address of the token which will be transferred
    /// @param to       - The recipient of the transfer
    /// @param amount   - The amount to be transferred
    function _transferERC20(address token, address to, uint256 amount) internal {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param amount   - The amount to be transferred
    function _transferFromERC20(address token, address from, address to, uint256 amount) internal {
        SafeTransferLib.safeTransferFrom(ERC20(token), from, to, amount);
    }

    /// @notice Transfer an ERC1155 token
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param id       - The tokenId of the token to be transferred
    /// @param amount   - The amount to be transferred
    function _transferFromERC1155(address token, address from, address to, uint256 id, uint256 amount) internal {
        IERC1155(token).safeTransferFrom(from, to, id, amount, "");
    }

    /// @notice Transfers a set of ERC1155 tokens
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param ids      - The tokenId of the token to be transferred
    /// @param amounts  - The amount to be transferred
    function _batchTransferFromERC1155(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        IERC1155(token).safeBatchTransferFrom(from, to, ids, amounts, "");
    }
}
