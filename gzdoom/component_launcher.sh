#!/bin/bash

RD_MODULES="/app/retrodeck/components"

LD_LIBRARY_PATH="$RD_MODULES/gzdoom/lib:${LD_LIBRARY_PATH}"
export DOOMWADDIR="$RD_MODULES/gzdoom/share/games/doom"

exec "$RD_MODULES/gzdoom/bin/gzdoom" +fluid_patchset "$RD_MODULES/gzdoom/share/games/doom/soundfonts/gzdoom.sf2" "$@"
