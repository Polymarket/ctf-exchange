// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console2 as console, stdStorage, StdStorage} from "forge-std/Test.sol";
import {ERC20} from "common/ERC20.sol";
import {TestMath} from "dev/libraries/TestMath.sol";

abstract contract TestHelper is Test {
    using TestMath for uint64;
    using TestMath for uint256;

    mapping(address => mapping(address => uint256)) private balanceCheckpoints;

    address alice = address(1);
    address brian = address(2);
    address carly = address(3);
    address dylan = address(4);
    address erica = address(5);
    address frank = address(6);
    address grace = address(7);
    address henry = address(8);

    constructor() {
        vm.label(alice, "alice");
        vm.label(brian, "brian");
        vm.label(carly, "carly");
        vm.label(dylan, "dylan");
        vm.label(erica, "erica");
        vm.label(frank, "frank");
        vm.label(grace, "grace");
        vm.label(henry, "henry");
    }

    modifier with(address _account) {
        vm.startPrank(_account);
        _;
        vm.stopPrank();
    }

    function hashAddress(bytes memory _digest) internal pure returns (address) {
        return address(uint160(uint256(keccak256(_digest))));
    }

    function assertBalance(address _token, address _who, uint256 _amount) internal {
        assertEq(ERC20(_token).balanceOf(_who), balanceCheckpoints[_token][_who] + _amount);
    }

    function checkpointBalance(address _token, address _who) internal {
        balanceCheckpoints[_token][_who] = ERC20(_token).balanceOf(_who);
    }

    function balanceOf(address _token, address _who) internal view returns (uint256) {
        return ERC20(_token).balanceOf(_who);
    }

    function approve(address _token, address _spender, uint256 _amount) internal {
        ERC20(_token).approve(_spender, _amount);
    }

    ///@dev msg.sender is the owner of the approved tokens
    function dealAndApprove(address _token, address _to, address _spender, uint256 _amount) internal {
        deal(_token, _to, _amount);
        approve(_token, _spender, _amount);
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a + _b;
    }

    function advance(uint256 _delta) internal {
        vm.roll(block.number + _delta);
    }

    function _address(bytes memory _seed) internal pure returns (address) {
        return address(bytes20(keccak256(_seed)));
    }
}
