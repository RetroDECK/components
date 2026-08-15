#!/bin/bash

## ares keeps it's config in $XDG_DATA_HOME/ares/

export ares_config="$XDG_DATA_HOME/ares/settings.bml"

_prepare_component::ares() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting ares"
      log i "----------------------"

      create_dir -d "$XDG_DATA_HOME/ares/hiro"
      create_dir -d "$XDG_CONFIG_HOME/ares/"
      create_dir -d "$logs_path/ares"
      create_dir -d "$saves_path/ares/"
      create_dir -d "$screenshots_path/ares/"

      cp -fr "$component_config/"* "$XDG_DATA_HOME/ares/"

      sed -i "s|RETRODECKROMSDIR|$roms_path|" $ares_config
      sed -i "s|RETRODECKBIOSDIR|$bios_path|" $ares_config
      sed -i "s|RETRODECKSAVESDIR|$saves_path|" $ares_config
      sed -i "s|RETRODECKSCREENSHORTSDIR|$screenshots_path|" $ares_config
      sed -i "s|RETRODECKLOGSDIR|$logs_path|" $ares_config

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving ares"
      log i "----------------------"

      sed -i "s|RETRODECKROMSDIR|$roms_path|" $ares_config
      sed -i "s|RETRODECKBIOSDIR|$bios_path|" $ares_config
      sed -i "s|RETRODECKSAVESDIR|$saves_path|" $ares_config
      sed -i "s|RETRODECKSCREENSHORTSDIR|$screenshots_path|" $ares_config
      sed -i "s|RETRODECKLOGSDIR|$logs_path|" $ares_config

    ;;

  esac

}

