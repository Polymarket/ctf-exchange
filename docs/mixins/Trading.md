# Trading

Trading implements the core exchange logic for trading CTF assets. 

*Note a core assumption that is made is that the collateral and conditional tokens have the same number of decimals. This is true for any CTF token.*

## `getOrderStatus`

Get the status of an order. An order can either be not-filled, partially filled or fully filled. If an order has not been filled, its hash will not exist in the `orderStatus` mapping. If it has been partially filled its hash will exist in this mapping and the maker amount `remaining` will be defined. If the order has been fully filled the hash will exist and the `isCompleted` bool in the `OrderStatus` object will be `true`

Parameters:

```java
bytes32 orderHash // hash of the order
```

Returns:

```java
OrderStatus // status object for the order hash
```

## `validateOrder`

Validates an order. Hashes an order and calls `_validateOrder` with the order hash and order object.

Parameters:

```java
Order order // order to be validated
```

## `cancelOrder`

Cancels an order. Calls `_cancelOrder` with the order. An order can only be cancelled by its maker, the address which holds funds for the order.

Parameters:

```java
Order order // order to be cancelled
```

## `cancelOrders`

Cancels a set of orders by calling `_cancelOrder` on each order is provided order array. 

Parameters:

```java
Order[] orders // orders to be cancelled
```

## `_cancelOrder`

Cancels an order by setting its status to completed.

Requirements:

- order's `maker` must be `msg.sender`
- order cannot have already been filled

Parameters:

```java
Order order // order  to cancel
```

Emits:

- `OrderCancelled(orderHash)`

## `_validateOrder`

Validates an order alongside its hash. Reverts if order is not valid.

Requirements:

- order is not expired
- order fee rate is not greater than configured max fee rate
- order signature is valid for order
- order is not already filled
- order has valid nonce

Parameters:

```java
bytes32 orderHash // hash of order to validate
Order order // order object corresponding to orderHash
```

## `_fillOrder`

Fills an order against the caller. First validates the order, then fills it up to the amount specified by `fillAmount`, updates the status and takes calculated fee. 

Parameters:

```java
Order order // order to fill
uint256 fillAmount // amount to be filled, always in terms of the maker amount
address to // address to receive proceeds from filling the order
```

Emits:

- `emit OrderFilled(orderHash, msg.sender, order.makerAssetId, order.takerAssetId, making, remaining, fee)`


## `_fillOrders`

Fills a set of orders against the caller by calling `_fillOrders` for each order and corresponding fill amount. 

```java
Order[] orders // orders to fill
uint256[] fillAmounts // amounts to be filled for each order in orders, always in terms of the maker amount
address to // address to receive proceeds from filling the orders
```

## `_matchOrders`

Matches a taker order against an array of maker orders up to the amounts specified. Validation is performed to make sure each maker order is able to be filled with the taker order up to the amount specified. The order of transfer operations in the fill is:

1. transfer making amount from taker order to exchange
2. Fill each maker order
   1. Transfer making amount for maker order into exchange
   2. Execute match call (merge or mint)
   3. Transfer taking amount for maker order to the maker order's maker
   4. Fee charged on maker
3. transfer taking amount (calculated based on maker order fills, will include any price improvement for buying) to taker order maker
4. Fee charged on taker
5. transfer any excess making amount left from exchange to taker order maker (price improvement in case of selling)

Requirements:

- all orders valid
- making amounts are valid for each order
- taker order provides enough assets for the filling of all maker orders to the amounts specified
- each maker order is marketable against taker order
- taker gets at least as much proceeds as they expect

Parameters:

```java
Order takerOrder // taker order to be matched
Order[] makerOrders // array of maker orders to be matched against the taker order
uint256 takerFillAmount // amount to fill on the taker order, in terms of the maker amount
uint256[] memory makerFillAmounts // array of amounts to fill on the maker orders, in terms of the maker amount
```

Emits:

- `OrderFilled(orderHash, address(this), takerOrder.makerAssetId, takerOrder.takerAssetId, making, remaining, fee)`
- `OrdersMatched(orderHash, takerOrder.makerAssetId, takerOrder.takerAssetId, making, taking)`

## `_fillMakerOrders`

Fills an array of maker orders for the specified amounts. 

Parameters:

