# Asset Operations

Provides balance fetching, transferring and ctf utilities as an abstract contract. Implements both the `IAssetOperations` and `IAssets` interface. 

## `_getBalance`

Gets the contract's balance of collateral (`tokenID` == 0) or the contract's balance of the conditional token. 

Parameters:

```java
uint256 tokenId // ERC1155 tokenID for ctf, or 0 for getting collateral (ERC20) balance
```

Returns:

```java
uint256 // token balance
```

## `_transfer`

Transfers a quantity of assets, defined by a tokenID, from one address to another address. Calls either `_transferCollateral` or `TransferHelper._transferFromERC1155`. 

Parameters:

```java
address from // account from which to transfer assets
address to // account to which to transfer assets
uint256 id // ID of asset to transfer. ERC1155 tokenID for ctf, or 0 for getting collateral (ERC20) balance
uint256 value // amount of asset to transfer
```

## `_transferCollateral`

Called by `_transfer` in the case that `id` == 0. Transfers ERC20 collateral using the `TransferHelper` library which in turn uses either the `transfer` or `transferFrom` ERC20 interface methods. The choice of transfer method depends on whether or not the from address is the contract itself. 

Parameters:

```java
address from // account from which to transfer the ERC20 tokens
address to // account to which to transfer the ERC20 tokens
uint256 value // amount of ERC20 tokens to transfer
```

## `_mint`

Mints a full conditional token set from collateral by calling the `splitPostion` function ont he ctf contract with the provided `conditionId`. This will convert X units of collateral (ERC20) into X units of complementary outcome tokens (ERC1155). The zeroed bytes32 is used as the `parentCollectionId` and the partition is the simple binary case [1,2]. You can read more about Gnosis Conditional Tokens [here](https://docs.gnosis.io/conditionaltokens/docs/devguide01/).

Parameters:

```java
bytes32 conditionId // id of condition on which to split
uint256 amount // quantity of collateral to split. Note the collateral and minted conditional tokens will use the same number of decimals.
```


## `_merge`

Opposite of `_mint`. Takes complete sets (equal parts of two complementary outcome tokens) and merges (burns) them by calling the `mergePositions` function on the ctf contract with the provided `conditionId`. Specifically this will convert X complete sets (X of token A (ERC1155) and X of its its complement token A' (ERC1155)) into X units of collateral (ERC20). This function assumes merging happens on a binary set and for the zeroed bytes32 `parentCollectionId`. You can read more about Gnosis Conditional Tokens [here](https://docs.gnosis.io/conditionaltokens/docs/devguide01/).

Parameters:

```java
bytes32 conditionId // id of condition on which to merge
uint256 amount // quantity of complete sets to burn for their underlying collateral.
```