#!/usr/bin/env bash

source .env.local

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
