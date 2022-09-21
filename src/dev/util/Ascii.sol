// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @notice ascii functions
library Ascii {
    /// @notice converts a uint256 to string
    /// @param _value, uint256, the value to convert
    /// @return result the resulting string
    function encodeUint256(uint256 _value) internal pure returns (string memory result) {
        if (_value == 0) return "0";

        assembly {
            // largest uint = 2^256-1 has 78 digits
            // reserve 110 = 78 + 32 bytes of data in memory
            // (first 32 are for string length)

            // get 110 bytes of free memory
            result := add(mload(0x40), 110)
            mstore(0x40, result)

            // keep track of digits
            let digits := 0

            for {} gt(_value, 0) {} {
                // increment digits
                digits := add(digits, 1)
                // go back one byte
                result := sub(result, 1)
                // compute ascii char
                let c := add(mod(_value, 10), 48)
                // store byte
                mstore8(result, c)
                // advance to next digit
                _value := div(_value, 10)
            }
            // go back 32 bytes
            result := sub(result, 32)
            // store the length
            mstore(result, digits)
        }
    }

    function encodeBytes(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "00";
        string memory table = "0123456789abcdef";
        uint256 length = _data.length;
        bytes memory result = new bytes(2 * length + 2);
        assembly {
            //
            let resultPtr := add(result, 32)
            //
            let tablePtr := add(table, 1)
            //
            let dataPtr := add(_data, 1)

            // write two bytes '0x' at most significant digits
            // this is actually not necessary for ffi
            mstore8(resultPtr, 48)
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, 120)
            resultPtr := add(resultPtr, 1)

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let c := mload(dataPtr)
                // first 4 bits
                let c1 := and(0x0f, shr(4, c))
                // second 4 bits
                let c2 := and(0x0f, c)

                mstore8(resultPtr, mload(add(tablePtr, c1)))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, c2)))
                resultPtr := add(resultPtr, 1)

                dataPtr := add(dataPtr, 1)
            }
        }
        return string(result);
    }
}
