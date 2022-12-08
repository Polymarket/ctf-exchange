# Fees

Provides simple utilities related to setting/getting a max fee rate

## `getMaxFeeRate`

Gets the max fee rate which is hard coded to 1000 bps.

Returns:

```java
uint256 // max fee rate that can be signed into an order
```

## `getFeeReceiver`

Gets the fee receiver.

Returns:

```java
address feeReceiver // address to which fees should be sent
```

## `_setFeeReceiver`

Sets a new fee receiver.

Parameters:

```java
address _feeReceiver // address to which fees should be sent
```