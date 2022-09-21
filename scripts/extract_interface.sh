

# // extract an interface from a CONTRACT

forge inspect CONTRACT abi > abi.json
cast interface abi.json > IFace.sol

interface() {
  if [[ $1 == 0x* ]]; then
    cast interface $1 -c ${2:-mainnet} --etherscan-api-key ${3:-$ETHERSCAN_API_KEY}
  else
    cast interface <(forge inspect $1 abi)
  fi
}