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

# -- prepare the build directory

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

# -- build the SDL2 libraries

cd "${SCRIPT_DIR}"

"${ANDROID_NDK_ROOT}/ndk-build" \
	NDK_MODULE_PATH="${SCRIPT_DIR}" \
	NDK_PROJECT_PATH=null \
	NDK_OUT="${BUILD_DIR}/obj" \
	NDK_LIBS_OUT="${BUILD_DIR}/lib" \
    APP_BUILD_SCRIPT=Android.mk \
    APP_ABI="armeabi-v7a arm64-v8a x86_64" \
    APP_PLATFORM="android-${ANDROID_API}" \
    APP_MODULES="SDL2 SDL2_main SDL2_mixer SDL2_image" \
	SUPPORT_WAV=false \
	SUPPORT_DRFLAC=false \
	SUPPORT_FLAC_LIBFLAC=false \
	SUPPORT_OGG_STB=true \
	SUPPORT_OGG=false \
	SUPPORT_MP3_DRMP3=false \
	SUPPORT_MP3_MPG123=false \
	SUPPORT_MOD_XMP=false \
	SUPPORT_MID_TIMIDITY=false \
	USE_STBIMAGE=true \
	SUPPORT_AVIF=false \
	SUPPORT_JPG=false \
	SUPPORT_JXL=false \
	SUPPORT_PNG=false \
	SUPPORT_WEBP=false \
	"-j$(nproc)"

# -- build the game executable

function fpcbuild() {
	local FPC_ARCH="$1"
	local NDK_ARCH="$2"

	fpc -Tandroid "-P${FPC_ARCH}" \
		"-Fl${SCRIPT_DIR}/build/lib/${NDK_ARCH}" \
		"-FE${SCRIPT_DIR}/build/lib/${NDK_ARCH}" \
		"-FU${SCRIPT_DIR}/build/obj/local/${NDK_ARCH}" \
		"-Fu${SCRIPT_DIR}/colorful/SDL2/units" \
		"${SCRIPT_DIR}/colorful/src/ld25.pas"
}

cd "${SCRIPT_DIR}/colorful"
fpcbuild arm armeabi-v7a
fpcbuild aarch64 arm64-v8a
fpcbuild x86_64 x86_64

