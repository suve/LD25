#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# -- prepare the build directory

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

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
		--debug=true \
		--android=true
	make executable
}

cd "${SCRIPT_DIR}/colorful"
fpcbuild arm armeabi-v7a
fpcbuild aarch64 arm64-v8a
fpcbuild x86_64 x86_64
