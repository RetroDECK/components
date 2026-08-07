#!/bin/bash

export commander-x16_config="$XDG_CONFIG_HOME/commander-x16/commander-x16.cfg"

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
      dir_prep "$storage_path/commander-x16/system" "$XDG_CONFIG_HOME/commander-x16/system"

    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Commander X16"
      log i "------------------------"

      dir_prep "$storage_path/commander-x16/system" "$XDG_CONFIG_HOME/commander-x16/system"

    ;;

  esac
}