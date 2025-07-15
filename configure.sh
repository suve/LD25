#!/bin/sh
#
# colorful - simple 2D sideview shooter
# Copyright (C) 2022-2024 suve (a.k.a. Artur Frenszek-Iwicki)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 3,
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -eu

show_help() {
	cat <<EOF
configure.sh for colorful
Accepted options:

--android BOOLEAN
  Controls whether Android-specific build settings are enabled.
  The default value is "false".

--assets <bundle, standalone, systemwide>
  Specifies where the game should expect asset files to be located.
  * bundle: Assets are expected to be found two directory levels
            above the executable, like in the following structure:
            - bin/linux64
            - bin/win64
            - gfx/
  * standalone: Assets are expected to be found in the same directory,
                right next to the executable.
  * systemwide: Assets are expected to be found in
                \${PREFIX}/share/suve/colorful.
  The default value is "standalone".
  This setting is ignored in Android builds.

--compat <auto, v1, v2>
  Controls whether the game should be built with compatibility for old config
  files and savegames. This means that users upgrading from an old version
  of the game will have their settings and savegames preserved.
  * v1: Include compat code for v1 files.
  * v2: Support only v2 files.
  The default value for this option is "auto", which resolves to "v2"
  for Android builds and "v1" otherwise.

--debug BOOLEAN
  Controls whether debugging features are enabled.
  The default value is "false".

--donate BOOLEAN
  Controls whether the "Donate" option appears in the main menu.
  The default value is "true".

--fpc FULL_PATH
  Use the Free Pascal Compiler located at FULL_PATH.
  The default is to use "fpc".

--flags FLAGS
  Pass FLAGS to fpc. Can be specified multiple times.

--ogg-quality QUALITY
  Encode sound effects to .ogg with this quality setting.
  The default value is "10".

--platform <auto, desktop, mobile>
  Controls whether the game should be built in desktop mode (keyboard focus,
  no touch controls) or mobile mode (touch, extra menus for accessibility).
  The default value is "auto", which resolves to "mobile" for Android builds
  and "desktop" otherwise.

--prefix PREFIX
  Controls the prefix used when installing the app and - if built with
  "assets" set to "systemwide" - when loading assets.
  The default value is "/usr/local".

--strip BOOLEAN
  Controls whether the built executable should be stripped of debug symbols.
  The default value is "false".

Option syntax is "--option=value". "--option" "value" will not work.
For BOOLEAN options, the value can be omitted; it will be treated as \"true\".
EOF
}

# Helper functions

parse_bool() {
	flag="${1}"
	value="${2}"

	if [ -z "${value}" ] || [ "${value}" = "true" ] || [ "${value}" = "yes" ] || [ "${value}" = "1" ]; then
		echo "true"
	elif [ "${value}" = "false" ] || [ "${value}" = "no" ] || [ "${value}" = "0" ]; then
		echo "false"
	else
		echo "Error: The argument to ${flag} must be one of \"true\", \"yes\", \"1\", \"false\", \"no\", or \"0\"" >&2
		exit 1
	fi
}

# Set defaults

ANDROID="false"
ASSETS="standalone"
COMPAT="auto"
DEBUG="false"
DONATE="true"
FPC="fpc"
USER_FLAGS=""
OGG_QUALITY="10"
PLATFORM="auto"
PREFIX="/usr/local"
STRIP="false"

while [ "${#}" -gt 0 ]; do
	if [ "${1}" = "--help" ]; then
		show_help
		exit
	fi

	opt="${1%%=*}"
	val="${1#*=}"
	if [ "${val}" = "${1}" ]; then
		val=""
	fi
	shift

	if [ "${opt}" = "--android" ]; then
		ANDROID="$(parse_bool "--android" "${val}")"
	elif [ "${opt}" = "--assets" ]; then
		if [ "${val}" != "bundle" ] && [ "${val}" != "standalone" ] && [ "${val}" != "systemwide" ]; then
			echo "Error: The argument to --assets must be one of \"bundle\", \"standalone\", or \"systemwide\"" >&2
			exit 1
		fi
		ASSETS="${val}"
	elif [ "${opt}" = "--compat" ]; then
		if [ "${val}" != "auto" ] && [ "${val}" != "v1" ] && [ "${val}" != "v2" ]; then
			echo "Error: The argument to --compat must be one of \"auto\", \"v1\" or \"v2\"" >&2
			exit 1
		fi
		COMPAT="${val}"
	elif [ "${opt}" = "--debug" ]; then
		DEBUG="$(parse_bool "--debug" "${val}")"
	elif [ "${opt}" = "--donate" ]; then
		DONATE="$(parse_bool "--donate" "${val}")"
	elif [ "${opt}" = "--fpc" ]; then
		FPC="${val}"
	elif [ "${opt}" = "--flags" ]; then
		USER_FLAGS="${USER_FLAGS} ${val}"
	elif [ "${opt}" = "--ogg-quality" ]; then
		OGG_QUALITY="${val}"
	elif [ "${opt}" = "--platform" ]; then
		if [ "${val}" != "auto" ] && [ "${val}" != "desktop" ] && [ "${val}" != "mobile" ]; then
			echo "Error: The argument to --platform must be one of \"auto\", \"desktop\", or \"mobile\"" >&2
			exit 1
		fi
		PLATFORM="${val}"
	elif [ "${opt}" = "--prefix" ]; then
		PREFIX="${val}"
	elif [ "${opt}" = "--strip" ]; then
		STRIP="$(parse_bool "--strip" "${val}")"
	else
		echo "Unknown option \"${opt}\"" >&2
		exit 1
	fi
