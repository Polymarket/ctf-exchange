#!/usr/bin/env bash

LOCAL=.env.local
TESTNET=.env.testnet
MAINNET=.env

if [ -z $1 ]
then
  echo "usage: deploy_exchange.sh [local || testnet || mainnet]"
  exit 1
elif [ $1 == "local" ]
then
  ENV=$LOCAL
elif [ $1 == "testnet" ]
then
  ENV=$TESTNET
elif [ $1 == "mainnet" ]
then
  ENV=$MAINNET
else
  echo "usage: deploy_exchange.sh [local || testnet || mainnet]"
  exit 1
fi

source $ENV

echo "Deploying CTF Exchange..."

echo "Deploy args:
Admin: $ADMIN
Collateral: $COLLATERAL
ConditionalTokensFramework: $CTF
ProxyFactory: $PROXY_FACTORY
SafeFactory: $SAFE_FACTORY
"

OUTPUT="$(forge script ExchangeDeployment \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --broadcast \
    -s "deployExchange(address,address,address,address,address)" $ADMIN $COLLATERAL $CTF $PROXY_FACTORY $SAFE_FACTORY)"

EXCHANGE=$(echo "$OUTPUT" | grep "{" | jq -r .returns.exchange.value)
echo "Exchange deployed: $EXCHANGE"

echo "Complete!"

sleep 20

ENCODED_ARGS_EXCHANGE=$(cast abi-encode "constructor(address,address,address,address)" $COLLATERAL $CTF $PROXY_FACTORY $SAFE_FACTORY)
echo "Verifying CTFExchange..."
forge verify-contract $EXCHANGE src/exchange/CTFExchange.sol:CTFExchange \
    --constructor-args $ENCODED_ARGS_EXCHANGE \
    --compiler-version "v0.8.15+commit.e14f2714" \
    --rpc-url $RPC_URL \
    -e $ETHERSCAN_API_KEY

echo "Complete!"
