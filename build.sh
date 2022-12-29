#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

CLEAN=""
DEBUG=""

while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--clean" ]]; then
		CLEAN="--clean"
	elif [[ "$1" == "--debug" ]]; then
		DEBUG="--debug"
	else
		echo "${SCRIPT_NAME}: Error! Unknown option \"${1}\"." >&2
		exit 1
	fi
	shift 1
done

# -- check env vars

if [[ -z "${ANDROID_SDK_ROOT+isset}" ]]; then
	echo "${SCRIPT_NAME}: Error! The \$ANDROID_SDK_ROOT variable is not set." >&2
	exit 1
fi

if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo "${SCRIPT_NAME}: Error! The \$ANDROID_NDK_ROOT variable is not set." >&2
	exit 1
fi

if [[ -z "${ANDROID_API+isset}" ]]; then
	echo "${SCRIPT_NAME}: Error! The \$ANDROID_API variable is not set." >&2
	exit 1
fi

# -- call sub-scripts in order

cd "${SCRIPT_DIR}"
./build-SDL2.sh ${CLEAN} ${DEBUG}
./build-colorful.sh ${CLEAN} ${DEBUG}
./build-assets.sh ${CLEAN} ${DEBUG}
./build-apk.sh ${CLEAN} ${DEBUG}
