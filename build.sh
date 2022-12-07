#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# -- check env vars

if [[ -z "${ANDROID_SDK_ROOT+isset}" ]]; then
	echo "Error: The \$ANDROID_SDK_ROOT variable is not set!" >&2
	exit 1
fi

if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo "Error: The \$ANDROID_NDK_ROOT variable is not set!" >&2
	exit 1
fi

if [[ -z "${ANDROID_API+isset}" ]]; then
	echo "Error: The \$ANDROID_API variable is not set!" >&2
	exit 1
fi

# -- call sub-scripts in order

cd "${SCRIPT_DIR}"
./build-SDL2.sh
./build-colorful.sh
./build-assets.sh
./build-apk.sh
