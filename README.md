**Colorful**

A Ludum Dare 25 game

48h compo entry

Theme: You are the villain

__**POST-COMPO VERSION**__


Licensing
---------------------------
Colorful is released under the "zlib with acknowledgement" license.

The full text of the license can be found in the LICENSE.txt file.


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
The game uses SDL (along with SDL_image and SDL_mixer) libraries
for event handling, gfx and sfx; and the Sour lib.

Simple DirectMedia Layer
http://libsdl.org

Sour is my own handiwork and can be downloaded from my site. A copy is also bundled with those GitHub sources.


Building instructions
-----------------
Since version 2.2.2, FPC comes with most of the SDL units included.
You could, alternatively, get a copy from http://delphi-jedi.org.

Sour is bundled with the Colorful source.
You could, alternatively, get a copy from my homepage.

To build, just compile the main source.
    
    $ fpc ld25.pas

You can also use the makefile, which sets up some additional compile flags.
    
    $ make

Note that the configfiles.pas file holds some game constants (mostly
file paths) used to determine where to place config files. These
constants are, of course, platform specific and have been set ONLY
for Win32 and Linux. If you want to compile for another platform,
you'll have to meddle with the code a bit and add these constants for
your new platform. Or just remove the compiler directives and hard-code
them for your OS - whatever you find suitable.

Also, note that, by default, on Linux, SDL_mixer links and depends on
smpeg for MP3 support. Since Colorful does not use MP3s, and less 
dependencies is better, my releases are compiled using a slightly 
altered version of SDL_mixer.pas, disabling the smpeg capabilities.
This version is also bundled with the GitHub sources.


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
