#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name "
  log i "----------------------"

  set_setting_value "$flycast_config" "Dreamcast.ContentPath" "$roms_path/dreamcast" "flycast"

fi

  dir_prep "$texture_packs_path/Flycast/TEXDUMP" "$XDG_CONFIG_HOME/Flycast/TEXDUMP"
  dir_prep "$texture_packs_path/Flycast/TEXTURES" "$XDG_CONFIG_HOME/Flycast/TEXTURES"

# Dreamcast.AutoLoadState = no, Dreamcast.AutoSaveState = no | add to autoresume
# rend.WideScreen = no, rend.WidescreenGameHacks = no | add to widescreen
