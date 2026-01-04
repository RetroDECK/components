#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "------------------------"
  log i "Resetting $component_name"
  log i "------------------------"
  
  create_dir -d "$XDG_CONFIG_HOME/duckstation/"
  create_dir "$saves_path/psx/duckstation/memcards"
  cp -fv "$component_config/"* "$XDG_CONFIG_HOME/duckstation"
  set_setting_value "$duckstation_config" "SearchDirectory" "$bios_path" "duckstation" "BIOS"
  set_setting_value "$duckstation_config" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
  dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
  dir_prep "$texture_packs_path/Duckstation/textures" "$duckstation_textures_path"
  dir_prep "$screenshots_path/Duckstation/" "$duckstation_screenshots_path"
  dir_prep "$shaders_path/Duckstation/" "$duckstation_shaders_path"
  dir_prep "$storage_path/Duckstation/dump/textures" "$duckstation_dump_textures_path"
  dir_prep "$storage_path/Duckstation/dump/audio" "$duckstation_dump_audio_path"
fi

if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  log i "------------------------"
  log i "Post-moving $component_name"
  log i "------------------------"

  set_setting_value "$duckstation_config" "SearchDirectory" "$bios_path" "duckstation" "BIOS"
  set_setting_value "$duckstation_config" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
  set_setting_value "$duckstation_config" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
  dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
  dir_prep "$texture_packs_path/Duckstation/textures" "$duckstation_textures_path"
  dir_prep "$screenshots_path/Duckstation/" "$duckstation_screenshots_path"
  dir_prep "$shaders_path/Duckstation/" "$duckstation_shaders_path"
  dir_prep "$storage_path/Duckstation/dump/textures" "$duckstation_dump_textures_path"
  dir_prep "$storage_path/Duckstation/dump/audio" "$duckstation_dump_audio_path"
fi
