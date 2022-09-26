// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order } from "../libraries/OrderStructs.sol";

abstract contract IHashing {
    function hashOrder(Order memory order) public view virtual returns (bytes32);
}
