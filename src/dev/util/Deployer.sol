// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {vm} from "dev/util/vm.sol";
import {Json} from "dev/util/Json.sol";

library Deployer {
    function deployCode(string memory _what) internal returns (address addr) {
        addr = deployCode(_what, "", "");
    }

    function deployCode(string memory _what, bytes memory _args, string memory _salt) internal returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.std_cheats.getCode(_what), _args);
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        }
    }

    function deployBytecode(bytes memory _initcode, bytes memory _args, string memory _salt)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(_initcode, _args);
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        }
    }

    function UniswapV3Factory() public returns (address) {
        // Solenv.config();
        // bool forkUniswap = vm.std_cheats.envBool("FORK_UNISWAP");
        bytes memory initcode = Json.readData("artifacts/UniswapV3Factory.json", ".bytecode");
        return deployBytecode(initcode, "", "");
    }

    function ConditionalTokens() public returns (address) {
        bytes memory initcode = Json.readData("artifacts/ConditionalTokens.json", ".bytecode.object");
        return deployBytecode(initcode, "", "");
    }
}
