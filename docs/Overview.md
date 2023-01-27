# Exchange 

## Overview

The `CTFExchange` contract facilitates atomic swaps between binary outcome tokens (ERC1155) and the collateral asset (ERC20). It is intended to be used in a hybrid-decentralized exchange model wherein there is an operator that provides matching/ordering/execution services while settlement happens on-chain,non-custodially according to instructions in the form of signed order messages. The CTF exchange allows for matching operations that include a mint/merge operation which allows orders for complementary outcome tokens to be crossed. Orders are represented as signed typed structured data (EIP712). Additionally, the CTFExchange implements symmetric fees. When orders are matched, one side is considered the maker and the other side is considered the taker. The relationship is always either one to one or many to one (maker to taker) and any price improvement is captured by the taking agent. 

## Matching Scenarios 

### Assets

* **`A`** - ERC1155 outcome token
* **`A'`** - ERC1155 outcome token, complement of **`A`**.*
* **`C`** - ERC20 collateral token. 


*\* Complements assumes 1 outcome token and 1 of its complement can always be merged into 1 unit of collateral and 1 unit of collateral can always be split into 1 outcome token and 1 of its complement (ie **`A`** + **`A'`** = **`C`**). Also assume that outcome tokens and collateral have the same decimals/base unit. Finally, the following examples assume **`C`** is USDC for pricing.*

### Scenario 1 - `NORMAL`

#### Maker Order

- **UserA** BUY **100** token **`A`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userA",
  "makerAsset": "C",
  "takerAsset": "A",
  "makerAmount": 50,
  "takerAmount": 100
}
```

#### Taker Order

- **UserB** SELL **50** token **`A`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userB",
  "makerAsset": "A",
  "takerAsset": "C",
  "makerAmount": 50,
  "takerAmount": 25
}
```

#### Match Operation Overview

`matchOrders(makerOrder, [takerOrder], 50, [25])`

1. Transfer **50** token **`A`** from **userB** into `CTFExchange`
2. Transfer **25** **`C`** from **userA** into `CTFExchange`
3. Transfer **50** token **`A`** from `CTFExchange` to **userA**
4. Transfer **25** **`C`** from `CTFExchange` to **userB**

### Scenario 2 - `MINT`

#### Maker Order

- **UserA** BUY **100** token **`A`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userA",
  "makerAsset": "C",
  "takerAsset": "A",
  "makerAmount": 50,
  "takerAmount": 100
}
```

#### Taker Order

- **UserB** BUY **50** token **`A'`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userB",
  "makerAsset": "C",
  "takerAsset": "A''",
  "makerAmount": 25,
  "takerAmount": 50
}
```

#### Match Operation Overview

`matchOrders(makerOrder, [takerOrder], 25, 25)`

1. Transfer **25** **`C`** from **userB** into `CTFExchange`
2. Transfer **25** **`C`** from **userA** into `CTFExchange`
3. Mint **50** token sets (= **50** token **`A`** + **50** token **`A'`**)
4. Transfer **50** token **`A`** from `CTFExchange` to **userA**
5. Transfer **50** token **`A'`** from `CTFExchange` to **userB**


### Scenario 3 - `MERGE`

#### Maker Order

- **UserA** SELL **50** token **`A`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userA",
  "makerAsset": "A",
  "takerAsset": "C",
  "makerAmount": 50,
  "takerAmount": 25
}
```

#### Taker Order

- **UserB** SELL **100** token **`A'`** @ **$0.50**

*(pseudo variables)*
```json
{
  "maker": "userB",
  "makerAsset": "A'",
  "takerAsset": "C'",
  "makerAmount": 100,
  "takerAmount": 50
}
```

#### Match Operation Overview

`matchOrders(makerOrder, [takerOrder], 50, 50)`

1. Transfer **50** **`A'`** from **userB** into `CTFExchange`
2. Transfer **50** **`A`** from **userA** into `CTFExchange`
3. Merge **50** token sets into **50** **`C`**(**50** token **`A`** + **50** token **`A'`** = **50** **`C`**)
4. Transfer **25** **`C`** from `CTFExchange` to **userA**
5. Transfer **25** **`C`** from `CTFExchange` to **userB**

## Fees

Fees are levied in the output asset (proceeds). Fees for binary options with a complementary relationship (ie **`A`** + **`A'`** = **`C`**) must be symmetric to preserve market integrity. Symmetric means that someone selling 100 shares of `A` @ $0.99 should pay the same fee value as someone buying 100 `A'` @ $0.01. An intuition for this requires understanding that minting/merging a complementary token set for collateral can happen at any time. Fees are thus implemented in the following manner. 

If buying (ie receiving **`A`** or **`A'`**), the fee is levied on the proceed tokens. If selling (ie receiving **`C`**), the fee is levied on the proceed collateral. The base fee rate (`baseFeeRate`) is signed into the order struct. The base fee rate corresponds to 2x the fee rate (collateral per unit of outcome token) paid by traders when the price of the two tokens is equal (ie $0.50 and $0.50). Moving away from a centered price, the following formulas are used to calculate the fees making sure to maintain symmetry.

usdcFee =  baseRate * min(price, 1-price) * outcomeShareCount

**Case 1:** If selling outcome tokens (base) for collateral (quote):

$feeQuote =  baseRate * \min(price, 1-price) * size$

**Case 2:** If buying outcome tokens (base) with collateral (quote):

$feeBase =  baseRate * \min(price, 1-price) * \frac{size}{price}$

### Fee Examples:

*(assume the full order is filled)*

`baseFeeRate` = 0.02 (usdc/condition)

____

BUY **100** **`A`** @ **$0.50** 

`fee` = 2 **`A`**

($1.00 in value)
___

SELL **100** **`A'`** @ **$0.50** 

`fee` = 1.0 **`C`**

($1.00 in value)
___

BUY **100** **`A`** @ **$0.10** 

`fee` = 2 **`A`**

($0.20 in value)
___

SELL **100** **`A``** @ **$0.90** 

`fee` = 0.20 **`C`**

($0.20 in value)

___

BUY **100** **`A`** @ **$0.90** 

`fee` = .222 **`A`**

($0.20 in value)
___

SELL **100** **`A``** @ **$0.10** 

`fee` = 0.20 **`C`**

($0.20 in value)

## Package Layout

The [`exchange/`]() package includes libraries, mixins, interface definitions and tests supporting the primary contract `CTFExchange`. Mixins are primarily full implementations of related interfaces that are then inherited by the `CTFExchange`. These contracts define the core logic and are supported by library contracts. Mixins are designated as abstract functions because they are intended to always be inherited from. Interfaces are generally separated into those that define function signatures and those that define events and errors (EE).


  

