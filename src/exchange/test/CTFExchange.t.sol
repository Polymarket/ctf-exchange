// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "exchange/test/BaseExchangeTest.sol";
import { Order, Side, MatchType, OrderStatus, SignatureType } from "exchange/libraries/OrderStructs.sol";

contract CTFExchangeTest is BaseExchangeTest {
    function testSetup() public {
        assertTrue(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));
        assertFalse(exchange.isAdmin(brian));
        assertFalse(exchange.isOperator(brian));
    }

    function testAuth() public {
        vm.expectEmit(true, true, true, true);
        emit NewAdmin(henry, admin);
        emit NewOperator(henry, admin);

        vm.startPrank(admin);
        exchange.addAdmin(henry);
        exchange.addOperator(henry);
        vm.stopPrank();

        assertTrue(exchange.isOperator(henry));
        assertTrue(exchange.isAdmin(henry));
    }

    function testAuthRemoveAdmin() public {
        vm.expectEmit(true, true, true, true);
        emit RemovedAdmin(henry, admin);
        emit RemovedOperator(henry, admin);

        vm.startPrank(admin);
        exchange.removeAdmin(henry);
        exchange.removeOperator(henry);
        vm.stopPrank();

        assertFalse(exchange.isAdmin(henry));
        assertFalse(exchange.isOperator(henry));
    }

    function testAuthNotAdmin() public {
        vm.expectRevert(NotAdmin.selector);
        exchange.addAdmin(address(1));
    }

    function testAuthRenounce() public {
        // Non admin cannot renounce
        vm.expectRevert(NotAdmin.selector);
        vm.prank(address(12));
        exchange.renounceAdminRole();

        assertTrue(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));

        // Successfully renounces the admin role
        vm.prank(admin);
        exchange.renounceAdminRole();
        assertFalse(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));

        // Successfully renounces the operator role
        vm.prank(admin);
        exchange.renounceOperatorRole();
        assertFalse(exchange.isOperator(admin));
    }

    function testPause() public {
        vm.expectEmit(true, true, true, false);
        emit TradingPaused(admin);

        vm.prank(admin);
        exchange.pauseTrading();

        _mintTestTokens(bob, address(exchange), 1_000_000_000);
        _mintTestTokens(carla, address(exchange), 1_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        vm.expectRevert(Paused.selector);
        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);

        vm.expectEmit(true, true, true, true);
        emit TradingUnpaused(admin);

        vm.prank(admin);
        exchange.unpauseTrading();

        // Order can be filled after unpausing
        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);
        emit OrderFilled(exchange.hashOrder(order), bob, carla, 0, yes, 50_000_000, 100_000_000, 0);
    }

    function testRegisterToken(uint256 _token0, uint256 _token1, uint256 _conditionId) public {
        vm.assume(
            _token0 != yes && _token0 != no && _token1 != yes && _token1 != no && _token1 != _token0 && _token0 > 0
                && _token1 > 0
        );
        bytes32 tokenConditionId = bytes32(_conditionId);

        vm.expectEmit(true, true, true, false);
        emit TokenRegistered(_token0, _token1, tokenConditionId);
        emit TokenRegistered(_token1, _token0, tokenConditionId);
        vm.prank(admin);
        exchange.registerToken(_token0, _token1, tokenConditionId);

        assertEq(exchange.getComplement(_token0), _token1);
        assertEq(exchange.getComplement(_token1), _token0);
        assertEq(exchange.getConditionId(_token0), tokenConditionId);
    }

    function testRegisterTokenRevertCases() public {
        vm.startPrank(admin);
        vm.expectRevert(InvalidTokenId.selector);
        exchange.registerToken(0, 0, bytes32(0));

        vm.expectRevert(AlreadyRegistered.selector);
        exchange.registerToken(no, yes, bytes32(0));
    }

    function testHashOrder() public {
        Order memory order = _createOrder(bob, 1, 50_000_000, 100_000_000, Side.BUY);

        bytes32 expectedHash = 0xea9d5909ecf95a08c9906dc3cfafa62ca6b505f5e1c37c33e0d01099c0565c8f;

        assertEq(exchange.hashOrder(order), expectedHash);
    }

    function testValidate() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        exchange.validateOrder(order);
    }

    function testValidateInvalidSig() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);

        // Incorrect signature(note: signed by carla)
        order.signature = _signMessage(carlaPK, exchange.hashOrder(order));
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function testValidateInvalidSigLength() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        order.signature = hex"";
        vm.expectRevert("ECDSA: invalid signature length");
        exchange.validateOrder(order);
    }

    function testValidateInvalidNonce() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        vm.prank(bob);
        exchange.incrementNonce();
        vm.expectRevert(InvalidNonce.selector);
        exchange.validateOrder(order);

        order.nonce = 1;
        order.signature = _signMessage(bobPK, exchange.hashOrder(order));
        exchange.validateOrder(order);
    }

    function testValidateInvalidSignerMaker() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // For EOA signature type, signer and maker MUST be the same
        order.maker = carla;
        order.signatureType = SignatureType.EOA;
        order.signature = _signMessage(bobPK, exchange.hashOrder(order));

        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function testValidateInvalidExpiration() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        vm.warp(block.timestamp + 1000);
        order.expiration = 50;
        vm.expectRevert(OrderExpired.selector);
        exchange.validateOrder(order);
    }

    function testValidateDuplicateOrder() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        _mintTestTokens(bob, address(exchange), 1_000_000_000);
        _mintTestTokens(carla, address(exchange), 1_000_000_000);
        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);

        // attempting to fill this order again reverts
        vm.expectRevert(OrderFilledOrCancelled.selector);
        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);
    }

    function testValidateFeeTooHigh() public {
        Order memory order = _createAndSignOrderWithFee(
            bobPK,
            yes,
            50_000_000,
            100_000_000,
            10000, // Fee of 100%
            Side.BUY
        );

        vm.expectRevert(FeeTooHigh.selector);
        exchange.validateOrder(order);
    }

    function testFillOrder() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        bytes32 orderHash = exchange.hashOrder(order);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(orderHash, bob, carla, 0, yes, 25_000_000, 50_000_000, 0);

        // Checkpoint USDC balance for carla and Outcome token balance for bob
        checkpointCollateral(carla);
        checkpointCTF(bob, yes);

        // Partially fill the order with carla
        vm.prank(carla);
        exchange.fillOrder(order, 25_000_000);

        // Check balances post fill
        assertCollateralBalance(carla, 25_000_000);
        assertCTFBalance(bob, yes, 50_000_000);

        // Ensure the order status is as expected
        OrderStatus memory status = exchange.getOrderStatus(orderHash);
        assertEq(status.remaining, 25_000_000);
        assertFalse(status.isFilledOrCancelled);
    }

    function testFillOrderPartial() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        bytes32 orderHash = exchange.hashOrder(order);

        // Partially fill the order with carla
        vm.startPrank(carla);
        exchange.fillOrder(order, 25_000_000);

        // Fill the order again
        exchange.fillOrder(order, 25_000_000);

        // Ensure the order status is as expected
        OrderStatus memory status = exchange.getOrderStatus(orderHash);
        assertEq(status.remaining, 0);
        assertTrue(status.isFilledOrCancelled);
    }

    function testFillOrderWithFees() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrderWithFee(
            bobPK,
            yes,
            50_000_000,
            100_000_000,
            100, // 1% or 100 bips
            Side.BUY
        );
        bytes32 orderHash = exchange.hashOrder(order);

        // Fees are charged on order proceeds, in this case Outcome tokens
        uint256 expectedFee = calculateFee(100, 50_000_000, order.makerAmount, order.takerAmount, order.side);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(orderHash, bob, carla, 0, yes, 25_000_000, 50_000_000, expectedFee);

        vm.prank(carla);
        exchange.fillOrder(order, 25_000_000);

        // Ensure the order status is as expected
        OrderStatus memory status = exchange.getOrderStatus(orderHash);
        assertEq(status.remaining, 25_000_000);
        assertFalse(status.isFilledOrCancelled);
    }

    function testFuzzFillOrderWithFees(uint128 fillAmount, uint16 feeRateBps) public {
        uint256 makerAmount = 50_000_000;
        uint256 takerAmount = 100_000_000;

        vm.assume(fillAmount <= makerAmount && feeRateBps < exchange.getMaxFeeRate());

        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrderWithFee(bobPK, yes, makerAmount, takerAmount, feeRateBps, Side.BUY);
        bytes32 orderHash = exchange.hashOrder(order);

        uint256 remaining = makerAmount - fillAmount;
        uint256 taking = fillAmount * order.takerAmount / order.makerAmount;
        uint256 expectedFee = calculateFee(feeRateBps, taking, order.makerAmount, order.takerAmount, order.side);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(orderHash, bob, carla, 0, yes, fillAmount, taking, expectedFee);

        checkpointCTF(bob, yes);
        checkpointCollateral(carla);

        vm.prank(carla);
        exchange.fillOrder(order, fillAmount);

        // Ensure the order status is as expected
        OrderStatus memory status = exchange.getOrderStatus(orderHash);
        assertEq(status.remaining, remaining);

        // Assert the token transfers from the order maker to the filler
        assertCTFBalance(bob, yes, taking - expectedFee);
        assertCollateralBalance(carla, fillAmount);
    }

    function testFillOrderNonTaker() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);
        _mintTestTokens(admin, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        order.taker = carla;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(bobPK, orderHash);

        // A non taker operator attempting to fill the order will revert
        vm.expectRevert(NotTaker.selector);
        vm.prank(admin);
        exchange.fillOrder(order, 50_000_000);

        // The taker specified operator will successfully fill the order
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(order), bob, carla, 0, yes, 50_000_000, 100_000_000, 0);

        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);
    }

    function testFillOrders() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order[] memory orders = new Order[](3);
        uint256[] memory amounts = new uint256[](3);

        Order memory yesBuy = _createAndSignOrderWithFee(
            bobPK,
            yes,
            50_000_000,
            100_000_000,
            100, // 1% or 100 bips
            Side.BUY
        );

        Order memory noBuy = _createAndSignOrderWithFee(
            bobPK,
            no,
            50_000_000,
            100_000_000,
            100, // 1% or 100 bips
            Side.BUY
        );

        Order memory yesSell = _createAndSignOrderWithFee(
            bobPK,
            yes,
            100_000_000,
            60_000_000,
            100, // 1% or 100 bips
            Side.SELL
        );

        orders[0] = yesBuy;
        orders[1] = noBuy;
        orders[2] = yesSell;

        amounts[0] = 50_000_000;
        amounts[1] = 50_000_000;
        amounts[2] = 100_000_000;

        uint256 expectedFeeYesBuy = calculateFee(100, 100_000_000, yesBuy.makerAmount, yesBuy.takerAmount, yesBuy.side);
        uint256 expectedFeeNoBuy = calculateFee(100, 100_000_000, noBuy.makerAmount, noBuy.takerAmount, noBuy.side);
        uint256 expectedFeeYesSell =
            calculateFee(100, 100_000_000, yesSell.makerAmount, yesSell.takerAmount, yesSell.side);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(yesBuy), bob, carla, 0, yes, 50_000_000, 100_000_000, expectedFeeYesBuy);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(noBuy), bob, carla, 0, no, 50_000_000, 100_000_000, expectedFeeNoBuy);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(yesSell), bob, carla, yes, 0, 100_000_000, 60_000_000, expectedFeeYesSell);

        vm.prank(carla);
        exchange.fillOrders(orders, amounts);
    }

    function testFillOrderZeroMakerAmount() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        // Create a non-standard order with 0 maker amount
        Order memory order = _createAndSignOrder(bobPK, yes, 0, 100_000_000, Side.BUY);

        // Reverts since the order does not allocate any tokens to be sold, i.e zero maker amount
        vm.expectRevert(MakingGtRemaining.selector);
        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);
    }

    function testFillOrderZeroTakerAmount() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        // Create a non-standard order with 0 taker amount
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 0, Side.BUY);

        // As such, the order can be successfully filled with *nothing*.
        // Note: it is up to the user to provide sensible maker and taker amounts
        // See the below CTF ERC1155 transfer event:
        // Transferring 0 YES tokens from carla in return for all of the USDC in the order
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(exchange), carla, bob, yes, 0);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(order), bob, carla, 0, yes, 50_000_000, 0, 0);

        uint256 fillAmount = 50_000_000;
        vm.prank(carla);
        exchange.fillOrder(order, fillAmount);
    }

    function testFillOrderMaliciousOperator() public {
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // A malicious operator could attempt to pull tokens available in the order maker's wallet
        // Exchange will protect against this and revert
        uint256 fillAmount = usdc.balanceOf(bob);

        vm.expectRevert(MakingGtRemaining.selector);
        vm.prank(carla);
        exchange.fillOrder(order, fillAmount);
    }

    function testCancelOrder(uint256 makerAmount, uint256 takerAmount, uint256 tokenId) public {
        vm.assume(tokenId > 0);

        Order memory order = _createAndSignOrder(bobPK, tokenId, makerAmount, takerAmount, Side.BUY);
        bytes32 orderHash = exchange.hashOrder(order);

        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(orderHash);
        vm.prank(bob);
        exchange.cancelOrder(order);
    }

    function testCancelOrders(uint256 makerAmount, uint256 takerAmount, uint256 tokenId) public {
        vm.assume(tokenId > 0);

        Order memory o1 = _createAndSignOrder(bobPK, tokenId, makerAmount, takerAmount, Side.BUY);
        bytes32 o1Hash = exchange.hashOrder(o1);

        Order memory o2 = _createAndSignOrder(bobPK, tokenId, makerAmount, takerAmount, Side.SELL);
        bytes32 o2Hash = exchange.hashOrder(o2);

        Order[] memory orders = new Order[](2);
        orders[0] = o1;
        orders[1] = o2;

        vm.expectEmit(true, true, true, true);
        emit OrderCancelled(o1Hash);
        emit OrderCancelled(o2Hash);

        vm.prank(bob);
        exchange.cancelOrders(orders);
    }

    function testCancelOrderNotOwner() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        vm.expectRevert(NotOwner.selector);
        vm.prank(carla);
        exchange.cancelOrder(order);
    }

    function testCancelOrderOrderFilledOrCancelled() public {
        _mintTestTokens(bob, address(exchange), 1_000_000_000);
        _mintTestTokens(carla, address(exchange), 1_000_000_000);

        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        vm.prank(carla);
        exchange.fillOrder(order, 50_000_000);

        vm.expectRevert(OrderFilledOrCancelled.selector);
        vm.prank(bob);
        exchange.cancelOrder(order);
    }

    function testCancelOrderNonExistent() public {
        Order memory order = _createAndSignOrder(bobPK, 1, 50_000_000, 100_000_000, Side.BUY);

        // Cancelling a new order is valid, the order will now be unfillable
        vm.prank(bob);
        exchange.cancelOrder(order);

        OrderStatus memory status = exchange.getOrderStatus(exchange.hashOrder(order));
        assertTrue(status.isFilledOrCancelled);
        assertEq(status.remaining, 0);

        vm.expectRevert(OrderFilledOrCancelled.selector);
        vm.prank(bob);
        exchange.cancelOrder(order);
    }

    function testCalculateFeeBuy() public {
        uint256 feeRateBps = 100; // 1%
        uint256 proceeds;
        uint256 expectedFee;
        uint256 actualFee;
        Order memory order;

        order = _createOrder(bob, yes, 40_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 1000000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 20_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 1000000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 60_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 666666;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 80_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 250000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 99_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 10101;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 1_000_000, 100_000_000, Side.BUY);
        proceeds = 100_000_000;
        expectedFee = 1_000_000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 500_000_000, Side.BUY);
        proceeds = 500_000_000;
        expectedFee = 5_000_000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 1_000, 2_000, Side.BUY);
        proceeds = 2_000;
        expectedFee = 20;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);
    }

    function testCalculateFeeSell() public {
        uint256 feeRateBps = 100; // 1%
        uint256 proceeds = 100_000_000;
        uint256 expectedFee;
        uint256 actualFee;
        Order memory order;

        order = _createOrder(bob, yes, 100_000_000, 40_000_000, Side.SELL);
        proceeds = 100_000_000;
        expectedFee = 400000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 20_000_000, Side.SELL);
        expectedFee = 200000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 60_000_000, Side.SELL);
        expectedFee = 400000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 80_000_000, Side.SELL);
        expectedFee = 200000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 99_000_000, Side.SELL);
        expectedFee = 10000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 100_000_000, 1_000_000, Side.SELL);
        expectedFee = 10000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 500_000_000, 100_000_000, Side.SELL);
        proceeds = 500_000_000;
        expectedFee = 1_000_000;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);

        order = _createOrder(bob, yes, 2_000, 1_000, Side.SELL);
        proceeds = 2_000;
        expectedFee = 10;
        actualFee = calculateFee(feeRateBps, proceeds, order.makerAmount, order.takerAmount, order.side);
        assertEq(actualFee, expectedFee);
    }

    function testFuzzCalculateFee(uint128 fillAmount, uint16 feeRateBps, uint128 makerAmount, uint128 takerAmount)
        public
    {
        vm.assume(
            makerAmount > 0 && takerAmount > makerAmount && fillAmount <= makerAmount
                && feeRateBps < exchange.getMaxFeeRate()
        );

        uint256 expectedProceeds = _getTakingAmount(fillAmount, makerAmount, takerAmount);
        calculateFee(feeRateBps, expectedProceeds, makerAmount, takerAmount, Side.BUY);
        calculateFee(feeRateBps, expectedProceeds, takerAmount, makerAmount, Side.SELL);
    }

    function testCalculateFeeLargePrice() public {
        // Possible for an order to have a price that breaks fee calculation:
        // Implies a price of 100 USD per YES token
        uint256 makerAmount = 1_000_000; // yes tokens
        uint256 takerAmount = 100_000_000; // cash

        Side side = Side.SELL;
        uint256 feeRateBps = 100;
        uint256 outcomeTokens = takerAmount;

        // ignore these orders in fee calculation
        uint256 fee = calculateFee(feeRateBps, outcomeTokens, makerAmount, takerAmount, side);
        assertEq(fee, 0);
    }
}
