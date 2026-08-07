#!/bin/bash

# Symlink custom.fs-uae to $storage_path/FS-UAE/custom.fs-uae
# Make a function that copies AmigaVision.fdi to $roms_path/amiga/ If enabled. 
# If disabled it deletes the file $roms_path/amiga/AmigaVision.fdi if it's there during boot.

amigavision_config="$XDG_CONFIG_HOME/FS-UAE/AmigaVision.fs-uae"
custom_config="$XDG_CONFIG_HOME/FS-UAE/custom.fs-uae"

_prepare_component::fs-uae() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting FS-UAE"
      log i "----------------------"

        create_dir -d "$XDG_CONFIG_HOME/FS-UAE/"
        create_dir -d "$XDG_DATA_HOME/FS-UAE/"
        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/FS-UAE/"
        create_dir "$storage_path/FS-UAE/AmigaVision/shared"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving FS-UAE"
      log i "----------------------"


    ;;
    
  esac
}

