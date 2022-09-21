// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2 as console} from "forge-std/Script.sol";
import {Io} from "dev/util/Io.sol";

// forces forge to download the specified solc version
contract prepareTempFolder is Script {
    // returns true
    function run() public returns (bool) {
        Io._prepareTempFolder();
        return true;
    }
}
