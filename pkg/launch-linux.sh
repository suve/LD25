#!/bin/sh

errmsg() {
	ZENITY="$(command -v zenity)"
	if [ ! -z "${ZENITY}" ]; then
		"${ZENITY}" --error --title="Colorful" --text="$1"
		exit
	fi

	KDIALOG="$(command -v kdialog)"
	if [ ! -z "${KDIALOG}" ]; then
		"${KDIALOG}" --title "Colorful" --error "$1"
		exit
	fi

	echo "$1" >&2
	exit
}


cd "$(dirname "$0")"

ARCH="$(uname -m)"
if [ "${ARCH}" = "x86_64" ] || [ "${ARCH}" = "x86-64" ] || [ "${ARCH}" = "x64" ] || [ "${ARCH}" = "amd64" ] || [ "${ARCH}" = "AMD64" ]; then
	LD_LIBRARY_PATH=./bin/linux64/  ./bin/linux64/colorful.elf  "$@"
	exit
fi

if [ "${ARCH}" = "i386" ] || [ "${ARCH}" = "i486" ] || [ "${ARCH}" = "i586" ] || [ "${ARCH}" = "i686" ]; then
	LD_LIBRARY_PATH=./bin/linux32/  ./bin/linux32/colorful.elf  "$@"
	exit
fi

errmsg "Sorry, but it appears your processor architecture is not supported."
