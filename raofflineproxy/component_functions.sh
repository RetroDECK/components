#!/bin/bash

_prepare_component::raofflineproxy() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting RAOfflineProxy"
      log i "----------------------"

  # RAOfflineProxy resolves its configuration directory at startup using `XDG_CONFIG_HOME` (fallback: `~/.config/raofflineproxy`). 

  create_dir "$XDG_CONFIG_HOME/raofflineproxy"
    ;;

  esac
}