# ProxyFactoryHelper

`PolyFactoryHelper` manages referenced proxy wallet factory addresses and provides wrappers around functions contained in both `PolySafeLib` and `PolyProxyLib` which calculate wallet addresses given the "owning" or "signing" EOA addresses of the proxy wallets. The `CTFExchange` supports two signature types related to contract wallets. Users of Polymarket's interface trade from contract wallets. Originally, these wallets were a custom implementation, but later, Gnosis safes were used. In order to maintain backwards compatibility, both types are supported by the `CTFExchange`. In both cases, the EOA that deploys/creates the proxy wallet is the approved "owner" of that wallet. This means that they are able to sign/execute transaction on the behalf of the contract. User's funds live in these proxy wallets, thus in order to support off-chain order signing (EOAs), the `CTFExchange` must be able to relate a signer to a corresponding wallet address. This contract along with the supporting library functions allow exactly that. 

## `constructor`

Sets the `proxyFactory` and `safeFactory` state variables. 

Parameters:

```java
address _proxyFactory // address of Polymarket proxy wallet factory
address _safeFactory // address of gnosis safe factory
```

## `getProxyFactory`

Getter for the Polymarket proxy factory address.

Returns:

```java
address // address of Polymarket proxy wallet factory
```

## `getSafeFactory`

Getter for the Gnosis safe factory address.

Returns:

```java
address // address of gnosis safe factory
```

## `getPolyProxyFactoryImplementation`

Calls the `getImplementation` function on the `proxyFactory` which should return the address of the proxy wallet implementation that is cloned when a new wallet is created via the factory. 

Returns:

```java
address // the Polymarket Proxy factory implementation
```

## `getSafeFactoryImplementation`

Calls the `masterCopy` function on the `safeFactory` which should return the address of the gnosis safe implementation that is cloned when a new wallet is created via the factory. 

Returns:

```java
address // the Safe factory implementation
```

## `getPolyProxyWalletAddress`

Uses the `PolyProxyLib`'s `computeProxyWalletAddress` function, called with the provided owner address, the stored Polymarket proxy factory implementation address and the proxy factory address to return the wallet address of the owner. 

Parameters:

```java
address _addr // the owner's address for which to calculate their proxy address
```

Returns:

```java
address // the _addr's owned proxy wallet address
```

## `getSafeAddress`

Uses the `PolySafeLib`'s `getSafeAddress` function, called with the provided owner address, the stored safe factory implementation address and the safe factory address to return the wallet address of the owner. 

Parameters:

```java
address _addr // the owner's address for which to calculate their safe address
```

Returns:

```java
address // the _addr's owned safe address
```

## `_setProxyFactory`

Internal function to set the `proxyFactory` address. 

Parameters:

```java
address _proxyFactory // Polymarket proxy factory address
```

Emits:

- `ProxyFactoryUpdated(proxyFactory, _proxyFactory)`


## `_setSafeFactory`

Parameters:

```java
address _safeFactory // Gnosis safe factory address
```

Internal function to set the `safeFactory` address. 

Emits:

- `SafeFactoryUpdated(safeFactory, _safeFactory)`