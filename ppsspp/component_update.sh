#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Move PPSSPP saves/states to appropriate folders

  dir_prep "$saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
  dir_prep "$states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"

  set_setting_value "$ppssppconf" "AutoLoadSaveState" "0" "ppsspp" "General"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.1b") == "true" ]]; then
  # In version 0.7.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Force update PPSSPP standalone keybinds for L/R.
  set_setting_value "$ppssppcontrolsconf" "L" "1-45,10-193" "ppsspp" "ControlMapping"
  set_setting_value "$ppssppcontrolsconf" "R" "1-51,10-192" "ppsspp" "ControlMapping"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the cheats for PPSSPP-SA..."
  create_dir -d "$cheats_path/PPSSPP"
  dir_prep "$cheats_path/PPSSPP" "$ppsspp_cheats_path"
  tar -xzf "/app/retrodeck/cheats/ppsspp.tar.gz" -C "$cheats_path/PPSSPP" --overwrite && log i "Cheats for PPSSPP installed"

  set_setting_value "$rd_conf" "ppsspp" "$(get_setting_value "$rd_defaults" "ppsspp" "retrodeck" "cheevos")" "retrodeck" "cheevos"
  set_setting_value "$rd_conf" "ppsspp" "$(get_setting_value "$rd_defaults" "ppsspp" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then

  log i "0.10.0b Upgrade - Postmove: PPSSPP"

  prepare_component "postmove" "ppsspp"

  unzip -q -o -j "$component_extras/CWCheat-Database-Plus--master.zip" "*/cheat.db" -d "$cheats_path/PPSSPP"
fi
