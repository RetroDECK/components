#!/bin/bash

export gzdoom_config="$XDG_CONFIG_HOME/gzdoom/gzdoom.ini"

_prepare_component::gzdoom() {
  local action="$1"

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
