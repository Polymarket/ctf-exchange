#!/usr/bin/env bash

# compute the decimal string
parsed=$(bc -l <<< "$1/2^96")

# convert to hex
hexed=$(xxd -p <<< x$parsed)

echo $hexed