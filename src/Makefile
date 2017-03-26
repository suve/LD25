# Compile-time warnings and hints, line info for debugging, basic optimisations
FLAGS_DEBUG   = -vewnh -gl -OG1

# Disable compile-time hints; enable level 3 optimisations; strip symbols
FLAGS_RELEASE = -vewn -Xs -XX -CX -OG3

# Disable compile-time hints; enable level 3 optimisations; include gdb debug symbols
# The gdb debug symbols are needed for generating a -debug package.
FLAGS_PACKAGE = -vewn -OG3 -g


.PHONY = debug release package clean


debug:
	fpc $(FLAGS_DEBUG)   -dDEVELOPER -o'colorful' ld25.pas

release:
	fpc $(FLAGS_RELEASE)             -o'colorful' ld25.pas

package:
	fpc $(FLAGS_PACKAGE) -dPACKAGE   -o'colorful' ld25.pas  

clean:
	rm *.o *.ppu *.a || echo 'Already clean!'
