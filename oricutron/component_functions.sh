#!/bin/bash

export sdl2trs_config="$XDG_CONFIG_HOME/sdl2trs/.sdltrs.t8c"

_prepare_component::sdl2trs() {
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

    postmove)
      log i "----------------------"
      log i "Post-moving Oricutron"
      log i "----------------------"

  esac
}