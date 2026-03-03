#!/bin/bash

pico8_config="$XDG_CONFIG_HOME/pico-8/config.txt"
pico8_config_sdl_controllers="$XDG_CONFIG_HOME/pico-8/sdl_controllers.txt"

_set_setting_value::pico-8() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")

  local sed_cmd
  # Lines with inline comments: preserve the comment
  sed_cmd='s^\(^'"$name"' \).*\( //.*\)^\1'"$value"'\2^; t end;'
  # Lines without comments
  sed_cmd+='s^\(^'"$name"' \).*^\1'"$value"'^; :end'

  sed -i "$sed_cmd" "$file"
}

_get_setting_value::pico-8() {
  local file="$1" name="$2"

  awk -v key="$name" \
    'index($0, key " ") == 1 {
       val = substr($0, length(key) + 2)
       idx = index(val, " //")
       if (idx > 0) val = substr(val, 1, idx - 1)
       gsub(/[[:space:]]+$/, "", val)
       print val; exit
     }' "$file"
}
