#!/bin/bash

duckstation_config="$XDG_CONFIG_HOME/duckstation/settings.ini"
duckstation_rd_config_dir="$rd_components/duckstation/rd_config"
duckstation_textures_path="$XDG_CONFIG_HOME/duckstation/textures"
duckstation_screenshots_path="$XDG_CONFIG_HOME/duckstation/screenshots"
duckstation_videos_path="$XDG_CONFIG_HOME/duckstation/videos"
duckstation_gamesettings_path="$XDG_CONFIG_HOME/duckstation/gamesettings"
duckstation_shaders_path="$XDG_CONFIG_HOME/duckstation/shaders"
duckstation_dump_textures_path="$XDG_CONFIG_HOME/duckstation/dump/textures"
duckstation_dump_audio_path="$XDG_CONFIG_HOME/duckstation/dump/audio"
duckstation_covers_path="$XDG_CONFIG_HOME/duckstation/covers"

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
