#!/bin/bash

_prepare_component::hypseus-singe() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting Hypseus Singe"
      log i "----------------------"

      create_dir -d "$XDG_DATA_HOME/hypseus-singe"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/hypseus-singe"
      dir_prep "$bios_path/EKA2L1" "$XDG_DATA_HOME/EKA2L1/data/roms"
      dir_prep "$storage_path/EKA2L1/j2me" "$XDG_DATA_HOME/EKA2L1/data/j2me"
      dir_prep "$storage_path/EKA2L1/drives" "$XDG_DATA_HOME/EKA2L1/data/drives"
      
    ;;


    postmove)
      log i "------------------------"
      log i "Post-moving Hypseus Singe"
      log i "------------------------"

      
    ;;

  esac
}