```java
Order takerOrder // taker order
Order[] makerOrders // maker orders
uint256[] makerFillAmounts // maker amounts to fill on each maker order
```

## `_fillMakerOrder`

Fills a maker order. In doing so, validates it is marketable with a supplied taker order, derives the pre/post matching operation and charges fees.

Requirements:

- valid taker and maker order
- maker and taker order can be crossed
- amount provided is fillable for maker order

Parameters:

```java
Order takerOrder // taker order object
Order makerOrder // maker order object
uint256 fillAmount // maker amount to be filled on makerOrder
```

Emits:

- `OrderFilled(hashOrder(makerOrder), takerOrder.maker, makerOrder.makerAssetId, makerOrder.takerAssetId, making, remaining, fee)`


## `_validateOrderAndCalcTaking`

Performs common order validation and calculates taking amount for a matched order. The taking amount is proportional to the making amount that is being filled. Additionally the order status is updated to reflect the amount that is being filled. 

Requirements:

- Order is valid
- Making amount can be filled on order

Parameters:

```java
Order order // order being validated
uint256 making // maker amount to be filled of order
```

Returns:

```java
uint256 takingAmount // amount of taking amount corresponding to supplied taking amount 
uint256 remainingAmount // maker amount remaining on the order. 
```

## `_fillFacingExchange`

Fills a maker order using the Exchange as the counterparty. Follows the following steps:

1. Transfers makingAmount of maker asset from the order maker to the exchange
2. Executes the match call
   1. In the case a buy + sell is being matching nothing happens
   2. In the case a buy + buy is being matched, a mint (split) happens, since the taker order's collateral is already available and the maker order's collateral was just transferred there should be enough to mint takingAmount.
   3. In the case a sell + sell is being matched a merge happens, since the taker order's conditional tokens will have already been transferred to the exchange and the taker order's conditional tokens were just transferred, there should be enough conditional tokens to merge makingAmount.
3. Transfer taking amount of taker asset to the order maker

Parameters:

```java
uint256 makingAmount // Amount to be filled in terms of maker amount
uint256 takingAmount // Amount to be filled in terms of taker amount
Order order // the order to be filed
MatchType matchType // the match type
```

## `_deriveMatchType`

Provided a taker and maker order determines the matching operation that is needed. 

Parameters:

```java
Order takerOrder // the taker order
Order makerOrder // the maker order
```

Returns:

```java
MatchType // type of match NORMAL, MINT or MERGE
```

## `_executeMatchCall`

Executes a CTF call to match orders by minting new Outcome tokens or merging Outcome tokens into collateral.

Parameters:

```java
uint256 makingAmount // Amount to be filled in terms of maker amount, used as amount in merge case
uint256 takingAmount // Amount to be filled in terms of taker amount, used as amount in mint case
Order order // order to be filled
MatchType matchType // the match type
```

## `_validateTakerAndMaker`

Ensures the taker and maker orders can be matched against each other.

Requirements:

- orders are crossing
- in case of NORMAL, conditional tokenIds match across maker and taker order
- in case of MINT, conditional tokenIds should be complementary
- in case of MERGE, conditional tokenIds should be complementary

Parameters:

```java
Order takerOrder // the taker order
Order makerOrder // the maker order
MatchType matchType // the match type
```

## `_chargeFee`

Charges a fee from a payer to the receiver.

Parameters:

```java
address payer // fee payer
address receiver // fee recipient
uint256 tokenId // token id of fee, 0 if collateral
uint256 fee // fee amount
```

Emits:

- `FeeReceived(payer, receiver, tokenId, fee)`

## `_updateOrderStatus`

Updates the order status. Will mark as completed if the making amount plus any already filled amount of order is equal to total order size, otherwise will calculate and store the remaining amount. 

Parameters:

```java
bytes32 orderHash // order hash
Order order // order object
uint256 makingAmount // making amount
```

Returns:

```java
uint256 // remaining maker amount for order
```

## `_updateTakingWithSurplus`

Checks to see how much of the tokenId the exchange contract has received and verifies it is greater than the min amount and returns the max(actualAmount, minimumAmount).

Parameters:

```java
uint256 minimumAmount // minimum amount exchange should have of tokenId
uint256 tokenId // tokenId to get balance of
```

Returns:

```java
uint256 // amount of tokenId in contract
```