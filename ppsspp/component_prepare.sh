#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"

  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
    create_dir -d "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
    cp -fv "$config/"* "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/ppsspp.ini" "CurrentDirectory" "$rd_home_roms_path/psp" "ppsspp" "General"
    dir_prep "$multi_user_data_folder/$SteamAppUser/config/ppsspp" "$XDG_CONFIG_HOME/ppsspp"

  else # Single-user actions

    create_dir -d "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
    cp -fv "$config/"* "$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/"
    set_setting_value "$ppssppconf" "CurrentDirectory" "$rd_home_roms_path/psp" "ppsspp" "General"
  fi

  # Shared actions
  dir_prep "$rd_home_saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
  dir_prep "$rd_home_states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
  dir_prep "$rd_home_texture_packs_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
  dir_prep "$rd_home_shaders_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/assets/shaders"
  create_dir -d "$rd_home_cheats_path/PPSSPP-SA"
  dir_prep "$rd_home_cheats_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
  if [[ -d "$rd_home_cheats_path/PPSSPP-SA" && "$(ls -A "$rd_home_cheats_path"/PPSSPP)" ]]; then
    backup_file="$rd_home_backups_path/cheats/PPSSPP-SA-$(date +%y%m%d).tar.gz"
    create_dir "$(dirname "$backup_file")"
    tar -czf "$backup_file" -C "$rd_home_cheats_path" PPSSPP
    log i "PPSSPP cheats backed up to $backup_file"
  fi
  rsync "$ppssppcheatsdb" "$rd_home_cheats_path/PPSSPP/"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$ppssppconf" "CurrentDirectory" "$rd_home_roms_path/psp" "ppsspp" "General"
  dir_prep "$rd_home_saves_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/SAVEDATA"
  dir_prep "$rd_home_states_path/PSP/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/PPSSPP_STATE"
  dir_prep "$rd_home_texture_packs_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
  dir_prep "$rd_home_shaders_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/assets/shaders"
  dir_prep "$rd_home_cheats_path/PPSSPP-SA" "$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
fi
