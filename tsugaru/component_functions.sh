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
      sed -i "s|-ROMDIR RETRODECKBIOSDIR|-ROMDIR $bios_path|" $tsugaru_config

    ;;

    postmove)
          log i "----------------------"
          log i "Post-moving Tsugaru"
          log i "----------------------"

          sed -i "s|-ROMDIR RETRODECKBIOSDIR|-ROMDIR $bios_path|" $tsugaru_config

    ;;

  esac
}