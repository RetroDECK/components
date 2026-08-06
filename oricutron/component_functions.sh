#!/bin/bash

export sdl2trs_config="$XDG_CONFIG_HOME/oricutron/oricutron.cfg"

_prepare_component::oricutron() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Oricutron"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/oricutron/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/oricutron/"

    ;;

  esac
}