#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

ARCHES=""
CLEAN=""
DEBUG=""

while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--arch" ]]; then
		if [[ "$#" -eq 1 ]]; then
			echo "${SCRIPT_NAME}: Error! The --arch option requires an argument." >&2
			exit 1
		fi
		if [[ "$2" == "arm" ]] || [[ "$2" == "aarch64" ]] || [[ "$2" == "x86" ]] || [[ "$2" == "x86_64" ]]; then
			ARCHES="${ARCHES} --arch ${2}"
		else
			echo "${SCRIPT_NAME}: Error! The argument to --arch must be one of 'arm', 'aarch64', 'x86' or 'x86_64' (got '${2}')" >&2
			exit 1
		fi
		shift 2
	elif [[ "$1" == "--clean" ]]; then
		CLEAN="--clean"
		shift 1
	elif [[ "$1" == "--debug" ]]; then
		DEBUG="--debug"
		shift 1
	else
		echo "${SCRIPT_NAME}: Error! Unknown option \"${1}\"." >&2
		exit 1
	fi
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
./build-SDL2.sh ${ARCHES} ${CLEAN} ${DEBUG}
./build-colorful.sh ${ARCHES} ${CLEAN} ${DEBUG}
./build-assets.sh ${CLEAN} ${DEBUG}
./build-apk.sh ${CLEAN} ${DEBUG}
