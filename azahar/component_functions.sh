#!/bin/bash

azahar_config_path="$XDG_CONFIG_HOME/azahar-emu"
azahar_qtconfig="$azahar_config_path/qt-config.ini"
azahar_mods_path="$XDG_DATA_HOME/azahar-emu/load/mods"
azahar_textures_path="$XDG_DATA_HOME/azahar-emu/load/textures"
azahar_shaders_path="$XDG_DATA_HOME/azahar-emu/shaders"
azahar_logs_path="$XDG_DATA_HOME/azahar-emu/log"
azahar_cheats_path="$XDG_DATA_HOME/azahar-emu/cheats"

_set_setting_value::azahar() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  local sed_cmd
  sed_cmd='s^'"$name"'=".*"^'"$name"'="'"$value"'"^; t end;'
  sed_cmd+='s^'"$name"'=.*^'"$name"'='"$value"'^; :end'

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"'=^{'"$sed_cmd"'}' "$file"
  else
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::azahar() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -F'=' -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && $1 == key {
         val = substr($0, index($0,"=")+1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    awk -F'=' -v key="$name" \
      '/^\[/ { exit }
       $1 == key {
         val = substr($0, index($0,"=")+1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  fi
}
