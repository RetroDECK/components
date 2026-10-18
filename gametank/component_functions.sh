#!/bin/bash

_prepare_component::gametank() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Commander X16"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/gametank"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/gametank"

    ;;

  esac

}

_post_update::gametank() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 GameTank Setup"

    prepare_component "reset" "gametank"
  fi
}