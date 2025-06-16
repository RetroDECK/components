#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"
extras="/app/retrodeck/config/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "----------------------"
  log i "Preparing $component_name"
  log i "----------------------"

  if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
    create_dir -d "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis"
    cp -fvr "$config/"* "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Bios" "$rd_home_bios_path" "pcsx2" "Folders"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Snapshots" "$rd_home_screenshots_path" "pcsx2" "Folders"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "SaveStates" "$rd_home_states_path/ps2/pcsx2" "pcsx2" "Folders"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "MemoryCards" "$rd_home_saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
    set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "RecursivePaths" "$rd_home_roms_path/ps2" "pcsx2" "GameList"
    dir_prep "$multi_user_data_folder/$SteamAppUser/config/PCSX2" "$XDG_CONFIG_HOME/PCSX2"

  else # Single-user actions

    create_dir -d "$XDG_CONFIG_HOME/PCSX2/inis"
    cp -fvr "$config/"* "$XDG_CONFIG_HOME/PCSX2/inis/"
    set_setting_value "$pcsx2conf" "Bios" "$rd_home_bios_path" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "Snapshots" "$rd_home_screenshots_path" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "SaveStates" "$rd_home_states_path/ps2/pcsx2" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "MemoryCards" "$rd_home_saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "RecursivePaths" "$rd_home_roms_path/ps2" "pcsx2" "GameList"
    set_setting_value "$pcsx2conf" "Cheats" "$rd_home_cheats_path/pcsx2" "Folders"
    if [[ -d "$rd_home_cheats_path/pcsx2" && "$(ls -A "$rd_home_cheats_path/pcsx2")" ]]; then
      backup_file="$rd_home_backups_path/cheats/pcsx2-$(date +%y%m%d).tar.gz"
      create_dir "$(dirname "$backup_file")"
      tar -czf "$backup_file" -C "$rd_home_cheats_path" pcsx2
      log i "PCSX2 cheats backed up to $backup_file"
    fi
    create_dir -d "$rd_home_cheats_path/pcsx2"
    tar --strip-components=1 -xzf "$extras/pcsx2.tar.gz" -C "$rd_home_cheats_path/pcsx2" --overwrite
  fi

  # Shared actions
  create_dir "$rd_home_saves_path/ps2/pcsx2/memcards"
  create_dir "$rd_home_states_path/ps2/pcsx2"
  dir_prep "$rd_home_texture_packs_path/PCSX2" "$XDG_CONFIG_HOME/PCSX2/textures"

  # Reset default preset settings
  set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos")" "retrodeck" "cheevos"
  set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
  set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
  set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$pcsx2conf" "Bios" "$rd_home_bios_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2conf" "Snapshots" "$rd_home_screenshots_path" "pcsx2" "Folders"
  set_setting_value "$pcsx2conf" "SaveStates" "$rd_home_states_path/ps2/pcsx2" "pcsx2" "Folders"
  set_setting_value "$pcsx2conf" "MemoryCards" "$rd_home_saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
  set_setting_value "$pcsx2conf" "RecursivePaths" "$rd_home_roms_path/ps2" "pcsx2" "GameList"
  set_setting_value "$pcsx2conf" "Cheats" "$rd_home_cheats_path/pcsx2" "Folders"
  dir_prep "$rd_home_texture_packs_path/PCSX2" "$XDG_CONFIG_HOME/PCSX2/textures"
fi
