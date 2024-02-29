# Colorful

Colorful is a simple 2D side-shooter game, originally created in 48 hours
for the [Ludum Dare](https://ldjam.com) event, 25th edition (December 2012).

This is the "post-compo" version of the game - it has received numerous
enhancements and bug fixes.

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/pl.suve.colorful.android/)

Or download the latest version from the [Releases Section](https://github.com/suve/LD25/releases/latest).

## Building the game

To build Colorful, you'll need the following dependencies:

- [Free Pascal Compiler](https://freepascal.org)
- [Make](https://www.gnu.org/software/make/)
- [optipng](https://optipng.sourceforge.net/) - for optimizing images
- [oggenc](https://github.com/xiph/vorbis-tools) - for encoding `.wav` sound effects to `.ogg`
- [SDL libraries](https://libsdl.org): SDL2, SDL2\_image, SDL2\_mixer
- Pascal units for SDL2


### Getting the SDL2 units

Before you can build, you need to get a copy of Pascal SDL2 units.
The recommended version to use can be found in the
[PGD SDL2-For-Pascal](https://github.com/PascalGameDevelopment/SDL2-for-Pascal)
repository, although you're free to try compiling the game using any others.

The repo links to aforementioned headers by the means of a git submodule,
so if you don't want to experiment, run the following commands:

    $ git submodule init
    $ git submodule update

This should fetch the SDL2 headers for you.


### Configuring the build

The build process includes a custom configuration script,
which can be used to tailor the build process to your needs.
The script takes the following options:

- `--android`    
  Controls whether Android-specific build settings are enabled.
  The default value is `false`.

- `--assets <bundle, standalone, systemwide>`    
  Specifies where the game should expect asset files to be located.
  * `bundle`: Assets are expected to be found two directory levels
    above the executable, like in the following structure:
    - bin/linux64
    - bin/win64
    - gfx/
  * `standalone`: Assets are expected to be found in the same directory,
    right next to the executable.
  * `systemwide`: Assets are expected to be found
  in `/usr/share/suve/colorful`.

  The default value is `standalone`.

- `--debug`    
  Controls whether debugging features are enabled.
  The default value is `false`.

- `--donate`    
  Controls whether the "Donate" option appears in the main menu.
  The default value is `true`.

- `--fpc PATH`    
  Use the Free Pascal Compiler located at `PATH`.
  The default is to use `fpc`.

- `--flags FLAGS`    
  Pass `FLAGS` to fpc. Can be specified multiple times.

- `--ogg-quality QUALITY`    
  Encode sound effects to `.ogg` with this quality setting.
  The default value is `10`.

- `--platform <auto, desktop, mobile>`    
  Controls whether the game should be built in desktop mode (keyboard focus,
  no touch controls) or mobile mode (touch, extra menus for accessibility).
  The default value is `auto`, which resolves to `mobile` when building
  for Android, and `desktop` otherwise.

- `--strip`    
  Controls whether the built executable should be stripped of debug symbols.
  The default value is `false`.

The option syntax is `--option=value`.
Passing `--option value` will result in an error.
For boolean options, the value can be omitted; it will be treated as `true`.

The script generates a Makefile, so once you've configured everything
to your liking (or just decided to go with the defaults), you can build
the game through the usual method:

    $ make all


### Installing the game

If you set `assets` to `standalone` (the default value) during the
configuration phase, the game is ready to go. You can launch the executable
found at `build/colorful` and enjoy yourself. Since the game stores
its configuration file and savestates inside the user's home directory,
it should continue to work even if moved to a non-writeable location.

If you're trying to package the game for Linux, go back and ensure you've
configured `assets` to `systemwide`. If everything checks out, you can
go ahead and use the `install` target defined in the Makefile.

    $ make install [DESTDIR=]

Note that, currently, there is no support for specifying the installation prefix;
it is hard-coded to `/usr`.


## Building for Android

Android is a bit of a tough cookie.
You can find all the extra code (Java/JNI glue, manifests, etc.)
and build scripts in the
[pl.suve.colorful.android](https://github.com/suve/pl.suve.colorful.android)
repository.


## Licensing

Colorful is subject to two different licences.

- Game code (found in the `src/` directory) is available under the terms of the
GNU General Public License, version 3, as published by the Free Software Foundation.
The full text of this licence is available in the LICENCE-CODE.txt file.

- Anything not covered by the point above is made available under the terms
of the "zlib with acknowledgement" licence. The full text of this licence
is available in the LICENCE-ASSETS.txt file.


## Random rambling

The code, as you can expect from a game made for a 48h compo, is quite crappy.
Since this is a post-compo version, some cleanup has been made,
functions have been moved, comments have been added.
But it's still far from being state-of-the-art, so don't
expect me to cover the damage if you hurt your eyes looking at it.

While getting the game to compile for Android was fairly easy, making it run
in a sensible matter was a whole other issue. As such, the code is riddled
with Android-specific quirks and workarounds. Some of these should be fairly
obvious in what they do, but some are quite literally workarounds for
behaviour I didn't bother to properly diagnose.

So anyway, feel free to read, observe, and despair. I mean, learn.
Like, you know, I made a game and you didn't, so you can learn from me.
Yeah.
