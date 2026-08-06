#!/bin/bash

export tsugaru_config="$XDG_CONFIG_HOME/tsugaru/tsugaru_config.txt"

_prepare_component::tsugaru() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Tsugaru"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/tsugaru"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/tsugaru"
      dir_prep "$bios_path/fmtowns" "$XDG_CONFIG_HOME/tsugaru/roms"

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving Tsugaru"
          log i "----------------------"

      dir_prep "$bios_path/fmtowns" "$XDG_CONFIG_HOME/tsugaru/roms"

    ;;

  esac
}