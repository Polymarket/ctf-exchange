#!/usr/bin/env bash

# File paths for environment variables
LOCAL_ENV=".env.local"
TESTNET_ENV=".env.testnet"
MAINNET_ENV=".env"

# --- 1. Argument and Environment Selection ---
if [ -z "$1" ]; then
    echo "Usage: deploy_exchange.sh [local | testnet | mainnet]"
    exit 1
fi

case "$1" in
    "local")
        ENV_FILE=$LOCAL_ENV
        ;;
    "testnet")
        ENV_FILE=$TESTNET_ENV
        ;;
    "mainnet")
        ENV_FILE=$MAINNET_ENV
        ;;
    *)
        echo "Error: Invalid argument '$1'."
        echo "Usage: deploy_exchange.sh [local | testnet | mainnet]"
        exit 1
        ;;
esac

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found."
    exit 1
fi

# CRITICAL SECURITY WARNING: Sourcing private keys directly from environment files 
# is highly insecure. For production, use hardware wallets (Ledger/Trezor) or 
# dedicated secrets management services (e.g., AWS KMS, Azure Key Vault) via Foundry.
source "$ENV_FILE"

echo "Deploying CTF Exchange to $1 network..."

echo "Deploy arguments:
Admin: $ADMIN
Collateral: $COLLATERAL
ConditionalTokensFramework: $CTF
ProxyFactory: $PROXY_FACTORY
SafeFactory: $SAFE_FACTORY
"

# --- 2. Optimized Foundry Command ---
OUTPUT=$(forge script ExchangeDeployment \
    --private-key "$PK" \
    --rpc-url "$RPC_URL" \
    --json \
    --broadcast \
    --slow # Use --slow to rely on the RPC URL for fetching dynamic gas price, or remove to rely on default EIP-1559

    # Removed: --with-gas-price 200000000000 to use dynamic gas price from RPC
    # If EIP-1559 is supported, Foundry automatically uses it. 
    # If legacy pricing is needed for non-EIP-1559 chains (e.g., Polygon pre-London), use:
    # --gas-price $(cast gas-price --rpc-url $RPC_URL) 
    
    -s "deployExchange(address,address,address,address,address)" "$ADMIN" "$COLLATERAL" "$CTF" "$PROXY_FACTORY" "$SAFE_FACTORY"
)

# --- 3. Process Output (Requires 'jq') ---
# Extracting the deployed contract address from the JSON output
EXCHANGE=$(echo "$OUTPUT" | jq -r '
    .transactions[] | 
    select(.transactionType == "CREATE" and .contractName == "CTFExchange") | 
    .contractAddress
')

if [ -z "$EXCHANGE" ]; then
    echo "Error: Deployment failed or could not retrieve contract address."
    echo "Full Forge Output:"
    echo "$OUTPUT"
    exit 1
fi

echo "Exchange deployed: $EXCHANGE"
echo "Deployment Complete!"
