#!/bin/bash

export duckstation_config="$XDG_CONFIG_HOME/duckstation/settings.ini"
export duckstation_rd_config_dir="$rd_components/duckstation/rd_config"
export duckstation_textures_path="$XDG_CONFIG_HOME/duckstation/textures"
export duckstation_screenshots_path="$XDG_CONFIG_HOME/duckstation/screenshots"
export duckstation_videos_path="$XDG_CONFIG_HOME/duckstation/videos"
export duckstation_gamesettings_path="$XDG_CONFIG_HOME/duckstation/gamesettings"
export duckstation_shaders_path="$XDG_CONFIG_HOME/duckstation/shaders"
export duckstation_dump_textures_path="$XDG_CONFIG_HOME/duckstation/dump/textures"
export duckstation_dump_audio_path="$XDG_CONFIG_HOME/duckstation/dump/audio"
export duckstation_covers_path="$XDG_CONFIG_HOME/duckstation/covers"

_set_setting_value::duckstation() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^s^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  fi
}

_get_setting_value::duckstation() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  fi
}

_prepare_component::duckstation() {
  local action="$1"

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Duckstation"
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
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Duckstation"
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
    ;;

  esac
}
