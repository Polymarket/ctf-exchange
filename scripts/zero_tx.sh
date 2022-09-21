#!

source .env

OUTPUT="$(forge script ZeroTx \
    --private-key $WALLET_PRIVATE_KEY \
    --rpc-url $RPC_URL_MUMBAI \
    --json \
    --with-gas-price 10000000000 \
    --broadcast
    )"

echo "$OUTPUT"