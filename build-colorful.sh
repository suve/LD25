#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

CLEAN=0
DEBUG="false"

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

# -- prepare the build directory

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

# -- clean, if requested

if [[ "${CLEAN}" -eq 1 ]]; then
	rm -f "${BUILD_DIR}/lib/"{armeabi-v7a,arm64-v8a,x86_64}/libcolorful.so
	rm -rf "${BUILD_DIR}/obj/local/"{armeabi-v7a,arm64-v8a,x86_64}/objs/colorful/
fi

# -- build the game .so

function fpcbuild() {
	local FPC_ARCH="$1"
	local NDK_ARCH="$2"

	mkdir -p "${BUILD_DIR}/obj/local/${NDK_ARCH}/objs/colorful/"

	./configure.sh \
		--flags="-P${FPC_ARCH}" \
		--flags="-Fl${BUILD_DIR}/lib/${NDK_ARCH}" \
		--flags="-FE${BUILD_DIR}/lib/${NDK_ARCH}" \
		--flags="-FU${BUILD_DIR}/obj/local/${NDK_ARCH}/objs/colorful/" \
		--debug="${DEBUG}" \
		--android=true
	make executable
}

cd "${SCRIPT_DIR}/colorful"
fpcbuild arm armeabi-v7a
fpcbuild aarch64 arm64-v8a
fpcbuild x86_64 x86_64
