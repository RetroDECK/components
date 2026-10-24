#!/bin/bash

export vpinballx_config="$XDG_CONFIG_HOME/vpinballx/VPinballX.ini"


_prepare_component::vpinballx() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Visual Pinball X"
      log i "----------------------"

      create_dir "$XDG_CONFIG_HOME/vpinballx/.vpinball/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/vpinballx/.vpinball"
      
      dir_prep "$storage_path/vpinballx/user" "$XDG_CONFIG_HOME/vpinballx/.vpinball/user"   

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving Visual Pinball X"
      log i "----------------------"

      dir_prep "$storage_path/vpinballx/user" "$XDG_CONFIG_HOME/vpinballx/.vpinball/user"
      
    ;;
    
  esac
}

_post_update::vpinballx() {
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.11.0"; then
    log i "0.11.0 Visual Pinball X Setup"

    prepare_component "reset" "vpinballx"
  fi
}