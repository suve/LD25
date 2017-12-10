**Colorful**

A Ludum Dare 25 game

48h compo entry

Theme: You are the villain

__**POST-COMPO VERSION**__


Licensing
---------------------------
Colorful is subject to two different licences.

- Game code (found in the `src/` directory) is available under the terms of the
GNU General Public License, version 3, as published by the Free Software Foundation.
The full text of this licence is available in the LICENCE-CODE.txt file.

- Anything not covered by the point above is made available under the terms
of the "zlib with acknowledgement" license. The full text of this licence
is available in the LICENCE-ASSETS.txt file.


Language info
-----------------------
Language: Object Pascal

Recommended compiler: Free Pascal Compiler

The release versions (both Win32 and Linux) have been compiled 
using FPC 2.6.2, but I've been able to compile it with 2.4.4.

I haven't been really using any features new to the compiler,
so I think that even older versions should be able to build
the game quite eagerly.


Libraries used
----------------------
The game uses SDL2 (along with SDL2\_Image and SDL2\_Mixer) libraries
for event handling, gfx and sfx.

Simple DirectMedia Layer
https://libsdl.org


Getting the SDL2 headers
-----------------
Before you can build, you need to get a copy of Pascal SDL2 headers.
The recommended version to use are the [ev1313](https://github.com/ev1313/Pascal-SDL-2-Headers) headers,
although you're free to try compiling the game using any others.

The repo links to aforementioned headers by the means of a git submodule;
that means, if you don't wish to experiment and just want to get this compiled, simply do:

    $ git submodule init
    $ git submodule update

This should fetch the SDL2 headers for you.


Building instructions
-----------------
To build, use the standard make call.

    $ make \[debug|release|package\]

You can, alternatively, just point the compiler at the main source, although that's not
recommended, since the Makefile sets up some compiler options and compile-time symbols.

    $ fpc ld25.pas


Note that the configfiles.pas file holds some game constants (mostly
file paths) used to determine where to place config files. These
constants are, of course, platform specific and have been set ONLY
for Win32 and Linux. If you want to compile for another platform,
you'll have to meddle with the code a bit and add these constants for
your new platform. Or just remove the compiler directives and hard-code
them for your OS - whatever you find suitable.


Author's rambling
-------------------
No, I'm not joking. It's that dead-since-always language, Pascal.
Well actually, Pascal, despite not being to popular in business,
has quite a large userbase, so contrary to what many C-users might
be thinking, it's far from being dead.

Okay, enough ranting. The code, as you can expect from a game made
for a 48h compo, is quite crappy. Since this is a post-compo version,
some cleanup has been made, functions have been moved, comments have
added. But it's still far from being state-of-the-art, so don't
expect me to cover the damage if you hurt your eyes looking at it.

To find out exactly what can you do with the code, read the license. 
Basically you can whatever you want as long as you don't claim you
are the author and make an acknowledgement if using some part of this
stuff for your own purposes.

Other than that, feel free to read, observe, and despair. I mean, learn.
Like, you know, I made a game and you didn't, so you can learn from me.
Yeah.
