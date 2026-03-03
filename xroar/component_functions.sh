#!/bin/bash

xroar_config="$XDG_CONFIG_HOME/xroar/xroar.conf"

_set_setting_value::xroar() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    local esc_section=$(sed_escape_pattern "$section")
    local sed_cmd
    sed_cmd='s^\(  '"$name"' \)".*"^\1"'"$value"'"^; t end;'
    sed_cmd+='s^\(  '"$name"' \).*^\1'"$value"'^; :end'
    sed -i '\^'"$esc_section"'$^,\^  '"$name"' ^{'"$sed_cmd"'}' "$file"
  else
    local sed_cmd
    sed_cmd='s^\(^'"$name"' \)".*"^\1"'"$value"'"^; t end;'
    sed_cmd+='s^\(^'"$name"' \).*^\1'"$value"'^; :end'
    sed -i "$sed_cmd" "$file"
  fi
}

_get_setting_value::xroar() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="$section" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^[^ ]/ { in_section=0 }
       in_section && index($0, "  " key " ") == 1 {
         val = substr($0, length("  " key " ") + 1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " ") == 1 {
         val = substr($0, length(key " ") + 1)
         gsub(/^"|"$/, "", val)
         print val; exit
       }' "$file"
  fi
}
