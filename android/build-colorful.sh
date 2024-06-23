#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

# -- parse args

ARCH_ARM=""
ARCH_AARCH64=""
ARCH_X86=""
ARCH_X86_64=""

CLEAN=0
DEBUG="false"

while [[ "$#" -gt 0 ]]; do
	if [[ "$1" == "--arch" ]]; then
		if [[ "$#" -eq 1 ]]; then
			echo "${SCRIPT_NAME}: Error! The --arch option requires an argument." >&2
			exit 1
		fi
		if [[ "$2" == "arm" ]]; then
			ARCH_ARM=1
		elif [[ "$2" == "aarch64" ]]; then
			ARCH_AARCH64=1
		elif [[ "$2" == "x86" ]]; then
			ARCH_X86=1
		elif [[ "$2" == "x86_64" ]]; then
			ARCH_X86_64=1
		else
			echo "${SCRIPT_NAME}: Error! The argument to --arch must be one of 'arm', 'aarch64', 'x86' or 'x86_64' (got '${2}')" >&2
			exit 1
		fi
		shift 2
	elif [[ "$1" == "--clean" ]]; then
		CLEAN=1
		shift 1
	elif [[ "$1" == "--debug" ]]; then
		DEBUG="true"
		shift 1
	else
		echo "${SCRIPT_NAME}: Error! Unknown option \"${1}\"." >&2
		exit 1
	fi
done

# If user didn't specify any architectures, use default
if [[ -z "${ARCH_ARM}" ]] && [[ -z "${ARCH_AARCH64}" ]] && [[ -z "${ARCH_X86}" ]] && [[ -z "${ARCH_X86_64}" ]]; then
	ARCH_ARM=1
	ARCH_AARCH64=1
	ARCH_X86_64=1
fi

# -- prepare the build directory

BUILD_DIR="${SCRIPT_DIR}/../build"
mkdir -p "${BUILD_DIR}"

# -- clean, if requested

function cleanarch() {
	rm -f "${BUILD_DIR}/lib/${1}/libcolorful.so"
	rm -rf "${BUILD_DIR}/obj/local/${1}/objs/colorful/"
}

if [[ "${CLEAN}" -eq 1 ]]; then
	if [[ ! -z "${ARCH_ARM}" ]]; then
		cleanarch armeabi-v7a
	fi
	if [[ ! -z "${ARCH_AARCH64}" ]]; then
		cleanarch arm64-v8a
	fi
	if [[ ! -z "${ARCH_X86}" ]]; then
		cleanarch x86
	fi
	if [[ ! -z "${ARCH_X86_64}" ]]; then
		cleanarch x86_64
	fi
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

cd "${SCRIPT_DIR}/../"
if [[ ! -z "${ARCH_ARM}" ]]; then
	fpcbuild arm armeabi-v7a
fi
if [[ ! -z "${ARCH_AARCH64}" ]]; then
	fpcbuild aarch64 arm64-v8a
fi
if [[ ! -z "${ARCH_X86}" ]]; then
	fpcbuild i386 x86
fi
if [[ ! -z "${ARCH_X86_64}" ]]; then
	fpcbuild x86_64 x86_64
fi
