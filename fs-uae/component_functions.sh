#!/bin/bash

# Symlink custom.fs-uae to $storage_path/FS-UAE/custom.fs-uae
# Make a function that copies AmigaVision.fdi to $roms_path/amiga/ If enabled. 
# If disabled it deletes the file $roms_path/amiga/AmigaVision.fdi if it's there during boot.

fs-uae_config_amiga1200="$XDG_CONFIG_HOME/fs-uae/RetroDECK-amiga1200.fs-uae"
fs-uae_config_amiga600="$XDG_CONFIG_HOME/fs-uae/RetroDECK-amiga600.fs-uae"
fs-uae_config_amigacd32="$XDG_CONFIG_HOME/fs-uae/RetroDECK-amigacd32.fs-uae"
fs-uae_config_cdtv="$XDG_CONFIG_HOME/fs-uae/RetroDECK-cdtv.fs-uae"
amigavision_config="$XDG_CONFIG_HOME/fs-uae/AmigaVision.fs-uae"
amigavision_fdi="$XDG_CONFIG_HOME/fs-uae/AmigaVision.fdi"
custom_config_amiga600="$XDG_CONFIG_HOME/fs-uae/Custom/custom-amiga600.fs-uae"
custom_config_amiga1200="$XDG_CONFIG_HOME/fs-uae/Custom/custom-amiga1200.fs-uae"


_prepare_component::fs-uae() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting FS-UAE"
      log i "----------------------"

        create_dir -d "$XDG_CONFIG_HOME/fs-uae/"
        create_dir -d "$XDG_DATA_HOME/fs-uae/"
        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/fs-uae/"
        create_dir "$storage_path/fs-uae/AmigaVision/shared"
        dir_prep "$storage_path/fs-uae/Custom" "$XDG_CONFIG_HOME/fs-uae/Custom"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving FS-UAE"
      log i "----------------------"

    dir_prep "$storage_path/fs-uae/Custom" "$XDG_CONFIG_HOME/fs-uae/Custom"

    ;;
    
  esac
}

