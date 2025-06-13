#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Prepearing CEMU"
  log i "----------------------"
  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
    create_dir -d "$multi_user_data_folder/$SteamAppUser/config/Cemu"
    cp -fr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/Cemu/"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "mlc_path" "$bios_folder/cemu" "cemu"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
    dir_prep "$multi_user_data_folder/$SteamAppUser/config/Cemu" "$XDG_CONFIG_HOME/Cemu"
  else
    create_dir -d "$XDG_CONFIG_HOME/Cemu/"
    cp -fr "$config/"* "$XDG_CONFIG_HOME/Cemu/"
    set_setting_value "$cemuconf" "mlc_path" "$bios_folder/cemu" "cemu"
    set_setting_value "$cemuconf" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
    if [[ -e "$bios_folder/cemu/keys.txt" ]]; then
      rm -rf "$XDG_DATA_HOME/Cemu/keys.txt" && ln -s "$bios_folder/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt" && log d "Linked $bios_folder/cemu/keys.txt to $XDG_DATA_HOME/Cemu/keys.txt"
    fi
  fi
  # Shared actions
  dir_prep "$saves_folder/wiiu/cemu" "$bios_folder/cemu/usr/save"
fi
if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  set_setting_value "$cemuconf" "mlc_path" "$bios_folder/cemu" "cemu"
  set_setting_value "$cemuconf" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
  dir_prep "$saves_folder/wiiu/cemu" "$bios_folder/cemu/usr/save"
fi

