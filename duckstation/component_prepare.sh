#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands

  log i "------------------------"
  log i "Preparing $component_name"
  log i "------------------------"
  
    if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
      create_dir -d "$multi_user_data_folder/$SteamAppUser/data/duckstation/"
      cp -fv "$config/"* "$multi_user_data_folder/$SteamAppUser/data/duckstation"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "SearchDirectory" "$rd_home_bios_path" "duckstation" "BIOS"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card1Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card2Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Directory" "$rd_home_saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
      set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "RecursivePaths" "$rd_home_roms_path/psx" "duckstation" "GameList"
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/duckstation" "$XDG_CONFIG_HOME/duckstation"
    else # Single-user actions
      create_dir -d "$XDG_CONFIG_HOME/duckstation/"
      create_dir "$rd_home_saves_path/psx/duckstation/memcards"
      cp -fv "$config/"* "$XDG_CONFIG_HOME/duckstation"
      set_setting_value "$duckstation_config_settings" "SearchDirectory" "$rd_home_bios_path" "duckstation" "BIOS"
      set_setting_value "$duckstation_config_settings" "Card1Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config_settings" "Card2Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config_settings" "Directory" "$rd_home_saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config_settings" "RecursivePaths" "$rd_home_roms_path/psx" "duckstation" "GameList"
    fi
    # Shared actions
    dir_prep "$rd_home_states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
    dir_prep "$rd_home_texture_packs_path/Duckstation" "$XDG_CONFIG_HOME/duckstation/textures"

    # Reset default preset settings
    set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "cheevos")" "retrodeck" "cheevos"
    set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
    set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
    set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  set_setting_value "$duckstation_config_settings" "SearchDirectory" "$rd_home_bios_path" "duckstation" "BIOS"
  set_setting_value "$duckstation_config_settings" "Card1Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config_settings" "Card2Path" "$rd_home_saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config_settings" "Directory" "$rd_home_saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config_settings" "RecursivePaths" "$rd_home_roms_path/psx" "duckstation" "GameList"
  dir_prep "$rd_home_states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
  dir_prep "$rd_home_texture_packs_path/Duckstation" "$XDG_CONFIG_HOME/duckstation/textures"
fi
