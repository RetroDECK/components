#!/bin/bash

_prepare_component::commander-x16() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Commander X16"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/commander-x16"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/commander-x16"
      
      dir_prep "$roms_path/commander-x16/system" "$XDG_CONFIG_HOME/commander-x16/system"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Commander X16"
      log i "------------------------"

      dir_prep "$roms_path/commander-x16/system" "$XDG_CONFIG_HOME/commander-x16/system"

    ;;

  esac
}

_post_update::commander-x16() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Commander X16 Setup"

    prepare_component "reset" "commander-x16"
  fi

}
