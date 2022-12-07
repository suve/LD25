#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# -- build the game assets

cd "${SCRIPT_DIR}/colorful"
./configure.sh --android=true
make "-j$(nproc)" assets
