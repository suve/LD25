#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

CLEAN=0
DEBUG=0

while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--clean" ]]; then
		CLEAN=1
	elif [[ "$1" == "--debug" ]]; then
		DEBUG=1
	else
		echo "${SCRIPT_NAME}: Error! Unknown option \"${1}\"." >&2
		exit 1
	fi
	shift 1
done

# -- check env vars

if [[ -z "${ANDROID_NDK_ROOT+isset}" ]]; then
	echo "${SCRIPT_NAME}: Error! The \$ANDROID_NDK_ROOT variable is not set." >&2
	exit 1
fi

if [[ -z "${ANDROID_API+isset}" ]]; then
	echo "${SCRIPT_NAME}: Error! The \$ANDROID_API variable is not set." >&2
	exit 1
fi

# -- prepare the build directory

BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

# -- set up some debug/release values

if [[ "${DEBUG}" -eq 1 ]]; then
	OPT_OPTIM="debug"
	OPT_STRIP_MODE="none"
else
	OPT_OPTIM="release"
	OPT_STRIP_MODE="--strip-unneeded"
fi

function build_sdl2() {
	"${ANDROID_NDK_ROOT}/ndk-build" \
		NDK_MODULE_PATH="${SCRIPT_DIR}" \
		NDK_PROJECT_PATH=null \
		NDK_OUT="${BUILD_DIR}/obj" \
		NDK_LIBS_OUT="${BUILD_DIR}/lib" \
		APP_BUILD_SCRIPT=Android.mk \
		APP_ABI="armeabi-v7a arm64-v8a x86_64" \
		APP_PLATFORM="android-${ANDROID_API}" \
		APP_MODULES="SDL2 SDL2_main SDL2_mixer SDL2_image" \
		APP_OPTIM="${OPT_OPTIM}" \
		APP_STRIP_MODE="${OPT_STRIP_MODE}" \
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
		"-j$(nproc)" \
		"$@"
}

# -- clean, if requested

if [[ "${CLEAN}" -eq 1 ]]; then
	build_sdl2 clean
fi

# -- build the SDL2 libraries

build_sdl2
