# polymarket-protocol

Polymarket protocol smart contracts.

---

## Contracts

[Contract Documentation](docs/Main.md)

### `markets`

Core market contracts.

- factory
- market
- ptoken

---

### `market-ctf`

Gnosis Conditional Tokens Framework (CTF) extension market.
Allows the creation of a pMarket which will settle using the result of a particular CTF market. CTF conditional tokens may be exchanged for the corrsponding pToken.

---

### `market-periphery`

Contracts to help

1. Create markets
2. Trade pTokens in UniswapV3 pools
3. Call primary market functions from an EOA
4. Add liquidity to UniswapV3 pools

---

### `oracle`

Polymarket's oracle contract, serving as the resolution source for most pMarkets.

---

### `gov`

Polymarket governance contracts

- `POLY` token
- Polymarket GovernorBravo fork
- Polygon bridge

---

### `exchange`

Polymarket CTF Exchange contracts.

---

### `dev`

Helper contracts for testing, deployment, and general interactions.

---

## Set-up

Install [Foundry](https://github.com/foundry-rs/foundry/).

Foundry has daily updates, run `foundryup` to update `forge` and `cast`.

To install/update forge dependencies: `forge update`

To build contracts: `forge build`

To use prettier-solidity: `pnpm install` (or `npm install` or `yarn install`)

---

## Testing

To run all tests: `forge test`

To run test functions matching a regex pattern `forge test -m PATTERN`

To run tests in contracts matching a regex pattern `forge test --mc PATTERN`

Set `-vvv` to see a stack trace for a failed test.

---

To install new foundry submodules: `forge install UserName/RepoName@CommitHash`

To remove: `forge remove UserName/RepoName`

---

## Gotchas

UniswapV3Pool will revert without error message if you try add liquidity to an arbitrary range. E.g. if the fee tier is 500, liquidity can only be added to ranges with both tickUpper and tickLower multiples of 10.

---

## Tricks

The bash utility `bc` can be helpful for dealing with uints.
To display an X96 uint: `bc -l <<< $NUMBER/2^96`
To square a sqrtPriceX96: `bc -l <<< ($SQRT_PRICE/2^96)^2`
You can also echo and pipe these: `echo $NUMBER/2^96 | bc -l`

```[bash]
cast keccak 'hevm cheat code' | grep -o '.\{40\}$'
```

---
