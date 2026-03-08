#!/bin/bash

export pico8_config="$XDG_CONFIG_HOME/pico-8/config.txt"
export pico8_config_sdl_controllers="$XDG_CONFIG_HOME/pico-8/sdl_controllers.txt"

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

_prepare_component::pico-8() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset|postmove)
      log i "------------------------"
      log i "Performing PICO-8 $action actions"
      log i "------------------------"

      if [[ -d "$roms_path/pico8" ]]; then
        dir_prep "$roms_path/pico8" "$bios_path/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
      fi
      dir_prep "$bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
      dir_prep "$saves_path/pico-8" "$bios_path/pico-8/cdata"  # PICO-8 saves folder
      create_dir "$XDG_CONFIG_HOME/pico-8/"
      cp -fv "$component_config/config.txt" "$pico8_config"
      cp -fv "$component_config/sdl_controllers.txt" "$pico8_config_sdl_controllers"
    ;;

  esac
}
