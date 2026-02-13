#!/usr/bin/env bash
set -euo pipefail

if ! command -v forge >/dev/null 2>&1; then
  echo "forge is not installed. Install Foundry first: https://book.getfoundry.sh/getting-started/installation"
  exit 1
fi

echo "Forge version:"
forge --version

echo "Running tests..."
forge test -vvv
