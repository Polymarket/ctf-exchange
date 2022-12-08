# Polymarket CTF Exchange
![Github Actions](https://github.com/Polymarket/ctf-exchange/workflows/Tests/badge.svg)

## Background

The Polymarket CTF Exchange is an exchange protocol that facilitates atomic swaps between [Conditional Tokens Framework(CTF)](https://docs.gnosis.io/conditionaltokens/) ERC1155 assets and an ERC20 collateral asset.

It is intended to be used in a hybrid-decentralized exchange model wherein there is an operator that provides offchain matching services while settlement happens on-chain, non-custodially.


## Documentation

Docs for the CTF Exchange are available in this repo [here](./docs/Overview.md).

## Audit

Polymarket engaged Chainsecurity to audit the security of the Polymarket CTF Exchange smart contracts. The full report is available [here](./audit/ChainSecurity_Polymarket_Governance_and_Exchange_audit_draft-5.pdf).


## Deployments

| Network          | Address                                                                           |
| ---------------- | --------------------------------------------------------------------------------- |
| Polygon          | [0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E](https://polygonscan.com/address/0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E)|
| Mumbai           | [0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E](https://mumbai.polygonscan.com/address/0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E)|


## Development

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

