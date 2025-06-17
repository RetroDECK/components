#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

cemu_conf="$XDG_CONFIG_HOME/Cemu/settings.xml"
cemu_controller_conf="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller0.xml"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"
  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
    create_dir -d "$multi_user_data_folder/$SteamAppUser/config/Cemu"
    cp -fr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/Cemu/"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "mlc_path" "$rd_home_bios_path/cemu" "cemu"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "Entry" "$rd_home_roms_path/wiiu" "cemu" "GamePaths"
    dir_prep "$multi_user_data_folder/$SteamAppUser/config/Cemu" "$XDG_CONFIG_HOME/Cemu"
  else
    create_dir -d "$XDG_CONFIG_HOME/Cemu/"
    cp -fr "$config/"* "$XDG_CONFIG_HOME/Cemu/"
    set_setting_value "$cemu_conf" "mlc_path" "$rd_home_bios_path/cemu" "cemu"
    set_setting_value "$cemu_conf" "Entry" "$rd_home_roms_path/wiiu" "cemu" "GamePaths"
    if [[ -e "$rd_home_bios_path/cemu/keys.txt" ]]; then
      rm -rf "$XDG_DATA_HOME/Cemu/keys.txt" && ln -s "$rd_home_bios_path/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt" && log d "Linked $rd_home_bios_path/cemu/keys.txt to $XDG_DATA_HOME/Cemu/keys.txt"
    fi
  fi
  # Shared actions
  dir_prep "$rd_home_saves_path/wiiu/cemu" "$rd_home_bios_path/cemu/usr/save"
fi
if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  set_setting_value "$cemu_conf" "mlc_path" "$rd_home_bios_path/cemu" "cemu"
  set_setting_value "$cemu_conf" "Entry" "$rd_home_roms_path/wiiu" "cemu" "GamePaths"
  dir_prep "$rd_home_saves_path/wiiu/cemu" "$rd_home_bios_path/cemu/usr/save"
fi

