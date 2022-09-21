#!

source .env
RECEIVER_ADDRESS=$(cat deploy/addresses.json | jq -j .ReceiverMumbai)
echo "receiver: $RECEIVER_ADDRESS"
OUTPUT="$(forge script --rpc-url $RPC_URL_MUMBAI --json IsExectuableMessage -s "run(address)" $RECEIVER_ADDRESS)"
echo $(echo "$OUTPUT" | grep "{" | jq -j .returns.isExecutable.value)
