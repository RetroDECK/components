#!/bin/bash

retroarch_updater() {
    # This function updates RetroArch by synchronizing shaders, cores, and border overlays.
    # It should be called whenever RetroArch is reset or updated.

    log i "Running RetroArch updater"

    log i "Updating cores..."
    tar -xzf "$extras/cores.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch cores updated correctly"

    log i "Updating overlays/borders..."
    tar -xzf "$extras/overlays.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch overlays and borders updated correctly"

    log i "Updating shaders..."
    tar -xzf "$extras/shaders.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch shaders updated correctly"

    log i "Updating cheats..."
    tar -xzf "$extras/cheats.tar.gz" -C "$rd_home_cheats_path/retroarch" --overwrite && log d "RetroArch cheats updated correctly"

}