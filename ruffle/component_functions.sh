#!/bin/bash

export ruffle_config="$XDG_CONFIG_HOME/ruffle/preferences.toml"
export ruffle_logs_path="$XDG_CACHE_HOME/ruffle/log"
export ruffle_saves_path="$XDG_DATA_HOME/ruffle/SharedObjects"

_set_setting_value::ruffle() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")

  sed -i 's^'"$name"' = ".*"^'"$name"' = "'"$value"'"^' "$file"
}

_get_setting_value::ruffle() {
  local file="$1" name="$2"

  sed -n 's^'"$(sed_escape_pattern "$name")"' = "\(.*\)"^\1^p' "$file"
}

_prepare_component::ruffle() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Ruffle"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/ruffle/"
      cp -fv "$component_config/"* "$XDG_CONFIG_HOME/ruffle/"
      dir_prep "$saves_path/flash/ruffle" "$ruffle_saves_path"
      dir_prep "$logs_path/ruffle" "$ruffle_logs_path"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Ruffle"
      log i "------------------------"

      dir_prep "$saves_path/flash/ruffle" "$ruffle_saves_path"
      dir_prep "$logs_path/ruffle" "$ruffle_logs_path"
    ;;

  esac
}