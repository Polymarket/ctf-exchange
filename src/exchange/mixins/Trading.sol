// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";
import { IHashing } from "../interfaces/IHashing.sol";
import { ITrading } from "../interfaces/ITrading.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { ISignatures } from "../interfaces/ISignatures.sol";
import { INonceManager } from "../interfaces/INonceManager.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";

import { CalculatorHelper } from "../libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus } from "../libraries/OrderStructs.sol";

/// @title Trading
/// @notice Implements logic for trading CTF assets
abstract contract Trading is IFees, ITrading, IHashing, IRegistry, ISignatures, INonceManager, IAssetOperations {
    /// @notice Mapping of orders to their current status
    mapping(bytes32 => OrderStatus) public orderStatus;

    /// @notice Gets the status of an order
    /// @param orderHash    - The hash of the order
    function getOrderStatus(bytes32 orderHash) public view returns (OrderStatus memory) {
        return orderStatus[ orderHash];
    }

    /// @notice Validates an order
    /// @notice order - The order to be validated
    function validateOrder(Order memory order) public view {
        bytes32 orderHash = hashOrder(order);
        _validateOrder(orderHash, order);
    }

    /// @notice Cancels an order
    /// An order can only be cancelled by its maker, the address which holds funds for the order
    /// @notice order - The order to be cancelled
    function cancelOrder(Order memory order) external {
        _cancelOrder(order);
    }

    /// @notice Cancels a set of orders
    /// @notice orders - The set of orders to be cancelled
    function cancelOrders(Order[] memory orders) external {
        uint256 length = orders.length;
        uint256 i = 0;
        for (; i < length;) {
            _cancelOrder(orders[ i]);
            unchecked {
                ++i;
            }
        }
    }

    function _cancelOrder(Order memory order) internal {
        if (order.maker != msg.sender) revert NotOwner();

        bytes32 orderHash = hashOrder(order);
        OrderStatus storage status = orderStatus[orderHash];
        if (status.isFilledOrCancelled) revert OrderFilledOrCancelled();

        status.isFilledOrCancelled = true;
        emit OrderCancelled(orderHash);
    }

    function _validateOrder(bytes32 orderHash, Order memory order) internal view {
        // Validate order expiration
        if (order.expiration > 0 && order.expiration < block.timestamp) revert OrderExpired();

        // Validate signature
        validateOrderSignature(orderHash, order);

        // Validate fee
        if (order.feeRateBps > getMaxFeeRate()) revert FeeTooHigh();

        // Validate the token to be traded
        validateTokenId(order.tokenId);

        // Validate that the order can be filled
        if (orderStatus[orderHash].isFilledOrCancelled) revert OrderFilledOrCancelled();

        // Validate nonce
        if (!isValidNonce(order.maker, order.nonce)) revert InvalidNonce();
    }

    /// @notice Fills an order against the caller
    /// @param order        - The order to be filled
    /// @param fillAmount   - The amount to be filled, always in terms of the maker amount
    /// @param to           - The address to receive assets from filling the order
    function _fillOrder(Order memory order, uint256 fillAmount, address to) internal {
        uint256 making = fillAmount;
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(order, making);

        uint256 fee = CalculatorHelper.calculateFee(
            order.feeRateBps, order.side == Side.BUY ? taking : making, order.makerAmount, order.takerAmount, order.side
        );

        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(order);

        // Transfer order proceeds minus fees from msg.sender to order maker
        _transfer(msg.sender, order.maker, takerAssetId, taking - fee);

        // Transfer makingAmount from order maker to `to`
        _transfer(order.maker, to, makerAssetId, making);

        // NOTE: Fees are "collected" by the Operator implicitly,
        // since the fee is deducted from the assets paid by the Operator

        emit OrderFilled(orderHash, order.maker, msg.sender, makerAssetId, takerAssetId, making, taking, fee);
    }

    /// @notice Fills a set of orders against the caller
    /// @param orders       - The order to be filled
    /// @param fillAmounts  - The amounts to be filled, always in terms of the maker amount
    /// @param to           - The address to receive assets from filling the order
    function _fillOrders(Order[] memory orders, uint256[] memory fillAmounts, address to) internal {
        uint256 length = orders.length;
        uint256 i = 0;
        for (; i < length;) {
            _fillOrder(orders[i], fillAmounts[i], to);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Matches orders against each other
    /// Matches a taker order against a list of maker orders
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of passive orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, in terms of the maker amount
    function _matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) internal {
        uint256 making = takerFillAmount;

        (uint256 taking, bytes32 orderHash) = _performOrderChecks(takerOrder, making);
        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(takerOrder);

        // Transfer takerOrder making amount from taker order to the Exchange
        _transfer(takerOrder.maker, address(this), makerAssetId, making);

        // Fill the maker orders
        _fillMakerOrders(takerOrder, makerOrders, makerFillAmounts);

        taking = _updateTakingWithSurplus(taking, takerAssetId);
        uint256 fee = CalculatorHelper.calculateFee(
            takerOrder.feeRateBps, takerOrder.side == Side.BUY ? taking : making, making, taking, takerOrder.side
        );

        // Execute transfers

        // Transfer order proceeds post fees from the Exchange to the taker order maker
        _transfer(address(this), takerOrder.maker, takerAssetId, taking - fee);

        // Charge the fee to taker order maker, explicitly transferring the fee from the Exchange to the Operator
        _chargeFee(address(this), msg.sender, takerAssetId, fee);

        // Refund any leftover tokens pulled from the taker to the taker order
        uint256 refund = _getBalance(makerAssetId);
        if (refund > 0) _transfer(address(this), takerOrder.maker, makerAssetId, refund);

        emit OrderFilled(
            orderHash, takerOrder.maker, address(this), makerAssetId, takerAssetId, making, taking, fee
        );

        emit OrdersMatched(orderHash, takerOrder.maker, makerAssetId, takerAssetId, making, taking);

        
    }

    function _fillMakerOrders(Order memory takerOrder, Order[] memory makerOrders, uint256[] memory makerFillAmounts)
        internal
    {
        uint256 length = makerOrders.length;
        uint256 i = 0;
        for (; i < length;) {
            _fillMakerOrder(takerOrder, makerOrders[i], makerFillAmounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Fills a Maker order
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    /// @param fillAmount   - The fill amount
    function _fillMakerOrder(Order memory takerOrder, Order memory makerOrder, uint256 fillAmount) internal {
        MatchType matchType = _deriveMatchType(takerOrder, makerOrder);

        // Ensure taker order and maker order match
        _validateTakerAndMaker(takerOrder, makerOrder, matchType);

        uint256 making = fillAmount;
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(makerOrder, making);
        uint256 fee = CalculatorHelper.calculateFee(
            makerOrder.feeRateBps,
            makerOrder.side == Side.BUY ? taking : making,
            makerOrder.makerAmount,
            makerOrder.takerAmount,
            makerOrder.side
        );
        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(makerOrder);

        _fillFacingExchange(making, taking, makerOrder.maker, makerAssetId, takerAssetId, matchType, fee);

        emit OrderFilled(
            orderHash, makerOrder.maker, takerOrder.maker, makerAssetId, takerAssetId, making, taking, fee
        );
    }

    /// @notice Performs common order computations and validation
    /// 1) Validates the order taker
    /// 2) Computes the order hash
    /// 3) Validates the order
    /// 4) Computes taking amount
    /// 5) Updates the order status in storage
    /// @param order    - The order being prepared
    /// @param making   - The amount of the order being filled, in terms of maker amount
    function _performOrderChecks(Order memory order, uint256 making)
        internal
        returns (uint256 takingAmount, bytes32 orderHash)
    {
        _validateTaker(order.taker);

        orderHash = hashOrder(order);

        // Validate order
        _validateOrder(orderHash, order);

        // Calculate taking amount
        takingAmount = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);

        // Update the order status in storage
        _updateOrderStatus(orderHash, order, making);
    }

    /// @notice Fills a maker order using the Exchange as the counterparty
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param maker        - The order maker
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    /// @param fee          - The fee charged to the Order maker
    function _fillFacingExchange(
        uint256 makingAmount,
        uint256 takingAmount,
        address maker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        MatchType matchType,
        uint256 fee
    ) internal {
        // Transfer makingAmount tokens from order maker to Exchange
        _transfer(maker, address(this), makerAssetId, makingAmount);

        // Executes a match call based on match type
        _executeMatchCall(makingAmount, takingAmount, makerAssetId, takerAssetId, matchType);

        // Ensure match action generated enough tokens to fill the order
        if (_getBalance(takerAssetId) < takingAmount) revert TooLittleTokensReceived();

        // Transfer order proceeds minus fees from the Exchange to the order maker
        _transfer(address(this), maker, takerAssetId, takingAmount - fee);

        // Transfer fees from Exchange to the Operator
        _chargeFee(address(this), msg.sender, takerAssetId, fee);
    }

    function _deriveMatchType(Order memory takerOrder, Order memory makerOrder) internal pure returns (MatchType) {
        if (takerOrder.side == Side.BUY && makerOrder.side == Side.BUY) return MatchType.MINT;
        if (takerOrder.side == Side.SELL && makerOrder.side == Side.SELL) return MatchType.MERGE;
        return MatchType.COMPLEMENTARY;
    }

    function _deriveAssetIds(Order memory order) internal pure returns (uint256 makerAssetId, uint256 takerAssetId) {
        if (order.side == Side.BUY) return (0, order.tokenId);
        return (order.tokenId, 0);
    }

    /// @notice Executes a CTF call to match orders by minting new Outcome tokens
    /// or merging Outcome tokens into collateral.
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    function _executeMatchCall(
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 makerAssetId,
        uint256 takerAssetId,
        MatchType matchType
    ) internal {
        if (matchType == MatchType.COMPLEMENTARY) {
            // Indicates a buy vs sell order
            // no match action needed
            return;
        }
        if (matchType == MatchType.MINT) {
            // Indicates matching 2 buy orders
            // Mint new Outcome tokens using Exchange collateral balance and fill buys
            return _mint(getConditionId(takerAssetId), takingAmount);
        }
        if (matchType == MatchType.MERGE) {
            // Indicates matching 2 sell orders
            // Merge the Exchange Outcome token balance into collateral and fill sells
            return _merge(getConditionId(makerAssetId), makingAmount);
        }
    }

    /// @notice Ensures the taker and maker orders can be matched against each other
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    function _validateTakerAndMaker(Order memory takerOrder, Order memory makerOrder, MatchType matchType)
        internal
        view
    {
        if (!CalculatorHelper.isCrossing(takerOrder, makerOrder)) revert NotCrossing();

        // Ensure orders match
        if (matchType == MatchType.COMPLEMENTARY) {
            if (takerOrder.tokenId != makerOrder.tokenId) revert MismatchedTokenIds();
        } else {
            // both bids or both asks
            validateComplement(takerOrder.tokenId, makerOrder.tokenId);
        }
    }

    function _validateTaker(address taker) internal view {
        if (taker != address(0) && taker != msg.sender) revert NotTaker();
    }

    function _chargeFee(address payer, address receiver, uint256 tokenId, uint256 fee) internal {
        // Charge fee to the payer if any
        if (fee > 0) {
            _transfer(payer, receiver, tokenId, fee);
            emit FeeCharged(receiver, tokenId, fee);
        }
    }

    function _updateOrderStatus(bytes32 orderHash, Order memory order, uint256 makingAmount)
        internal
        returns (uint256 remaining)
    {
        OrderStatus storage status = orderStatus[orderHash];
        // Fetch remaining amount from storage
        remaining = status.remaining;

        // Update remaining if the order is new/has not been filled
        remaining = remaining == 0 ? order.makerAmount : remaining;

        // Throw if the makingAmount(amount to be filled) is greater than the amount available
        if (makingAmount > remaining) revert MakingGtRemaining();

        // Update remaining using the makingAmount
        remaining = remaining - makingAmount;

        // If order is completely filled, update isFilledOrCancelled in storage
        if (remaining == 0) status.isFilledOrCancelled = true;

        // Update remaining in storage
        status.remaining = remaining;
    }

    function _updateTakingWithSurplus(uint256 minimumAmount, uint256 tokenId) internal returns (uint256) {
        uint256 actualAmount = _getBalance(tokenId);
        if (actualAmount < minimumAmount) revert TooLittleTokensReceived();
        return actualAmount;
    }
}
