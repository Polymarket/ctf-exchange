#!

source .env
BROADCASTER_ADDRESS=$(cat deploy/addresses.json | jq -j .BroadcasterGoerli)
echo "broadcaster: $BROADCASTER_ADDRESS"
OUTPUT="$(forge script BroadcasterSendMessageToChild \
    --private-key $WALLET_PRIVATE_KEY \
    --rpc-url $RPC_URL_GOERLI \
    --json \
    --broadcast \
    -s "run(address)" $BROADCASTER_ADDRESS)"
echo $OUTPUT