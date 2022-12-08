# Signatures 

The `CTFExchange` supports three distinct signature types:

- **EOA** - ECDSA EIP712 signatures signed by EOAs
- **POLY_PROXY** - EIP712 signatures signed by EOAs that own Polymarket Proxy wallets
- **POLY_GNOSIS_SAFE** - EIP712 signatures signed by EOAs that own Polymarket Gnosis safes

The `Signatures` contract provides functions for validating signatures and associated utilities. 

## `validateOrderSignature`

Validates the signature of an order. Calls `isValidSignature`, reverts if not truthy. 

Parameters:

```java
bytes32 orderHash // the has of the order
Order order // the order which includes the signature
```

## `isValidSignature`

Verifies a signature for signed Order structs. Follows validation paths based on the signature type. Returns boolean indicating signature validity

Parameters:

```java
address signer // Address of the signer
address associated //Address associated with the signer. For POLY_PROXY and POLY_GNOSIS_SAFE signature types, this is the address of the proxy or the safe. For EOA, this is the same as the signer address and is not used.
bytes32 structHash // hash of the struct being verified
bytes signature // signature to be verified
uint256 signatureType // signature type EOA, POLY_PROXY or POLY_GNOSIS_SAFE
```

Returns:

```java
bool // indicates validity of signature
```

## `verifyECDSASignature`

Verifies that a given ECDSA signature was that of the provided `signer` over the given `structHash`. Uses `SilentECDSA` library. Returns boolean indicating signature validity.

Parameters:

```java
address signer // signer address
bytes32 structHash // hash of the struct being verified
bytes signature // signature to be verified
```

Returns:

```java
bool // indicates validity of signature
```

## `verifyPolyProxySignature`

Verifies a signature created by the owner of a Polymarket proxy wallet. Specifically it verifies that:

- ECDSA signature is valid 
- Proxy wallet is owned by the signer

Parameters:

```java
address signer // signer
address proxyWallet // Polymarket proxy wallet (should be one "owned" by signer)
bytes32 structHash // Hash of the struct being verified
bytes signature // Signature to be verified
```

Returns:

```java
bool // indicates validity of signature
```

## `verifyPolySafeSignature`

Verifies a signature created by the owner of a Polymarket Gnosis safe. Specifically it verifies that:

- ECDSA signature is valid 
- PSafe is owned by the signer

Parameters:

```java
address signer // signer
address safeAddress // gnosis safe (should be one "owned" by signer)
bytes32 structHash // Hash of the struct being verified
bytes signature // Signature to be verified
```

Returns:

```java
bool // indicates validity of signature
```

## `getSignatureType`

Returns the associated `SignatureType` enum value provided an index.

Parameters:

```java
uint256 signatureType // index of signature type
```

Returns:

```java
SignatureType // SignatureType enum value of index
```