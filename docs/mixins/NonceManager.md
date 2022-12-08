# Nonce Manager

The nonce manager is a mixin responsible for maintaining a mapping of account nonces. These account nonces are used to determine the validity of an order and allow users to cancel orders via nonce changes and increments. Specifically, an order is only valid if the nonce included in the signed order matches the signers current nonce value. Note that nonces can only increase therefore if an account sets their nonce to the max unint256, they will no longer be able to cancel orders via nonce increments. 


## `incrementNonce`

Increments (by 1) an account's nonce. `msg.sender` is used to determine the account of which to increment the nonce for. 

## `updateNonce`

Updates an account's nonce by adding a specific uint256 `val` to the user's current nonce value. Again, `msg.sender` is used to determine the account for nonce addition.

Parameters:

```java
uint256 val // value to add to user's current nonce
```

## `isValidNonce`

Provided a user address and a nonce, returns a boolean indicating whether or not the specified nonce matches the user's nonce stored in the `nonces` state variable mapping. 

Parameters:

```java
address usr // account to match nonce for
uint256 nonce // nonce value to compare against
```

Returns:

```java
bool // indicates whether a supplied nonce matches the user's nonce as stored in nonces mapping
```