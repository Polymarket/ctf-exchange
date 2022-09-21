// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2 as console} from "forge-std/Test.sol";
import {Json} from "dev/util/Json.sol";

contract ZeroTx is Script {
    function run() public {
        vm.startBroadcast();
        payable(address(this)).transfer(0);
    }
}