done

# Resolve "auto" values

if [ "${COMPAT}" = "auto" ]; then
	if [ "${ANDROID}" = "true" ]; then
		COMPAT="v2"
	else
		COMPAT="v1"
	fi
fi
if [ "${PLATFORM}" = "auto" ]; then
	if [ "${ANDROID}" = "true" ]; then
		PLATFORM="mobile"
	else
		PLATFORM="desktop"
	fi
fi

# Print out used values

cat <<EOF
Config values:
  ANDROID = ${ANDROID}
  ASSETS = ${ASSETS}
  COMPAT = ${COMPAT}
  DEBUG = ${DEBUG}
  DONATE = ${DONATE}
  FPC = ${FPC}
  FLAGS =${USER_FLAGS}
  OGG_QUALITY = ${OGG_QUALITY}
  PLATFORM = ${PLATFORM}
  PREFIX = ${PREFIX}
  STRIP = ${STRIP}
EOF

# Calculate src/buildconfig.pas variables

pascal_string() {
	input_str="${1}"

	output_str="''"
	open_apos=0
	while [ -n "${input_str}" ]; do
		letter="$(echo "${input_str}" | cut -b1)"
		input_str="$(echo "${input_str}" | cut -b2-)"

		letter_ord="$(printf "%d" "'${letter}")"
		if [ "${letter_ord}" -ge 32 ] && [ "${letter_ord}" -le 126 ]; then
			if [ "${letter}" != "'" ]; then
				if [ "${open_apos}" = "0" ]; then
					output_str="${output_str} + '"
					open_apos=1
				fi
				output_str="${output_str}${letter}"
			else
				if [ "${open_apos}" = "0" ]; then
					output_str="${output_str} + #39"
				else
					output_str="${output_str}''"
				fi
			fi
		else
			if [ "${open_apos}" = "1" ]; then
				output_str="${output_str}'"
				open_apos=0
			fi
			output_str="${output_str} + #${letter_ord}"
		fi
	done

	if [ "${open_apos}" = "0" ]; then
		echo "${output_str}"
	else
		echo "${output_str}'"
	fi
}

PAS_PREFIX="$(pascal_string "${PREFIX}")"

# Calculate Makefile variables from arguments

BUILD_FLAGS="-vewnh -dLD25_ASSETS_${ASSETS}"
GFX_FILTER=""

if [ "${ANDROID}" = "true" ]; then
	EXE_PREFIX="lib"
	EXE_SUFFIX=".so"
	BUILD_FLAGS="-Tandroid ${BUILD_FLAGS}"
	GFX_FILTER="gfx/toasts.png ${GFX_FILTER}"
else
	EXE_PREFIX=""
	EXE_SUFFIX=""
fi

if [ "${COMPAT}" = "v1" ]; then
	BUILD_FLAGS="${BUILD_FLAGS} -dLD25_COMPAT_V1"
fi

if [ "${DEBUG}" = "true" ]; then
	# Note: No -O1/-O2/-O3/-O4 flag - no optimisations!
	BUILD_FLAGS="${BUILD_FLAGS} -dLD25_DEBUG"
else
	BUILD_FLAGS="${BUILD_FLAGS} -O3"
fi

if [ "${DONATE}" = "true" ]; then
	BUILD_FLAGS="${BUILD_FLAGS} -dLD25_DONATE"
fi

if [ "${PLATFORM}" = "mobile" ]; then
	BUILD_FLAGS="${BUILD_FLAGS} -dLD25_MOBILE"
	PLATFORM_GOOD="mobile"
	PLATFORM_BAD="desktop"
else
	GFX_FILTER="gfx/touch-controls.png ${GFX_FILTER}"
	PLATFORM_GOOD="desktop"
	PLATFORM_BAD="mobile"
fi

if [ "${STRIP}" = "true" ]; then
	BUILD_FLAGS="${BUILD_FLAGS} -CX -XX -Xs"
else
	BUILD_FLAGS="${BUILD_FLAGS} -gl -gw"
fi

FPC_FLAGS="${BUILD_FLAGS}${USER_FLAGS}"

# cd to this script's directory and create src/buildconfig.pas and the Makefile
cd "$(dirname "${0}")"

GENERATED_DATE="$(date '+%Y-%m-%dT%H:%M:%S%z')"

echo 'Generating src/buildconfig.pas...'

{ cat <<EOF
// !
// ! This file has been generated by "configure.sh".
// ! Do not edit manually.
// !
// ! Generated on: ${GENERATED_DATE}
// !
Unit BuildConfig;

Interface

Const
	Prefix = ${PAS_PREFIX};

Implementation

End.
EOF
} > src/buildconfig.pas

echo 'Generating Makefile...'

{ cat <<EOF
# !
# ! This file has been generated by "configure.sh".
# ! Do not edit manually.
# !
# ! Generated on: ${GENERATED_DATE}
# !

EXE_PREFIX := ${EXE_PREFIX}
EXE_SUFFIX := ${EXE_SUFFIX}
FPC := ${FPC}
FPC_FLAGS := ${FPC_FLAGS}
GFX_FILTER := ${GFX_FILTER}
PLATFORM_GOOD := ${PLATFORM_GOOD}
PLATFORM_BAD := ${PLATFORM_BAD}
PREFIX := ${PREFIX}
OGG_QUALITY := ${OGG_QUALITY}

EOF
} | cat - Makefile.in > Makefile

echo 'Done.'
