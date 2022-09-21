// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console2 as console} from "forge-std/Test.sol";

// simple demo of ffi with echo
contract ffi is Test {
    function run() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "echo";
        inputs[1] = "-n";
        inputs[2] = "0xcafe";
        // or
        // inputs[2] = 'cafe';

        bytes memory result = vm.ffi(inputs);
        console.logBytes(result);
    }
}
