#!/bin/bash
#
# Helper script for building redistributable packages for colorful.
# The game will be built for the folowing four targets:
# - i386-linux
# - i386-win32
# - x86_64-linux
# - x86_64-win64
# Any required .dll / .so files will be bundled together with the executables,
# creating a fairly universal package.
#

VERSION="2.2"

# -- Set up error handling and paths

set -eu -o pipefail

cd "$(dirname "$0")"
cd ..

BUILD_DIR="$(pwd)/build/colorful-${VERSION}"

# -- Clean before starting anything

if [[ -d build/ ]]; then
	if [[ ! -f src/buildconfig.pas ]] || [[ ! -f Makefile ]]; then
		./configure.sh
	fi
	make clean
fi

# -- Build executables and copy .so / .dll files

function build_executable() {
	local dir="${BUILD_DIR}/bin/${1}"
	local suffix="$2"
	local flags="$3"

	./configure.sh --assets=bundle --debug=false --donate=true --flags="${flags}" --strip
	make executable

	mkdir -p "${dir}"
	mv build/colorful "${dir}/colorful${suffix}"
	copydeps --verbose "${dir}/colorful${suffix}"
}

build_executable "linux64" ".elf" "-Px86_64"
build_executable "linux32" ".elf" "-Pi386"

build_executable "win64" ".exe" "-Px86_64 -Twin64"
build_executable "win32" ".exe" "-Pi386 -Twin32"

# -- Build and copy assets

make -j assets
cp -t "${BUILD_DIR}" -a build/{gfx,map,sfx,slides}

# -- Copy misc stuff

cp -t "${BUILD_DIR}" -a \
	LICENCE-ASSETS.txt LICENCE-CODE.txt pkg/readme.txt \
	pkg/launch-linux.sh pkg/launch-windows.bat

# -- Zip it all up

pushd build
zip -9 "colorful-${VERSION}.zip" -r "colorful-${VERSION}/"
popd
