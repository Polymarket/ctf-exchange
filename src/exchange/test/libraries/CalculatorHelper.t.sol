// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "forge-std/Test.sol";

import { CalculatorHelper } from "exchange/libraries/CalculatorHelper.sol";
import { Side } from "exchange/libraries/OrderStructs.sol";

contract CalculatorHelperTest is Test {
    function testFuzzCalculateTakingAmount(uint64 making, uint128 makerAmount, uint128 takerAmount) public {
        vm.assume(makerAmount > 0 && making <= makerAmount);
        // Explicitly cast to 256 to avoid overflows
        uint256 expected = making * uint256(takerAmount) / uint256(makerAmount);
        assertEq(CalculatorHelper.calculateTakingAmount(making, makerAmount, takerAmount), expected);
    }

    function testFuzzCalculatePrice(uint128 makerAmount, uint128 takerAmount, uint8 sideInt) public {
        vm.assume(sideInt <= 1);
        Side side = Side(sideInt);
        // Asserts not needed, test checks that we can calculate price safely without unexpected reverts

        CalculatorHelper._calculatePrice(makerAmount, takerAmount, side);
    }

    function testFuzzIsCrossing(
        uint128 makerAmountA,
        uint128 takerAmountA,
        uint8 sideIntA,
        uint128 makerAmountB,
        uint128 takerAmountB,
        uint8 sideIntB
    ) public {
        vm.assume(sideIntA <= 1 && sideIntB <= 1);
        Side sideA = Side(sideIntA);
        Side sideB = Side(sideIntB);
        uint256 priceA = CalculatorHelper._calculatePrice(makerAmountA, takerAmountA, sideA);
        uint256 priceB = CalculatorHelper._calculatePrice(makerAmountB, takerAmountB, sideB);

        // Asserts not needed, test checks that we can check isCrossing safely without unexpected reverts
        CalculatorHelper._isCrossing(priceA, priceB, sideA, sideB);
    }
}
