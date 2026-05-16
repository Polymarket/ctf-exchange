#!/usr/bin/env bash

# --- ENVIRONMENT CONFIGURATION ---
# Define the environment file names.
LOCAL_ENV=".env.local"
TESTNET_ENV=".env.testnet"
MAINNET_ENV=".env.mainnet" # Renamed from '.env' for clarity/safety

# --- ARGUMENT VALIDATION ---
if [ -z "$1" ]; then
    echo "Error: Missing environment argument."
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
        echo "Error: Invalid environment '$1'."
        echo "Usage: deploy_exchange.sh [local | testnet | mainnet]"
        exit 1
        ;;
esac

# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

# Load environment variables (RPC_URL, ADMIN, COLLATERAL, etc.).
# WARNING: Ensure PK (Private Key) is NOT committed to Git.
source "$ENV_FILE"

# --- DEPLOYMENT PRE-CHECK ---
if [ -z "$PK" ]; then
    echo "Error: PK (Private Key) is not set in $ENV_FILE. Aborting for security."
    exit 1
fi

echo "--- Deploying CTF Exchange to $1 ---"

echo "Deploy Arguments:
Admin: $ADMIN
Collateral: $COLLATERAL
ConditionalTokensFramework: $CTF
ProxyFactory: $PROXY_FACTORY
SafeFactory: $SAFE_FACTORY
"

# --- CORE FORGE EXECUTION ---

# Forge script command execution.
# Using standard gas price retrieval (no --with-gas-price) for robustness.
# PK is read from the environment variable (sourced above).
OUTPUT=$(forge script ExchangeDeployment \
    --private-key "$PK" \
    --rpc-url "$RPC_URL" \
    --json \
    --broadcast \
    -s "deployExchange(address,address,address,address,address)" \
    "$ADMIN" "$COLLATERAL" "$CTF" "$PROXY_FACTORY" "$SAFE_FACTORY")

# Check the exit status of the forge script command
if [ $? -ne 0 ]; then
    echo "--- DEPLOYMENT FAILED ---"
    # Print the full output (including error messages)
    echo "$OUTPUT"
    exit 1
fi

# --- RESULT PARSING ---

# Extract the deployed address using jq from the raw JSON output.
# Filtering through "grep {" is unnecessary as we expect JSON output.
EXCHANGE=$(echo "$OUTPUT" | jq -r '.returns.exchange.value')

if [ -z "$EXCHANGE" ]; then
    echo "Error: Failed to parse deployed exchange address from JSON output."
    echo "Full Forge Output:"
    echo "$OUTPUT"
    exit 1
fi

echo "--- DEPLOYMENT SUCCESS ---"
echo "Exchange deployed: $EXCHANGE"
echo "--- Complete! ---"
