Description := Static runtime libraries for ARM

Configs := Release
Arch := arm

CC.Release := agcc.bash
CFLAGS.Release := -Wall -Werror -O3 -fomit-frame-pointer
FUNCTIONS.Release := $(CommonFunctions) $(ArchFunctions.arm)
OPTIMIZED.Release := 1
VISIBILITY_HIDDEN.Release := 0
