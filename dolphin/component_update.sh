#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.3b") == "true" ]]; then
  # In version 0.6.3b, the following changes were made that required config file updates/reset:
  # - Put Dolphin and Primehack save states in different folders inside $rdhome/states

  dir_prep "$rdhome/states/dolphin" "$XDG_DATA_HOME/dolphin-emu/StateSaves"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Move Dolphin and Primehack save folder names
  # - Disable ask-on-exit in existing Citra / Dolphin / Duckstation / Primehack installs for proper preset functionality

  dir_prep "$mods_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/GraphicMods"
  dir_prep "$texture_packs_folder/Dolphin" "$XDG_DATA_HOME/dolphin-emu/Load/Textures"

  mv "$saves_folder/gc/dolphin/EUR" "$saves_folder/gc/dolphin/EU"
  mv "$saves_folder/gc/dolphin/USA" "$saves_folder/gc/dolphin/US"
  mv "$saves_folder/gc/dolphin/JAP" "$saves_folder/gc/dolphin/JP"
  dir_prep "$saves_folder/gc/dolphin/EU" "$XDG_DATA_HOME/dolphin-emu/GC/EUR"
  dir_prep "$saves_folder/gc/dolphin/US" "$XDG_DATA_HOME/dolphin-emu/GC/USA"
  dir_prep "$saves_folder/gc/dolphin/JP" "$XDG_DATA_HOME/dolphin-emu/GC/JAP"

  set_setting_value "$dolphinconf" "ConfirmStop" "False" "dolphin" "Interface"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the RetroAchievements for Dolphin..."
  cp -vn "$config/dolphin/"* "$XDG_CONFIG_HOME/dolphin-emu/"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then
  log i "Dolphin team suggest to run Dolphin in single core, setting it"
  set_setting_value "$dolphinconf" "CPUThread" "False" "dolphin" "Core"
  set_setting_value "$dolphinconf" "LanguageCode" " " "dolphin" "Interface"

fi

#######################################
# These actions happen at every update
#######################################

if [[ -d "$dolphin_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
  log i "Refreshing installed textures for Dolphin..."
  rsync -rlD --mkpath "/app/retrodeck/components/shared-data/DynamicInputTextures/" "$dolphin_dynamic_input_textures_path/" && log i "Done"
fi
