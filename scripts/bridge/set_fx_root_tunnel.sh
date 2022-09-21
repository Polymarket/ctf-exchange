#!

source .env
BROADCASTER_ADDRESS=$(cat deploy/addresses.json | jq -j .BroadcasterGoerli)
RECEIVER_ADDRESS=$(cat deploy/addresses.json | jq -j .ReceiverMumbai)


OUTPUT="$(forge script SetFxRootTunnel \
    --private-key $WALLET_PRIVATE_KEY \
    --rpc-url $RPC_URL_MUMBAI \
    --json \
    --broadcast \
    --with-gas-price 10000000000 \
    -s "run(address,address)" $RECEIVER_ADDRESS $BROADCASTER_ADDRESS)"
echo $OUTPUT