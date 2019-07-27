#########################################################################
#                                                                       #
# colorful - simple 2D sideview shooter                                 #
# Copyright (C) 2012-2019 Artur "suve" Iwicki                           #
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
FLAGS_SDL2 = -Fu./SDL2/

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

SLIDE_SOURCES := $(shell find slides/ -name '*.png')
SLIDE_TARGETS := $(SLIDE_SOURCES:slides/%.png=build/slides/%.png)

SFX_SOURCES := $(shell find sfx/ -name '*.wav')
SFX_TARGETS := $(SFX_SOURCES:sfx/%.wav=build/sfx/%.ogg)

## -- Start .PHONY targets

.PHONY = assets clean executable executable-debug executable-release executable-package

assets: $(GFX_TARGETS) $(SLIDE_TARGETS) $(SFX_TARGETS)

executable-debug:
	FPC_FLAGS="$(FLAGS_DEBUG)" make executable

executable-release:
	FPC_FLAGS="$(FLAGS_RELEASE)" make executable

executable-package:
	FPC_FLAGS="$(FLAGS_PACKAGE)" make executable

executable: build/colorful

clean:
	rm -rf build/

# -- End .PHONY targets

build/colorful: build/obj/colorful
	cp -a "$<" "$@"

build/gfx/%.png: gfx/%.png
	mkdir -p "$(dir $@)"
	optipng -clobber -out "$@" "$<" >/dev/null 2>/dev/null

build/slides/%.png: slides/%.png
	mkdir -p "$(dir $@)"
	optipng -clobber -out "$@" "$<" >/dev/null 2>/dev/null

build/sfx/%.ogg: sfx/%.wav
	mkdir -p "$(dir $@)"
	oggenc --quiet --quality=10 -o "$@" "$<"

build/obj/colorful: src/ld25.pas $(SOURCES)
	mkdir -p "$(dir $@)"
	$(FPC) $(FLAGS_SDL2) $(FPC_FLAGS) -o'$@' '$<'  
