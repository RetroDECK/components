#!/bin/bash

_prepare_component::flips() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
        log i "----------------------"
        log i "Resetting Flips"
        log i "----------------------"

        create_dir "$XDG_CONFIG_HOME/flips"
    ;;

  esac
}
