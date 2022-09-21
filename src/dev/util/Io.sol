// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console2 as console} from "forge-std/Test.sol";
import {vm} from "./vm.sol";

library Io {
    string constant tempFolder = "tmp";

    function read(string memory filePath) internal returns (bytes memory) {
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        c[2] = string.concat("cat ", filePath);

        bytes memory result = vm.std_cheats.ffi(c);
        return result;
    }

    function write(string memory filePath, string memory _content) internal {
        _prepareTempFolder();
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        c[2] = string.concat("echo -n ", _content, " > ", filePath);

        vm.std_cheats.ffi(c);
    }

    function _prepareTempFolder() internal {
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        // c[2] = 'cast ae "x(string)" $(pwd)';
        c[2] = "mkdir -p tmp && echo -n 0x00";
        // c[0] = string.concat("mdkir -p ", tempFolder);

        vm.std_cheats.ffi(c);
    }
}
