// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script, console2 as console} from "forge-std/Test.sol";
import {Json} from "dev/util/Json.sol";

contract PoolBytecodeHash is Script {
    function run() public {
        bytes memory result = Json.readData("artifacts/UniswapV3Pool.json", ".bytecode");
        console.logBytes32(keccak256(result));
    }
}
