# Auth

Manages authenticated address with two distinct tiers: `admins` and `operators`. Both roles are represented through mappings allowing for any address to be designated to either role. Admins ultimately have the highest role based access control as they are capable of modifying (adding/removing) the `operators` mapping. All `admins` are equal and can add/remove other `admins`. Initially the contract deployer is the only authorized admin and `operator`. Implements `IAuth` interface.

## `onlyAdmin`

Modifier that reverts in the case that the `msg.sender` is not an admin specifically, it checks the value of `msg.sender` in the `admins` mapping, reverting if it's not `1`. 

## `onlyOperator`

Modifier that reverts in the case that the `msg.sender` is not an operator specifically, it checks the value of `msg.sender` in the `operators` mapping, reverting if it's not `1`. 

## `constructor`

Initializes the contract, designating the deployer as the sole admin and operator.

## `isAdmin`

Gets a boolean indicating whether or not a specified address has been designated as an admin. 

Parameters:

```java
address usr // address to check for admin status
```

Returns:

```java
bool // true if usr is an admin, false if not
```

## `isOperator`

Gets a boolean indicating whether or not a specified address has been designated as an operator. 

Parameters:

```java
address usr // address to check for operator status
```

Returns:

```java
bool // true if usr is an operator, false if not
```

## `addAdmin`

Adds an admin by setting the value of a specified address key to `1` in the `admins` mapping. 

Requirements:

- caller is `admin` (`onlyAdmin`)

Parameters:

```java
address admin_ // address to add as an admin
```

Emits:

- `NewAdmin(admin_, msg.sender)`

## `addOperator`

Adds an operator by setting the value of a specified address key to `1` in the `operators` mapping. 

Requirements:

- caller is `admin` (`onlyAdmin`)

Parameters:

```java
address operator_ // address to add as an operator
```

Emits:

- `NewOperator(operator_, msg.sender)`

## `removeAdmin`

Removes an admin by setting the value of a specified address key to `0` in the `admins` mapping. 

Requirements:

- caller is `admin` (`onlyAdmin`)

Parameters:

```java
address admin // address to remove as an admin
```

Emits:

- `RemovedAdmin(admin, msg.sender)`

## `removeOperator`

Removes an operator by setting the value of a specified address key to `0` in the `operator` mapping. 

Requirements:

- caller is `admin` (`onlyAdmin`)

Parameters:

```java
address operator // address to remove as an admin
```

Emits:

- `RemovedOperator(operator, msg.sender)`