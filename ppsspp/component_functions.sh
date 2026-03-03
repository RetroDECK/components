#!/bin/bash

ppsspp_config="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp.ini"
ppsspp_config_controls="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/controls.ini"
ppsspp_retroachievements_dat="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat"
ppsspp_cheats_db="$rd_components/ppsspp/cheats/cheat.db"
ppsspp_rd_config_dir="$rd_components/ppsspp/rd_config"
ppsspp_rd_extras_dir="$rd_components/ppsspp/rd_extras"
ppsspp_textures_path="$XDG_CONFIG_HOME/ppsspp/PSP/TEXTURES"
ppsspp_shaders_path="$XDG_CONFIG_HOME/ppsspp/PSP/shaders"
ppsspp_cheats_path="$XDG_CONFIG_HOME/ppsspp/PSP/Cheats"
ppsspp_mods_path="$XDG_CONFIG_HOME/ppsspp/PSP/PLUGINS"
ppsspp_logs_path="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/DUMP"

_set_setting_value::ppsspp() {
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

_get_setting_value::ppsspp() {
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
