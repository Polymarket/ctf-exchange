// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import {OrderStatus, Order} from "../libraries/OrderStructs.sol";

interface ITradingEE {
    error NotOwner();
    error NotTaker();
    error OrderFilledOrCancelled();
    error OrderExpired();
    error InvalidNonce();
    error MakingGtRemaining();
    error NotCrossing();
    error TooLittleTokensReceived();
    error MismatchedTokenIds();

    /// @notice Emitted when an order is cancelled
    event OrderCancelled(bytes32 indexed orderHash);

    /// @notice Emitted when an order is filled
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed filler,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 filled,
        uint256 remaining,
        uint256 fee
    );

    /// @notice Emitted when a set of orders is matched
    event OrdersMatched(
        bytes32 indexed takerOrderHash,
        uint256 indexed makerAssetId,
        uint256 indexed takerAssetId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );
}

interface ITrading is ITradingEE {}
