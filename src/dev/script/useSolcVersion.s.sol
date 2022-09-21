// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2 as console} from "forge-std/Script.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

// forces forge to download the specified solc version
contract useSolcVersion is Script {
    // returns true
    function run() public view returns (bool) {
        console.log("using 0.8.15");
        return true;
    }
}
