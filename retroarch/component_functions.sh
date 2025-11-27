#!/bin/bash

retroarch_config="$XDG_CONFIG_HOME/retroarch/retroarch.cfg"
retroarch_config_core_options="$XDG_CONFIG_HOME/retroarch/retroarch-core-options.cfg"
retroarch_config_scummvm="$XDG_CONFIG_HOME/retroarch/system/scummvm.ini"
retroarch_cores_path="$XDG_CONFIG_HOME/retroarch/cores"
retroarch_extras_path="$rd_components/retroarch/rd_extras"
retroarch_rd_config_dir="$rd_components/retroarch/rd_config"

retroarch_updater() {
  # This function updates RetroArch by synchronizing shaders, cores, and border overlays.
  # It should be called whenever RetroArch is reset or updated.

  log i "Running RetroArch updater"

  log i "Updating cores..."
  tar -xzf "$retroarch_extras_path/cores.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/" --overwrite && log d "RetroArch cores updated correctly"

  log i "Updating overlays/borders..."
  create_dir -d "$XDG_CONFIG_HOME/retroarch/overlays"
  tar -xzf "$retroarch_extras_path/overlays.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/overlays" --overwrite && log d "RetroArch overlays and borders updated correctly"

  log i "Updating shaders..."
  create_dir -d "$XDG_CONFIG_HOME/retroarch/shaders"
  tar -xzf "$retroarch_extras_path/shaders.tar.gz" -C "$XDG_CONFIG_HOME/retroarch/shaders" --overwrite && log d "RetroArch shaders updated correctly"

  log i "Updating cheats..."
  create_dir -d "$cheats_path/retroarch"
  tar -xzf "$retroarch_extras_path/cheats.tar.gz" -C "$cheats_path/retroarch" --overwrite && log d "RetroArch cheats updated correctly"
}
