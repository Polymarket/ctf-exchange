# CTFExchange

`CTFExchange` is the core binary limit order exchange contract. It inherits from various library and mixin functions and provides a concise definition of entry points. 
___


## `constructor`

Initializes the abstract contracts it inherits from including `Asset` `Signatures` and `Fees`.

Parameters:

```java
address _collateral // ERC20 collateral asset (USDC)
address _ctf //  ERC1155 outcome tokens contract (gnosis conditional tokens framework)
address _proxyFactory // Polymarket proxy factory
address _safeFactory // Gnosis safe factory contract 
address _feeReceiver // account to accumulate feed to 
```

## `pauseTrading`

Allows admin to pause trading. 

Requirements:

- caller is `admin` (`onlyAdmin`)

## `unpauseTrading`

Allows admin to unpause trading. 

Requirements:

caller is `admin` (`onlyAdmin`)

## `fillOrder`

Fills the fill amount of an order with `msg.sender` as the taker

Parameters:

```java
Order order // The order to be filled
uint256 fillAmount // The amount to be filled, always in terms of the maker amount
```

Requirements:

- caller is `operator` (`onlyOperator`)
- trading is not `paused` (`notPaused`)
- function is being called for first time in control flow or the previous function call has resolved (`nonReentrant`)


## `fillOrders`

Fills an array of orders for the corresponding fill amounts with `msg.sender` as the taker

Parameters:

```java
Order[] orders // The order to be filled
uint256[] fillAmounts // The amounts to be filled, always in terms of the maker amount
```

Requirements:

- caller is `operator` (`onlyOperator`)
- trading is not `paused` (`notPaused`)
- function is being called for first time in control flow or the previous function call has resolved (`nonReentrant`)

## `matchOrders`

Matches a taker order against an array of maker orders for the specified amounts. 

Parameters:

```java
Order takerOrder // The active order to be matched
Order[] makerOrders // The array of maker orders to be matched against the active order
uint256 takerFillAmount // The amount to fill on the taker order, always in terms of the maker amount
uint256[] makerFillAmounts // The array of amounts to fill on the maker orders, always in terms of the maker amount
```

Requirements:

- caller is `operator` (`onlyOperator`)
- trading is not `paused` (`notPaused`)
- function is being called for first time in control flow or the previous function call has resolved (`nonReentrant`)

## `setFeeReceiver`

Sets `feeReceiver` to new address. 

Parameters:

```java
address _feeReceiver // The new fee receiver address
```

Requirements:

- caller is `admin` (`onlyAdmin`)


## `setProxyFactory`

Sets `proxyFactory` to new Polymarket proxy wallet factory address. 

Parameters:

```java
address _newProxyFactory // The new Proxy Wallet factory
```

Requirements:

- caller is `admin` (`onlyAdmin`)

## `setSafeFactory`

Sets `safeFactory` to new gnosis safe factory address.

Parameters:

```java
address _newSafeFactory // The new Safe wallet factory
```
Requirements:

- caller is `admin` (`onlyAdmin`)


## `registerToken`

Registers a tokenId, its complement and its conditionId for trading.

Parameters:

```java
uint256 token // The ERC1155 (ctf) tokenId being registered
uint256 complement // The ERC1155 (ctf) token ID of the complement of token
bytes32 // The corresponding CTF conditionId
```
Requirements:

- caller is `admin` (`onlyAdmin`)