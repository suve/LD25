#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

CLEAN=0
DEBUG=false

while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--clean" ]]; then
		CLEAN=1
	elif [[ "$1" == "--debug" ]]; then
		DEBUG="true"
	else
		echo "${SCRIPT_NAME}: Error! Unknown option \"${1}\"." >&2
		exit 1
	fi
	shift 1
done

# -- clean up, if requested

if [[ "${CLEAN}" -eq 1 ]]; then
	rm -rf "${SCRIPT_DIR}"/../build/{gfx,map,sfx,slides}
fi

# -- build the game assets

cd "${SCRIPT_DIR}/../"
./configure.sh --android=true --debug="${DEBUG}"
make "-j$(nproc)" assets
