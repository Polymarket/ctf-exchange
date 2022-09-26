// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "exchange/test/BaseExchangeTest.sol";

import { Order, Side, MatchType, OrderStatus } from "exchange/libraries/OrderStructs.sol";

contract MatchOrdersTest is BaseExchangeTest {
    function setUp() public override {
        super.setUp();
        _mintTestTokens(bob, address(exchange), 20_000_000_000);
        _mintTestTokens(carla, address(exchange), 20_000_000_000);
    }

    function testMatchTypeComplementary() public {
        // Init a match with a yes buy against a list of yes sells
        Order memory buy = _createAndSignOrder(bobPK, yes, 60_000_000, 100_000_000, Side.BUY);
        Order memory sellA = _createAndSignOrder(carlaPK, yes, 50_000_000, 25_000_000, Side.SELL);
        Order memory sellB = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order[] memory makerOrders = new Order[](2);
        makerOrders[ 0] = sellA;
        makerOrders[ 1] = sellB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[ 0] = 50_000_000;
        fillAmounts[ 1] = 70_000_000;

        checkpointCollateral(carla);
        checkpointCTF(bob, yes);

        // Check fill events
        // First maker order is filled completely
        vm.expectEmit(true, true, true, false);
        emit OrderFilled(exchange.hashOrder(sellA), carla, bob, yes, 0, 50_000_000, 25_000_000, 0);

        // Second maker order is partially filled
        vm.expectEmit(true, true, true, false);
        emit OrderFilled(exchange.hashOrder(sellB), carla, bob, yes, 0, 70_000_000, 35_000_000, 0);

        // The taker order is filled completely
        vm.expectEmit(true, true, true, false);
        emit OrderFilled(exchange.hashOrder(buy), bob, address(exchange), 0, yes, 60_000_000, 120_000_000, 0);

        vm.expectEmit(true, true, true, false);
        emit OrdersMatched(exchange.hashOrder(buy), bob, 0, yes, 60_000_000, 120_000_000);

        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, 60_000_000, fillAmounts);

        // Ensure balances have been updated post match
        assertCollateralBalance(carla, 60_000_000);
        assertCTFBalance(bob, yes, 120_000_000);

        // Ensure onchain state for orders is as expected
        bytes32 buyHash = exchange.hashOrder(buy);
        assertEq(exchange.getOrderStatus(buyHash).remaining, 0);
        assertTrue(exchange.getOrderStatus(buyHash).isFilledOrCancelled);
    }

    function testMatchTypeMint() public {
        // Init Match with YES buy against a YES sell and a NO buy
        // To match the YES buy with the NO buy, CTF Exchange will MINT new Outcome tokens using it's collateral
        // balance. Then will fill the YES buy and NO buy with the resulting Outcome tokens
        Order memory buy = _createAndSignOrder(bobPK, yes, 60_000_000, 100_000_000, Side.BUY);
        Order memory yesSell = _createAndSignOrder(carlaPK, yes, 50_000_000, 25_000_000, Side.SELL);
        Order memory noBuy = _createAndSignOrder(carlaPK, no, 16_000_000, 40_000_000, Side.BUY);
        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = yesSell;
        makerOrders[1] = noBuy;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000;
        fillAmounts[1] = 16_000_000;

        uint256 takerOrderFillAmount = 49_000_000;

        checkpointCollateral(carla);
        checkpointCTF(bob, yes);
        checkpointCTF(carla, no);

        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);

        // Ensure balances have been updated post match
        assertCTFBalance(bob, yes, 90_000_000);

        assertCollateralBalance(carla, 9_000_000);
        assertCTFBalance(carla, no, 40_000_000);

        // Ensure onchain state for orders is as expected
        // The taker order is partially filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(buy)).remaining, 11_000_000);
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(buy)).isFilledOrCancelled);

        // The maker orders get completely filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(yesSell)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(yesSell)).isFilledOrCancelled);

        assertEq(exchange.getOrderStatus(exchange.hashOrder(noBuy)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(noBuy)).isFilledOrCancelled);
    }

    function testMatchTypeMerge() public {
        // Init Match with YES sell against a NO sell and a Yes buy
        // To match the YES sell with the NO sell, CTF Exchange will MERGE Outcome tokens into collateral
        // Then will fill the YES sell and the NO sell with the resulting collateral
        Order memory yesSell = _createAndSignOrder(bobPK, yes, 100_000_000, 60_000_000, Side.SELL);

        Order memory noSell = _createAndSignOrder(carlaPK, no, 75_000_000, 30_000_000, Side.SELL);

        Order memory yesBuy = _createAndSignOrder(carlaPK, yes, 24_000_000, 40_000_000, Side.BUY);
        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = noSell;
        makerOrders[1] = yesBuy;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 75_000_000;
        fillAmounts[1] = 15_000_000;

        uint256 takerOrderFillAmount = 100_000_000;

        checkpointCollateral(bob);

        checkpointCTF(carla, yes);
        checkpointCollateral(carla);

        vm.prank(admin);
        exchange.matchOrders(yesSell, makerOrders, takerOrderFillAmount, fillAmounts);

        // Ensure balances have been updated post match
        assertCollateralBalance(bob, 60_000_000);

        assertCTFBalance(carla, yes, 25_000_000);
        assertCollateralBalance(carla, 15_000_000);

        // Ensure onchain state for orders is as expected
        // The taker order is fully filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(yesSell)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(yesSell)).isFilledOrCancelled);

        // The first maker order gets completely filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(noSell)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(noSell)).isFilledOrCancelled);

        // The second maker order is partially filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(yesBuy)).remaining, 9_000_000);
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(yesBuy)).isFilledOrCancelled);
    }

    function testMatchTypeComplementaryFuzz(uint128 fillAmount, uint16 takerFeeRateBps, uint16 makerFeeRateBps)
        public
    {
        uint256 makerAmount = 50_000_000;
        uint256 takerAmount = 100_000_000;

        vm.assume(
            fillAmount <= makerAmount && takerFeeRateBps < exchange.getMaxFeeRate()
                && makerFeeRateBps < exchange.getMaxFeeRate()
        );

        // Init a match with a yes buy against a yes sell
        Order memory buy = _createAndSignOrderWithFee(bobPK, yes, makerAmount, takerAmount, takerFeeRateBps, Side.BUY);
        Order memory sell =
            _createAndSignOrderWithFee(carlaPK, yes, takerAmount, makerAmount, makerFeeRateBps, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        uint256 makerFillAmount = _getTakingAmount(fillAmount, makerAmount, takerAmount);
        fillAmounts[0] = makerFillAmount;

        checkpointCollateral(carla);
        checkpointCTF(bob, yes);

        uint256 makerFee = calculateFee(makerFeeRateBps, makerFillAmount, sell.makerAmount, sell.takerAmount, sell.side);
        if (makerFee > 0) {
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, 0, makerFee);
        }

        uint256 takerFee = calculateFee(takerFeeRateBps, fillAmount, fillAmount, makerFillAmount, buy.side);
        if (takerFee > 0) {
            // TakerFee could be >= expected taker fee due to surplus
            vm.expectEmit(true, true, false, false);
            emit FeeCharged(admin, buy.tokenId, takerFee);
        }

        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, fillAmount, fillAmounts);

        // Ensure balances have been updated post match
        assertCollateralBalance(carla, fillAmount - makerFee);
        assertGe(getCTFBalance(bob, yes), makerFillAmount);
    }

    function testMatchTypeMintFuzz(uint128 fillAmount, uint16 takerFeeRateBps, uint16 makerFeeRateBps) public {
        uint256 makerAmount = 50_000_000;
        uint256 takerAmount = 100_000_000;

        vm.assume(
            fillAmount <= makerAmount && takerFeeRateBps < exchange.getMaxFeeRate()
                && makerFeeRateBps < exchange.getMaxFeeRate()
        );

        // Init a match with a YES buy against a NO buy
        Order memory yesBuy =
            _createAndSignOrderWithFee(bobPK, yes, makerAmount, takerAmount, takerFeeRateBps, Side.BUY);

        Order memory noBuy =
            _createAndSignOrderWithFee(carlaPK, no, makerAmount, takerAmount, makerFeeRateBps, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noBuy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = fillAmount;

        uint256 taking = _getTakingAmount(fillAmount, makerAmount, takerAmount);

        uint256 makerFee = calculateFee(makerFeeRateBps, taking, noBuy.makerAmount, noBuy.takerAmount, noBuy.side);
        if (makerFee > 0) {
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, yes, makerFee);
        }

        uint256 takerFee = calculateFee(takerFeeRateBps, taking, fillAmount, taking, yesBuy.side);
        if (takerFee > 0) {
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, no, takerFee);
        }

        checkpointCTF(carla, no);
        checkpointCTF(bob, yes);

        vm.prank(admin);
        exchange.matchOrders(yesBuy, makerOrders, fillAmount, fillAmounts);

        // Ensure balances have been updated post match
        assertCTFBalance(carla, no, taking - makerFee);
        assertCTFBalance(bob, yes, taking - takerFee);
    }

    function testMatchTypeMergeFuzz(uint128 fillAmount, uint16 takerFeeRateBps, uint16 makerFeeRateBps) public {
        uint256 makerAmount = 100_000_000;
        uint256 takerAmount = 50_000_000;

        vm.assume(
            fillAmount <= makerAmount && takerFeeRateBps < exchange.getMaxFeeRate()
                && makerFeeRateBps < exchange.getMaxFeeRate()
        );

        // Init a match with a YES sell against a NO sell
        Order memory yesSell =
            _createAndSignOrderWithFee(bobPK, yes, makerAmount, takerAmount, takerFeeRateBps, Side.SELL);

        Order memory noSell =
            _createAndSignOrderWithFee(carlaPK, no, makerAmount, takerAmount, makerFeeRateBps, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = fillAmount;
        uint256 taking = _getTakingAmount(fillAmount, makerAmount, takerAmount);

        uint256 makerFee =
            calculateFee(makerFeeRateBps, fillAmount, noSell.makerAmount, noSell.takerAmount, noSell.side);
        if (makerFee > 0) {
            vm.expectEmit(true, true, true, true);
            emit FeeCharged(admin, 0, makerFee);
        }

        uint256 takerFee = calculateFee(takerFeeRateBps, fillAmount, fillAmount, taking, yesSell.side);
        if (takerFee > 0) {
            // TakerFee could be >= expected taker fee due to surplus
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, 0, takerFee);
        }

        checkpointCollateral(carla);
        checkpointCollateral(bob);

        vm.prank(admin);
        exchange.matchOrders(yesSell, makerOrders, fillAmount, fillAmounts);

        // Ensure balances have been updated post match
        assertCollateralBalance(carla, taking - makerFee);
        assertGe(usdc.balanceOf(bob), taking - takerFee);
    }

    function testTakerRefund() public {
        // Init match with takerFillAmount >> amount needed to fill the maker orders
        // The excess tokens should be refunded to the taker
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order memory sell = _createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        // If fill amount is miscalculated, refund the caller any leftover tokens
        // In this test, 40 USDC is needed to fill the sell.
        // The Exchange will refund the taker order maker 10 USDC
        uint256 takerFillAmount = 50_000_000;
        uint256 expectedRefund = 10_000_000;

        vm.expectEmit(true, true, true, false);
        // Assert the refund transfer to the taker order maker
        emit Transfer(address(exchange), bob, expectedRefund);

        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerFillAmount, fillAmounts);
    }

    function testWithFees() public {
        vm.startPrank(admin);

        // Init a yes BUY taker order at 50c with a 10% taker fee
        uint256 takerFeeRate = 1000;
        Order memory buy = _createAndSignOrderWithFee(
            bobPK,
            yes,
            50_000_000,
            100_000_000,
            takerFeeRate, // Taker fee of 10%
            Side.BUY
        );

        // Init a yes SELL order at 50c with a 1% maker fee
        uint256 makerFeeRate = 100;
        Order memory sell = _createAndSignOrderWithFee(
            carlaPK,
            yes,
            100_000_000,
            50_000_000,
            makerFeeRate, // Maker fee of 1%
            Side.SELL
        );

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 25_000_000;
        uint256 expectedTakerFee = calculateFee(takerFeeRate, 50_000_000, buy.makerAmount, buy.takerAmount, buy.side);
        uint256 expectedMakerFee = calculateFee(makerFeeRate, 50_000_000, sell.makerAmount, sell.takerAmount, sell.side);

        if (expectedMakerFee > 0) {
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, yes, expectedMakerFee);
        }

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(sell), carla, bob, yes, 0, 50_000_000, 25_000_000, expectedMakerFee);

        if (expectedMakerFee > 0) {
            vm.expectEmit(true, true, true, false);
            emit FeeCharged(admin, yes, expectedTakerFee);
        }

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(buy), bob, address(exchange), 0, yes, 25_000_000, 50_000_000, expectedTakerFee
        );

        // Match the orders
        exchange.matchOrders(buy, makerOrders, takerFillAmount, fillAmounts);
    }

    function testWithFeesWithSurplus() public {
        vm.startPrank(admin);

        // Init a yes SELL taker order at 50c with a 1% taker fee
        uint256 takerFeeRate = 100;
        Order memory sell = _createAndSignOrderWithFee(
            bobPK,
            yes,
            100_000_000,
            50_000_000,
            takerFeeRate, // Taker fee of 1%
            Side.SELL
        );

        // Init a yes BUY order at 60c with a 0% maker fee
        uint256 makerFeeRate = 0;
        Order memory buy = _createAndSignOrderWithFee(carlaPK, yes, 60_000_000, 100_000_000, makerFeeRate, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = buy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 60_000_000;

        uint256 takerFillAmount = 100_000_000;

        // NOTE: the fee is calculated on the *actual* fill price, vs the price implied by the sell order
        // thus the fee is inclusive of any surplus/price improvements generated
        uint256 expectedTakerFee = calculateFee(takerFeeRate, takerFillAmount, 100_000_000, 60_000_000, sell.side);
        uint256 expectedMakerFee =
            calculateFee(makerFeeRate, takerFillAmount, buy.makerAmount, buy.takerAmount, buy.side);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(buy), carla, bob, 0, yes, 60_000_000, 100_000_000, expectedMakerFee);

        if (expectedTakerFee > 0) {
            vm.expectEmit(true, true, true, true);
            emit FeeCharged(admin, 0, expectedTakerFee);
        }

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(sell), bob, address(exchange), yes, 0, 100_000_000, 60_000_000, expectedTakerFee);

        vm.expectEmit(true, true, true, true);
        emit OrdersMatched(exchange.hashOrder(sell), bob, yes, 0, 100_000_000, 60_000_000);

        // Match the orders
        exchange.matchOrders(sell, makerOrders, takerFillAmount, fillAmounts);
    }

    function testMintWithFees() public {
        vm.startPrank(admin);

        // Init a YES BUY taker order at 50c with a 1% taker fee
        uint256 takerFeeRate = 100;
        Order memory buy = _createAndSignOrderWithFee(
            bobPK,
            yes,
            50_000_000,
            100_000_000,
            takerFeeRate, // Taker fee of 1%
            Side.BUY
        );

        // Init a NO BUY order at 50c with a 0.3% maker fee
        uint256 makerFeeRate = 30;
        Order memory noBuy = _createAndSignOrderWithFee(
            carlaPK,
            no,
            50_000_000,
            100_000_000,
            makerFeeRate, // Maker fee of 0.3%
            Side.BUY
        );

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noBuy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;

        uint256 expectedTakerFee = calculateFee(takerFeeRate, 100_000_000, buy.makerAmount, buy.takerAmount, buy.side);
        uint256 expectedMakerFee =
            calculateFee(makerFeeRate, 100_000_000, noBuy.makerAmount, noBuy.takerAmount, noBuy.side);

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(admin, no, expectedMakerFee);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(noBuy), carla, bob, 0, no, 50_000_000, 100_000_000, expectedMakerFee);

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(admin, yes, expectedTakerFee);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(buy), bob, address(exchange), 0, yes, 50_000_000, 100_000_000, expectedTakerFee);

        // Match the orders
        exchange.matchOrders(buy, makerOrders, takerFillAmount, fillAmounts);

        assertCTFBalance(admin, yes, expectedTakerFee);
        assertCTFBalance(admin, no, expectedMakerFee);
    }

    function testMergeWithFees() public {
        vm.startPrank(admin);

        // Init a YES SELL taker order at 50c with a 1% taker fee
        uint256 takerFeeRate = 100;
        Order memory yesSell = _createAndSignOrderWithFee(
            bobPK,
            yes,
            100_000_000,
            50_000_000,
            takerFeeRate, // Taker fee of 1%
            Side.SELL
        );

        // Init a NO SELL order at 50c with a 0.3% maker fee
        uint256 makerFeeRate = 30;
        Order memory noSell = _createAndSignOrderWithFee(
            carlaPK,
            no,
            100_000_000,
            50_000_000,
            makerFeeRate, // Maker fee of 0.3%
            Side.SELL
        );

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;

        uint256 expectedTakerFee =
            calculateFee(takerFeeRate, 100_000_000, yesSell.makerAmount, yesSell.takerAmount, yesSell.side);
        uint256 expectedMakerFee =
            calculateFee(makerFeeRate, 100_000_000, noSell.makerAmount, noSell.takerAmount, noSell.side);

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(admin, 0, expectedMakerFee);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(noSell), carla, bob, no, 0, 100_000_000, 50_000_000, expectedMakerFee);

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(admin, 0, expectedTakerFee);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(exchange.hashOrder(yesSell), bob, address(exchange), yes, 0, 100_000_000, 50_000_000, expectedTakerFee);

        // Match the orders
        exchange.matchOrders(yesSell, makerOrders, takerFillAmount, fillAmounts);
    }

    /*//////////////////////////////////////////////////////////////
                               FAIL CASES
    //////////////////////////////////////////////////////////////*/

    function testNotCrossingSells() public {
        // 60c YES sell
        Order memory yesSell = _createAndSignOrder(bobPK, yes, 100_000_000, 60_000_000, Side.SELL);

        // 60c NO sell
        Order memory noSell = _createAndSignOrder(carlaPK, no, 100_000_000, 60_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerOrderFillAmount = 100_000_000;

        // Sells can only match if priceYesSell + priceNoSell < 1
        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(yesSell, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testNotCrossingBuys() public {
        // 50c YES buy
        Order memory yesBuy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // 40c NO buy
        Order memory noBuy = _createAndSignOrder(carlaPK, no, 40_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noBuy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 40_000_000;

        uint256 takerOrderFillAmount = 50_000_000;

        // Buys can only match if priceYesBuy + priceNoBuy > 1
        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(yesBuy, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testNotCrossingBuyVsSell() public {
        // 50c YES buy
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // 60c YES sell
        Order memory sell = _createAndSignOrder(carlaPK, no, 100_000_000, 60_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 0;

        uint256 takerOrderFillAmount = 0;

        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testInvalidTrade() public {
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory sell = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerOrderFillAmount = 50_000_000;

        // Attempt to match a yes buy with a no sell, reverts as this is invalid
        vm.expectRevert(MismatchedTokenIds.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testMatchNonTaker() public {
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        buy.taker = carla;
        buy.signature = _signMessage(bobPK, exchange.hashOrder(buy));

        // Sell with taker zero
        Order memory sell = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerOrderFillAmount = 50_000_000;

        // Attempt to match orders with admin, incompatible with the taker for the buy order
        // Reverts
        vm.expectRevert(NotTaker.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);

        // Matching with carla suceeds as expected
        vm.expectEmit(true, true, true, true);
        emit OrdersMatched(exchange.hashOrder(buy), bob, 0, yes, 50_000_000, 100_000_000);
        vm.prank(carla);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testMatchZeroTakerAmount() public {
        // Create a non-standard buy order with zero taker amount
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 0, Side.BUY);

        // Any valid sell order will be able to drain the buy order
        // Init a sell order priced absurdly high
        Order memory sell = _createAndSignOrder(carlaPK, yes, 1, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 1;

        uint256 takerOrderFillAmount = 50_000_000;

        vm.expectEmit(true, true, true, true);
        emit OrdersMatched(exchange.hashOrder(buy), bob, 0, yes, 50_000_000, 1);

        // The orders are successfully matched
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);
    }

    function testMatchInvalidFillAmount() public {
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order memory sell = _createAndSignOrder(carlaPK, yes, 1_000_000_000, 500_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 1_000_000_000;

        uint256 takerOrderFillAmount = 500_000_000;

        // Attempt to match the above buy and sell, with fillAmount >>> the maker amount of the buy
        // Reverts
        vm.expectRevert(MakingGtRemaining.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts);
    }
}
