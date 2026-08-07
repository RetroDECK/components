#!/bin/bash

gargoyle_config="$XDG_CONFIG_HOME/gargoyle/QtProject.conf"
gargoyle_config_Gargoylerc="$XDG_CONFIG_HOME/gargoyle/Gargoylerc"
gargoyle_config_user_dirs="$XDG_CONFIG_HOME/gargoyle/user-dirs.dirs"

_prepare_component::gargoyle() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Gargoyle"
      log i "----------------------"

  create_dir "$XDG_CONFIG_HOME/gargoyle"
  dir_prep "$storage_path/gargoyle/themes" "$XDG_DATA_HOME/gargoyle/themes"
  
    ;;

      esac
}