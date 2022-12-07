#!/bin/bash

set -eu -o pipefail

# -- cd to script dir so we're in a known location

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# -- check env vars

if [[ -z "${ANDROID_SDK_ROOT+isset}" ]]; then
	echo "Error: The \$ANDROID_SDK_ROOT variable is not set!" >&2
	exit 1
fi

# -- create symlinks to hook up required files

mkdir -p android/app/src/main/assets
for TYPE in gfx sfx map slides; do
	ln -srf "colorful/build/${TYPE}" "android/app/src/main/assets/${TYPE}"
done

ln -srf SDL2/android-project/app/src/main/java/org \
	android/app/src/main/java/org
ln -srf build/lib \
	android/app/src/main/jniLibs

# -- trigger a Gradle build

cd "${SCRIPT_DIR}/android"
./gradlew
./gradlew build
