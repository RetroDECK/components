#!/bin/bash

export lindbergh_config="$XDG_CONFIG_HOME/oricutron/lindbergh.ini"
export controls_config="$XDG_CONFIG_HOME/oricutron/controls.ini"

_prepare_component::lindbergh() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Lindbergh Loader"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/lindbergh/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/lindbergh/"

    ;;

  esac
  
}