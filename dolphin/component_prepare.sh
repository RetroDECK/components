#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  create_dir -d "$XDG_CONFIG_HOME/dolphin-emu/"
  cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/dolphin-emu/"
  set_setting_value "$dolphin_config" "BIOS" "$bios_path" "dolphin" "GBA"
  set_setting_value "$dolphin_config" "SavesPath" "$saves_path/gba" "dolphin" "GBA"
  set_setting_value "$dolphin_config" "ISOPath0" "$roms_path/wii" "dolphin" "General"
  set_setting_value "$dolphin_config" "ISOPath1" "$roms_path/gc" "dolphin" "General"
  set_setting_value "$dolphin_config" "WiiSDCardPath" "$saves_path/wii/dolphin/sd.raw" "dolphin" "General"
  dir_prep "$saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
  dir_prep "$saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA" # TODO: Multi-user one-off
  dir_prep "$saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
  dir_prep "$screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
  dir_prep "$states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
  dir_prep "$saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
  dir_prep "$mods_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
  dir_prep "$texture_packs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  dir_prep "$saves_path/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
  dir_prep "$saves_path/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
  dir_prep "$saves_path/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"
  dir_prep "$screenshots_path" "$XDG_DATA_HOME/dolphin-emu/ScreenShots"
  dir_prep "$states_path/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
  dir_prep "$saves_path/wii/dolphin" "$XDG_DATA_HOME/dolphin-emu/Wii"
  dir_prep "$mods_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
  dir_prep "$texture_packs_path/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"
  set_setting_value "$dolphin_config" "BIOS" "$bios_path" "dolphin" "GBA"
  set_setting_value "$dolphin_config" "SavesPath" "$saves_path/gba" "dolphin" "GBA"
  set_setting_value "$dolphin_config" "ISOPath0" "$roms_path/wii" "dolphin" "General"
  set_setting_value "$dolphin_config" "ISOPath1" "$roms_path/gc" "dolphin" "General"
  set_setting_value "$dolphin_config" "WiiSDCardPath" "$saves_path/wii/dolphin/sd.raw" "dolphin" "General"
fi
