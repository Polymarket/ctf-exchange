// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { EIP712 } from "openzeppelin-contracts/utils/cryptography/draft-EIP712.sol";

import { IHashing } from "../interfaces/IHashing.sol";

import { Order, ORDER_TYPEHASH } from "../libraries/OrderStructs.sol";

abstract contract Hashing is EIP712, IHashing {
    bytes32 public immutable domainSeparator;

    constructor(string memory name, string memory version) EIP712(name, version) {
        domainSeparator = _domainSeparatorV4();
    }

    /// @notice Computes the hash for an order
    /// @param order - The order to be hashed
    function hashOrder(Order memory order) public view override returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.salt,
                    order.maker,
                    order.signer,
                    order.taker,
                    order.tokenId,
                    order.makerAmount,
                    order.takerAmount,
                    order.expiration,
                    order.nonce,
                    order.feeRateBps,
                    order.side,
                    order.signatureType
                )
            )
        );
    }
}
