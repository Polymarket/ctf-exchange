// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {vm} from "./vm.sol";

library Reader {
    function read(string memory _path) internal returns (bytes memory) {
        string[] memory c = new string[](3);
        c[0] = "bash";
        c[1] = "-c";
        c[2] = string.concat('cast ae "response(bytes)" $(xxd -p ', _path, ")");

        bytes memory result = vm.std_cheats.ffi(c);
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
