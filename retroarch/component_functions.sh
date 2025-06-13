#!/bin/bash

retroarch_updater() {
    # This function updates RetroArch by synchronizing shaders, cores, and border overlays.
    # It should be called whenever RetroArch is reset or updated.

    log i "Running RetroArch updater"

    log i "Updating cores..."
    tar --strip-components=1 -xzf "$extras/cores.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch cores updated correctly"

    log i "Updating overlays/borders..."
    tar --strip-components=1 -xzf "$extras/overlays.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch overlays and borders updated correctly"

    log i "Updating cheats..."
    tar --strip-components=1 -xzf "$extras/cheats.tar.gz" -C "$cheats_folder/retroarch" --overwrite

    log i "Updating shaders..."
    tar --strip-components=1 -xzf "$extras/shaders.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite

}