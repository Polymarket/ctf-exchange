# Hashing

Provides a simple EIP712 typed structured data hashing utility function. Inherits from Open Zeppelin's draft-EIP712 contract and implements the `IHashing` interface. 

## `constructor`

Initializes the `Hasing` contract, setting the domainSeparator state variable via the parent `EIP712` contract's `_domainSeparatorV4` function and also calls the `EIP712` parent constructor. 

Parameters:

```java
address name // name of the signing domain
address version // current major version of signing domain
```


## `hashOrder`

Hashes an `Order` object according to the EIP712 procedure for hashing and signing of typed structured data. This will mirror the hashing done in client libraries used to prepare and sign orders. 


Parameters:

```java
Order order // order object to hash 
```

Returns:

```java
bytes32 // typed data hash of order object
```