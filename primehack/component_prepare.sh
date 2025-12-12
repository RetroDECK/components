#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/primehack/"
  cp -fvr "$component_config/config/"* "$XDG_CONFIG_HOME/primehack/"
  set_setting_value "$primehack_config" "ISOPath0" "$roms_path/wii" "primehack" "General"
  set_setting_value "$primehack_config" "ISOPath1" "$roms_path/gc" "primehack" "General"
  dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
  dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
  dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
  dir_prep "$screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
  dir_prep "$states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
  dir_prep "$saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii"
  dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
  dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
  dir_prep "$shaders_path/Primehack" "$XDG_DATA_HOME/primehack/Shaders"
  dir_prep "$logs_path/Primehack" "$XDG_DATA_HOME/primehack/Logs"
  dir_prep "$storage_path/Primehack/Dump" "$XDG_DATA_HOME/Primehack/Dump"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
  dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
  dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"
  dir_prep "$screenshots_path" "$XDG_DATA_HOME/primehack/ScreenShots"
  dir_prep "$states_path/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
  dir_prep "$saves_path/wii/primehack" "$XDG_DATA_HOME/primehack/Wii/"
  dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
  dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"
  dir_prep "$shaders_path/Primehack" "$XDG_DATA_HOME/primehack/Shaders"
  dir_prep "$logs_path/Primehack" "$XDG_DATA_HOME/primehack/Logs"
  dir_prep "$storage_path/Primehack/Dump" "$XDG_DATA_HOME/Primehack/Dump"
  set_setting_value "$primehack_config" "ISOPath0" "$roms_path/gc" "primehack" "General"
fi
