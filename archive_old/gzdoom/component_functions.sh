#!/bin/bash

export gzdoom_config="$XDG_CONFIG_HOME/gzdoom/gzdoom.ini"

_prepare_component::gzdoom() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting GZDOOM"
      log i "------------------------"
      
      # TODO: do a proper script
      # This is just a placeholder script to test the emulator's flow

      create_dir "$XDG_CONFIG_HOME/gzdoom"
      create_dir "$XDG_DATA_HOME/gzdoom/audio/midi"
      create_dir "$XDG_DATA_HOME/gzdoom/audio/fm_banks"
      create_dir "$XDG_DATA_HOME/gzdoom/audio/soundfonts"
      create_dir "$bios_path/gzdoom"
      create_dir "$storage_path/gzdoom/audio/soundfonts"
      create_dir "$storage_path/gzdoom/audio/fm_banks"
      create_dir "$storage_path/gzdoom/audio/midi"

      cp -fv "$component_config/gzdoom.ini" "$gzdoom_config"

      # This is an unfortunate one-off because set_setting_value does not currently support multiple setting names with the same name in the same section
      sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$gzdoom_config"
      sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$gzdoom_config"
      sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$gzdoom_config"
      sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$gzdoom_config"
      sed -i "s#RETRODECKSTORAGESDIR#${storage_path}#g" "$gzdoom_config"
    ;;

  esac
}

_post_update::gzdoom() {
  local previous_version="$1"

}

_post_update_legacy::gzdoom() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

    prepare_component "reset" "gzdoom"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then

    log i "0.10.0b Upgrade - Reset: GZDoom"

    prepare_component "reset" "gzdoom"

    # GZDOOM needs to be reset as the changes are in the config that connects to the new folders.
  fi
}
