#!/bin/bash

if [[ "$component" =~ ^(pcsx2|all)$ ]]; then
  component_found="true"
  if [[ "$action" == "reset" ]]; then # Run reset-only commands
    log i "----------------------"
    log i "Preparing PCSX2"
    log i "----------------------"
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
      create_dir -d "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis"
      cp -fvr "$config/PCSX2/"* "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Bios" "$bios_folder" "pcsx2" "Folders"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/PCSX2" "$XDG_CONFIG_HOME/PCSX2"
    else # Single-user actions
      create_dir -d "$XDG_CONFIG_HOME/PCSX2/inis"
      cp -fvr "$config/PCSX2/"* "$XDG_CONFIG_HOME/PCSX2/inis/"
      set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
      set_setting_value "$pcsx2conf" "Cheats" "$cheats_folder/pcsx2" "Folders"
      if [[ -d "$cheats_folder/pcsx2" && "$(ls -A "$cheats_folder/pcsx2")" ]]; then
        backup_file="$backups_folder/cheats/pcsx2-$(date +%y%m%d).tar.gz"
        create_dir "$(dirname "$backup_file")"
        tar -czf "$backup_file" -C "$cheats_folder" pcsx2
        log i "PCSX2 cheats backed up to $backup_file"
      fi
      create_dir -d "$cheats_folder/pcsx2"
      tar --strip-components=1 -xzf "/app/retrodeck/cheats/pcsx2.tar.gz" -C "$cheats_folder/pcsx2" --overwrite
    fi
    # Shared actions
    create_dir "$saves_folder/ps2/pcsx2/memcards"
    create_dir "$states_folder/ps2/pcsx2"
    dir_prep "$texture_packs_folder/PCSX2" "$XDG_CONFIG_HOME/PCSX2/textures"

    # Reset default preset settings
    set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos")" "retrodeck" "cheevos"
    set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
    set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
    set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
  fi
  if [[ "$action" == "postmove" ]]; then # Run only post-move commands
    set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
    set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
    set_setting_value "$pcsx2conf" "Cheats" "$cheats_folder/pcsx2" "Folders"
    dir_prep "$texture_packs_folder/PCSX2" "$XDG_CONFIG_HOME/PCSX2/textures"
  fi
fi
