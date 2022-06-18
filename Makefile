#########################################################################
#                                                                       #
# colorful - simple 2D sideview shooter                                 #
# Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek-Iwicki)           #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License, version 3,      #
# as published by the Free Software Foundation.                         #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                       #
#########################################################################
 
# Use a var for FPC to ease cross-compiling
FPC ?= fpc

# We need to set up SDL2 file location flags appropriately
FLAGS_SDL2 = -Fu./SDL2/units/

# Compile-time warnings and hints, line info for debugging, basic optimisations
FLAGS_DEBUG   = -vewnh -gl -OG1 -dDEVELOPER

# Disable compile-time hints; enable level 3 optimisations; strip symbols
FLAGS_RELEASE = -vewn -Xs -XX -CX -OG3

# Disable compile-time hints; enable level 3 optimisations; include gdb debug symbols
# The gdb debug symbols are needed for generating a -debug package.
FLAGS_PACKAGE = -vewn -OG3 -g -dPACKAGE


## -- End vars
## -- Start scanning for source files

SOURCES := $(filter-out '*ld25.pas', $(shell find src/ -name '*.{pas,inc}'))

GFX_SOURCES := $(shell find gfx/ -name '*.png')
GFX_TARGETS := $(GFX_SOURCES:gfx/%.png=build/gfx/%.png)

MAP_SOURCES := $(shell find map/ -name '*.txt')
MAP_TARGETS := $(MAP_SOURCES:map/%.txt=build/map/%.txt)

SFX_SOURCES := $(shell find sfx/ -name '*.wav')
SFX_TARGETS := $(SFX_SOURCES:sfx/%.wav=build/sfx/%.ogg)

SLIDE_SOURCES := $(shell find slides/ -name '*.png')
SLIDE_TARGETS := $(SLIDE_SOURCES:slides/%.png=build/slides/%.png)

## -- Start .PHONY targets

.PHONY = all-debug all-release all-package assets clean executable executable-debug executable-release executable-package help

all-debug: executable-debug assets

all-package: executable-package assets

all-release: executable-release assets

assets: $(GFX_TARGETS) $(MAP_TARGETS) $(SFX_TARGETS) $(SLIDE_TARGETS)

executable-debug:
	FPC_FLAGS="$(FLAGS_DEBUG)" make executable

executable-package:
	FPC_FLAGS="$(FLAGS_PACKAGE)" make executable

executable-release:
	FPC_FLAGS="$(FLAGS_RELEASE)" make executable

executable: build/colorful

clean:
	rm -rf build/

# -- End .PHONY targets

build/colorful: build/obj/colorful
	cp -a "$<" "$@"

build/gfx/%.png: gfx/%.png
	mkdir -p "$(dir $@)"
	optipng -clobber -out "$@" "$<" >/dev/null 2>/dev/null

build/map/%.txt: map/%.txt
	mkdir -p "$(dir $@)"
	sed -e 's|\r$$||g' -e 's|^[\t]*||g' -e 's| 0*\([0-9][0-9]*\)| \1|g' < "$<" > "$@"

build/sfx/%.ogg: sfx/%.wav
	mkdir -p "$(dir $@)"
	oggenc --quiet --quality=10 -o "$@" "$<"

build/slides/%.png: slides/%.png
	mkdir -p "$(dir $@)"
	optipng -clobber -out "$@" "$<" >/dev/null 2>/dev/null

build/obj/colorful: src/ld25.pas $(SOURCES)
	mkdir -p "$(dir $@)"
	$(FPC) $(FLAGS_SDL2) $(FPC_FLAGS) -o'$@' '$<'  
