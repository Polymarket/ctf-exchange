# Assets

Stores the addresses of the ERC20 collateral and ERC155 outcome tokens. 

## `constructor`

Initializes the contract, setting the collateral token address and ctf token address state variables. Also approves the ctf contract to spend usdc on the contract's behalf.

Parameters:

```java
address _collateral // collateral token (ERC20)
address _ctf // ctf outcome token (ERC1155)
```

## `getCollateral`

Gets the stored `collateral` address.

Returns:

```java
address // collateral token address
```

## `getCtf`

Gets the stored `ctf` address.

Returns:

```java
address // ctf address
```