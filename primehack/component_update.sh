#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.2b") == "true" ]]; then
  # In version 0.6.2b, the following changes were made that required config file updates/reset:
  # - Primehack preconfiguration completely redone. "Stop emulation" hotkey set to Start+Select, Xbox and Nintendo keymap profiles were created, Xbox set as default.

  rm -rf "$XDG_CONFIG_HOME/primehack" # Purge old Primehack config files. Saves are safe as they are linked into $XDG_DATA_HOME/primehack.
  prepare_component "reset" "primehack"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.3b") == "true" ]]; then
  # In version 0.6.3b, the following changes were made that required config file updates/reset:
  # - Put Dolphin and Primehack save states in different folders inside $rdhome/states

  dir_prep "$rdhome/states/primehack" "$XDG_DATA_HOME/primehack/StateSaves"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Move Dolphin and Primehack save folder names
  # - Disable ask-on-exit in existing Citra / Dolphin / Duckstation / Primehack installs for proper preset functionality

  dir_prep "$mods_path/Primehack" "$XDG_DATA_HOME/primehack/Load/GraphicMods"
  dir_prep "$texture_packs_path/Primehack" "$XDG_DATA_HOME/primehack/Load/Textures"

  mv "$saves_path/gc/primehack/EUR" "$saves_path/gc/primehack/EU"
  mv "$saves_path/gc/primehack/USA" "$saves_path/gc/primehack/US"
  mv "$saves_path/gc/primehack/JAP" "$saves_path/gc/primehack/JP"
  dir_prep "$saves_path/gc/primehack/EU" "$XDG_DATA_HOME/primehack/GC/EUR"
  dir_prep "$saves_path/gc/primehack/US" "$XDG_DATA_HOME/primehack/GC/USA"
  dir_prep "$saves_path/gc/primehack/JP" "$XDG_DATA_HOME/primehack/GC/JAP"

  set_setting_value "$primehackconf" "ConfirmStop" "False" "primehack" "Interface"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then

  log i "0.10.0b Upgrade - Postmove: PrimeHack"

  set_setting_value "$primehack_config" "CPUThread" "False" "primehack" "Core"
  set_setting_value "$primehack_config" "LanguageCode" " " "primehack" "Interface"
  prepare_component "postmove" "primehack"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.2b") == "true" ]]; then

  log i "0.10.2b Upgrade - Postmove: PrimeHack"

  set_setting_value "$primehack_config" "SIDevice0" "0" "primehack" "Core"
  rsync -rlD --mkpath "$primehack_rd_config_dir/config/Profiles/Wiimote/" "$XDG_CONFIG_HOME/primehack/Profiles/Wiimote/"
fi

#######################################
# These actions happen at every update
#######################################

if [[ -d "$primehack_dynamic_input_textures_path" ]]; then # Refresh installed textures if they have been enabled
  log i "Refreshing installed textures for Primehack..."
  rsync -rlD --mkpath "/app/retrodeck/components/shared-data/DynamicInputTextures/" "$primehack_dynamic_input_textures_path/" && log i "Done"
fi
