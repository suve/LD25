#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# -- check env vars

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
	echo "Error: The \$ANDROID_NDK_ROOT variable is not set!" >&2
	exit 1
fi

if [[ -z "${ANDROID_API}" ]]; then
	echo "Error: The \$ANDROID_API variable is not set!" >&2
	exit 1
fi

# -- perform the build

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

cd "${SCRIPT_DIR}"
"${ANDROID_NDK_ROOT}/ndk-build" \
	NDK_MODULE_PATH="${SCRIPT_DIR}" \
	NDK_PROJECT_PATH=null \
	NDK_OUT="${BUILD_DIR}/obj" \
	NDK_LIBS_OUT="${BUILD_DIR}/lib" \
    APP_BUILD_SCRIPT=Android.mk \
    APP_ABI="armeabi-v7a arm64-v8a x86_64" \
    APP_PLATFORM="android-${ANDROID_API}" \
    APP_MODULES="SDL2 SDL2_main SDL2_mixer" \
	SUPPORT_WAV=false \
	SUPPORT_DRFLAC=false \
	SUPPORT_FLAC_LIBFLAC=false \
	SUPPORT_OGG_STB=true \
	SUPPORT_OGG=false \
	SUPPORT_MP3_DRMP3=false \
	SUPPORT_MP3_MPG123=false \
	SUPPORT_MOD_XMP=false \
	SUPPORT_MID_TIMIDITY=false \
	"-j$(nproc)"

