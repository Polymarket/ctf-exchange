// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import {vm} from "dev/util/vm.sol";
import {Ascii} from "dev/util/Ascii.sol";

library Log {
    function logERC20(string memory label, uint256 value) internal {
        string[] memory inputs = new string[](2);
        inputs[0] = "scripts/formatERC20.sh";
        inputs[1] = string(Ascii.encodeUint256(value));

        string memory result = string(vm.std_cheats.ffi(inputs));
        console.log(string.concat(label, ": ", result));
    }

    function logX96(string memory label, uint256 value) internal {
        string[] memory inputs = new string[](2);
        inputs[0] = "scripts/formatX96.sh";
        inputs[1] = string(Ascii.encodeUint256(value));

        string memory result = string(vm.std_cheats.ffi(inputs));
        console.log(string.concat(label, ": ", result));
    }
}
