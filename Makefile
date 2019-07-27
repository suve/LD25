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
FLAGS_DEBUG   = -vewnh -gl -OG1

# Disable compile-time hints; enable level 3 optimisations; strip symbols
FLAGS_RELEASE = -vewn -Xs -XX -CX -OG3

# Disable compile-time hints; enable level 3 optimisations; include gdb debug symbols
# The gdb debug symbols are needed for generating a -debug package.
FLAGS_PACKAGE = -vewn -OG3 -g


.PHONY = debug release package clean


debug:
	mkdir -p build/obj/
	$(FPC) $(FLAGS_SDL2) $(FLAGS_DEBUG)   -dDEVELOPER -o'build/obj/colorful' src/ld25.pas
	cp -a build/obj/colorful build/

release:
	mkdir -p build/obj/
	$(FPC) $(FLAGS_SDL2) $(FLAGS_RELEASE)             -o'build/obj/colorful' src/ld25.pas
	cp -a build/obj/colorful build/

package:
	mkdir -p build/obj/
	$(FPC) $(FLAGS_SDL2) $(FLAGS_PACKAGE) -dPACKAGE   -o'build/obj/colorful' src/ld25.pas  
	cp -a build/obj/colorful build/

clean:
	rm -rf build/
