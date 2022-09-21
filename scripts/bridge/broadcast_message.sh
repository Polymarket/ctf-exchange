

RPC_URL="http://127.0.0.1:8545"
# anvil account number 9
WALLET_PRIVATE_KEY="0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
WALLET_ADDRESS="0xa0ee7a142d267c1f36714e4a8f75612f20a79720"

BROADCASTER_ADDRESS="0x2fb5e98f1efe95ae50f9becafce660701ad8d9be"

#  SEND_MESSAGE_TO_CHILD
forge script BridgeDeployment \
    --private-key $WALLET_PRIVATE_KEY \
    --rpc-url $RPC_URL \
    -s "sendMessageToChild(address,address)" $BROADCASTER_ADDRESS $WALLET_ADDRESS

echo "$OUTPUT"
DATA_HASH=$(echo "$OUTPUT" | grep "{" | jq -r .returns.dataHash.value)
echo "Message broadcasted with data hash $DATA_HASH"