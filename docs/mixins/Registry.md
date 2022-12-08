# Registry

The `CTFExchange` supports "binary matching". This assumes that two complementary tokens are always worth, in sum, 1 unit of underlying collateral. This is enforced by the CTF contract which always allows minting and merging of full sets (complete collection of outcomes, in our case `A` and its binary complement `A'`). What this ultimately unlocks for the `CTFExchange` is matching between buy orders of `A` and `A'` (via a preceeding "mint" operation), and sell orders of `A` and `A'` (via a succeeding "merge" operation). The `CTFExchange` gets orders to match and is able to determine whether or not a "mint" or "merge" operation is ncessary. The challenge, is that the "mint"/"merge" operation requires knowing the order's base asset's (conditional token) corresponding `conditionId`. Thus, there needs to be a way for the `conditionId` to be gotten from the `tokenId`. The `Registry` is responsible for this function and maintains a mapping of `tokenId`s to `OutcomeToken` objects which include information relating to the specific `tokenId` including the `complement`'s `tokenId`, and the parent `conditionId`. It is the responsibility of operators to register new outcome tokens. Note all methods assume benevolent input by the operator, specifically that they are registering the correct tokenIds/complements/conditions and that they are all binary outcomes that are valid in the context of the CTF contract.


## `getConditionId`

Gets the associated `conditionId` for a `tokenId` by looking it up in the `registry` mapping and returning the `conditionId` value.

Parameters:

```java
uint256 token // token id for which to get conditionId for
```

Returns:

```java
bytes32 // parent conditionId of the token according to the registry
```

## `getComplement`

Gets the complementary `tokenId` for a specified `tokenId` by looking it up in the `registry` mapping and returning the `complement` value. 

Parameters:

```java
uint256 token // token id for which to get complement token id for
```

Returns:

```java
uint256 // complement token id
```

## `validateComplement`

Checks whether the `token` id and `complement` id correspond according to `token`'s value in the `registry` mapping. Reverts if not.

Parameters:

```java
uint256 token // token id for which to check complement
uint256 complement // suspected complement token id of token
```

## `validateTokenId`

Checks whether a valid token id (`!=0`) has been registered. Reverts if not

Parameters:

```java
uint256 tokenId // token id to validate registration for
```

## `validateMatchingTokenIds`

Checks whether the `token0` id and `token1` id are equal if it has been registered. Reverts if not.

Parameters:

```java
uint256 token0 // first token id to compare for equality 
uint256 token1 // second token id to compare for equality
```

## `_registerToken`

Registers complementary token pair.

Parameters:

```java
uint256 token0 // first token id of pair
uint256 token1 // second token id of pair
bytes32 conditionID // cft conditionId for the pair
```

Requirements:

- `token0` and `token1` are not equal
- neither `token0` or `token1` are zero
- neither `token0` or `token` have been registered


Emits:

- `TokenRegistered(token0, token1, conditionId)`
- `TokenRegistered(token1, token0, conditionId)`
