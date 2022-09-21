// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console2 as console} from "forge-std/Test.sol";
import {vm} from "./vm.sol";

library Json {
    function read(string memory _path, string memory _filter) internal returns (bytes memory) {
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        c[2] = string.concat('cast ae "response(bytes)" $(jq -j ', _filter, " ", _path, " | xxd -p)");
        // in general should dump with xxd -p (or whatever)
        bytes memory data = vm.std_cheats.ffi(c);

        return data;
    }

    function readData(string memory _path, string memory _filter) internal returns (bytes memory) {
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        c[2] = string.concat('cast ae "response(bytes)" $(jq -j ', _filter, " ", _path, ")");

        bytes memory data = vm.std_cheats.ffi(c);
        bytes memory result = abi.decode(data, (bytes));

        return result;
    }

    // function write(string memory filePath, string memory data) internal {
    //     string[] memory writeInputs = new string[](3);
    //     writeInputs[0] = "scripts/io_write.sh";
    //     writeInputs[1] = filePath;
    //     writeInputs[2] = data;

    //     vm.std_cheats.ffi(writeInputs);
    // }
}
