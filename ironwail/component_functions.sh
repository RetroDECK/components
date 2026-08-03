#!/bin/bash

_prepare_component::ironwail() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Ironwail"
      log i "----------------------"

        dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Ironwail"
      log i "----------------------"
      
    dir_prep "$roms_path/quake/ironwail/id1" "$XDG_CONFIG_HOME/ironwail/id1"
    ;;

  esac
}
