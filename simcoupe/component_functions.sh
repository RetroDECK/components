#!/bin/bash

export simcoupe_config="$XDG_CONFIG_HOME/simcoupe/.simcoupe/SimCoupe.cfg"

_prepare_component::simcoupe() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting SimCoupé"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/simcoupe/.simcoupe/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/simcoupe/.simcoupe/"

    ;;

  esac
}

_post_update::simcoupe() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 SimCoupé Setup"

    prepare_component "reset" "simcoupe"
  fi
}