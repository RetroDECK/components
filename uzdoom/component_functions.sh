#!/bin/bash

export uzdoom_config="$XDG_CONFIG_HOME/uzdoom/uzdoom.ini"

_prepare_component::uzdoom() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting UZDOOM"
      log i "------------------------"
      
      # TODO: do a proper script
      # This is just a placeholder script to test the emulator's flow

      create_dir "$XDG_CONFIG_HOME/uzdoom"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/midi"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/fm_banks"
      create_dir "$XDG_DATA_HOME/uzdoom/audio/soundfonts"
      create_dir "$bios_path/uzdoom"
      create_dir "$storage_path/uzdoom/audio/soundfonts"
      create_dir "$storage_path/uzdoom/audio/fm_banks"
      create_dir "$storage_path/uzdoom/audio/midi"

      cp -fv "$component_config/uzdoom.ini" "$uzdoom_config"

      # This is an unfortunate one-off because set_setting_value does not currently support multiple setting names with the same name in the same section
      sed -i "s#RETRODECKHOMEDIR#${rd_home_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKROMSDIR#${roms_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKBIOSDIR#${bios_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKSAVESDIR#${saves_path}#g" "$uzdoom_config"
      sed -i "s#RETRODECKSTORAGESDIR#${storage_path}#g" "$uzdoom_config"
    ;;

  esac
}

_post_update::uzdoom() {
  local previous_version="$1"

}
