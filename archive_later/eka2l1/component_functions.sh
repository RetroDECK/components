#!/bin/bash

export eka2l1_config="$XDG_CONFIG_HOME/EKA2L1/EKA2L1.conf"
export eka2l1_bindings_default="$XDG_CONFIG_HOME/EKA2L1/bindings/default.yml"
export eka2l1_bindings_steamdeck="$XDG_CONFIG_HOME/EKA2L1/bindings/steamdeck.yml"

_prepare_component::eka2l1() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"
  local component_data="$(get_own_component_path)/rd_data"

  case "$action" in

    reset)
      log i "----------------------"
      log i "Resetting EKA2L1"
      log i "----------------------"

      create_dir -d "$XDG_CONFIG_HOME/EKA2L1/"
      create_dir -d "$XDG_DATA_HOME/EKA2L1/"
      cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/EKA2L1/"
      cp -fvr "$component_data/"* "$XDG_DATA_HOME/EKA2L1/"
      
      dir_prep "$bios_path/EKA2L1" "$XDG_DATA_HOME/EKA2L1/data/roms"
      dir_prep "$storage_path/EKA2L1/j2me" "$XDG_DATA_HOME/EKA2L1/data/j2me"
      dir_prep "$storage_path/EKA2L1/drives" "$XDG_DATA_HOME/EKA2L1/data/drives"
   
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving EKA2L1"
      log i "----------------------"

      dir_prep "$bios_path/EKA2L1" "$XDG_DATA_HOME/EKA2L1/data/roms"
      dir_prep "$storage_path/EKA2L1/j2me" "$XDG_DATA_HOME/EKA2L1/data/j2me"
      dir_prep "$storage_path/EKA2L1/drives" "$XDG_DATA_HOME/EKA2L1/data/drives"
      
    ;;

  esac
}