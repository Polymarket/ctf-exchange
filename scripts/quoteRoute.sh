#!/usr/bin/env bash

if [ -z $1 ] || [ -z $2 ]
then
  echo "usage: quoteRoute.sh INPUT_AMOUNT COLLATERAL_AMOUNT"
  exit 1
fi

INPUT_DATA_PATH=./tmp/quote_route_input_data
OUTPUT_DATA_PATH=./tmp/quote_route_output_data


# make the tmp folder if it doesnt exist
mkdir -p tmp

INPUT1=$1
HEX_INPUT1=$(cast --to-uint256 $INPUT1)
INPUT2=$2
HEX_INPUT2=$(cast --to-uint256 $INPUT2)
HEX_INPUT=$(cast --to-hexdata "$HEX_INPUT1":"$HEX_INPUT2")

echo -n $HEX_INPUT > ./tmp/quote_route_input_data

# parse logs from script
OUTPUT_REGEX='s/^.*== Logs ==\(.*\)$/\1/'

# run the script and suppress output
forge run ./src/scripts/quoteRoute.sol &> /dev/null

echo $(cast --to-dec $(cat $OUTPUT_DATA_PATH))