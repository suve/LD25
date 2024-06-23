# pl.suve.colorful.android

This directory contains scripts used to build Colorful for Android.


## Requirements

To build the game, you'll need the following:
- An [FPC](https://freepascal.org) cross-compiler for Android
- Android SDK
- Android NDK
- [optipng](https://optipng.sourceforge.net/) - for optimizing images
- [oggenc](https://github.com/xiph/vorbis-tools) - for encoding `.wav` sound effects to `.ogg`

For the FPC cross-compiler, you can use the container solutions found in the
[fpc-for-android](https://github.com/suve/fpc-for-android) repository.


## Environment

Before you can run the build, you need to set up some environment variables.
- `ANDROID_API` - the Android NDK API level you want to target.
  The recommended value is `21`.
- `ANDROID_SDK_ROOT` - the location of the Android SDK.
- `ANDROID_NDK_ROOT` - the location of the Android NDK.

If you're using the `fpc-for-android:cimg` container image,
all of the above will be already set up.


## Building

Once you took care of all the requirements, you can finally trigger the build.
The straightforward way is to call:

    $ ./build.sh

The build script can, optionally, the the following arguments:

* `--clean`    
  Forces removal of any old files before the build.

* `--debug`    
  Performs a debug build.

This main build script will call all the sub-scripts in proper order for you.
Unless you want to perform a partial build, there's no need to call the
individual sub-scripts manually. All the sub-scripts accept the `--clean`
and `--debug` options, as well.


### build-SDL2.sh

The `build-SDL2.sh` script, as can be guessed,
compiles the required SDL2 libraries for Android.


### build-colorful.sh

The `build-colorful.sh` script builds the game's code
as a shared library (`.so`) for Android.


### build-assets.sh

The `build-assets.sh` script builds the game's assets. This consists
mostly of re-encoding `.wav` files to `.ogg` and optimising other files.


### build-apk.sh

The `build-apk.sh` script takes the outputs of all the previous steps
and uses them to assemble an `.apk`.

