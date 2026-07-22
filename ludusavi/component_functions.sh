#!/bin/bash

export ludusavi_config_dir="$XDG_CONFIG_HOME/ludusavi"
export ludusavi_config_file="$ludusavi_config_dir/config.yaml"

_prepare_component::ludusavi() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "--------------------------------"
      log i "Resetting Ludusavi"
      log i "--------------------------------"

      create_dir -d "$ludusavi_config_dir"
      cp -fv "$component_config/config.yaml" "$ludusavi_config_file"
    ;;

    postmove)

    ;;

    startup)
      log i "--------------------------------"
      log i "Starting Ludusavi"
      log i "--------------------------------"
      local component_path="$(get_own_component_path)"

      run_ludusavi_backup "startup"
    ;;

    shutdown)
      log i "--------------------------------"
      log i "Shutting down Ludusavi"
      log i "--------------------------------"

      run_ludusavi_backup "shutdown"
    ;;

  esac
}

start::ludusavi() {
  log d "Starting Steam ROM Manager"
  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}
