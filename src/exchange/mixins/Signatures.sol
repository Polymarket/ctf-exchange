// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC1271 } from "openzeppelin-contracts/interfaces/IERC1271.sol";
import { ECDSA } from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

import { SignatureType, Order } from "../libraries/OrderStructs.sol";

import { ISignatures } from "../interfaces/ISignatures.sol";

import { PolyFactoryHelper } from "./PolyFactoryHelper.sol";

/// @title Signatures
/// @notice Maintains logic that defines the various signature types and validates them
abstract contract Signatures is ISignatures, PolyFactoryHelper {
    constructor(address _proxyFactory, address _safeFactory) PolyFactoryHelper(_proxyFactory, _safeFactory) { }

    /// @notice Validates the signature of an order
    /// @param orderHash - The hash of the order
    /// @param order     - The order
    function validateOrderSignature(bytes32 orderHash, Order memory order) public view override {
        if (!isValidSignature(order.signer, order.maker, orderHash, order.signature, order.signatureType)) {
            revert InvalidSignature();
        }
    }

    /// @notice Verifies a signature for signed Order structs
    /// @param signer           - Address of the signer
    /// @param associated       - Address associated with the signer.
    ///                           For signature type EOA, this MUST be the same as the signer address.
    ///                           For signature types POLY_PROXY and POLY_GNOSIS_SAFE, this is the address of the proxy or the safe
    /// @param structHash       - The hash of the struct being verified
    /// @param signature        - The signature to be verified
    /// @param signatureType    - The signature type to be verified
    function isValidSignature(
        address signer,
        address associated,
        bytes32 structHash,
        bytes memory signature,
        SignatureType signatureType
    ) internal view returns (bool) {
        if (signatureType == SignatureType.EOA) {
            return verifyEOASignature(signer, associated, structHash, signature);
        } else if (signatureType == SignatureType.POLY_GNOSIS_SAFE) {
            return verifyPolySafeSignature(signer, associated, structHash, signature);
        } else {
            // POLY_PROXY
            return verifyPolyProxySignature(signer, associated, structHash, signature);
        }
    }

    /// @notice Verifies an EOA ECDSA signature
    /// Verifies that:
    /// 1) the signature is valid
    /// 2) the signer and maker are the same
    /// @param signer      - The address of the signer
    /// @param maker       - The address of the maker
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function verifyEOASignature(address signer, address maker, bytes32 structHash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return (signer == maker) && verifyECDSASignature(signer, structHash, signature);
    }

    /// @notice Verifies an ECDSA signature
    /// @dev Reverts if the signature length is invalid or the recovered signer is the zero address
    /// @param signer      - Address of the signer
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function verifyECDSASignature(address signer, bytes32 structHash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return ECDSA.recover(structHash, signature) == signer;
    }

    /// @notice Verifies a signature signed by a Polymarket proxy wallet
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Proxy wallet is owned by the signer
    /// @param signer       - Address of the signer
    /// @param proxyWallet  - Address of the poly proxy wallet
    /// @param structHash   - Hash of the struct being verified
    /// @param signature    - Signature to be verified
    function verifyPolyProxySignature(address signer, address proxyWallet, bytes32 structHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifyECDSASignature(signer, structHash, signature) && getPolyProxyWalletAddress(signer) == proxyWallet;
    }

    /// @notice Verifies a signature signed by a Polymarket Gnosis safe
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Safe is owned by the signer
    /// @param signer      - Address of the signer
    /// @param safeAddress - Address of the safe
    /// @param hash        - Hash of the struct being verified
    /// @param signature   - Signature to be verified
    function verifyPolySafeSignature(address signer, address safeAddress, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return verifyECDSASignature(signer, hash, signature) && getSafeAddress(signer) == safeAddress;
    }
}
