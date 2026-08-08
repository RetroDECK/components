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
        create_dir "$storage_path/fs-uae/AmigaVision/shared"
        
        cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/fs-uae/"
        
        dir_prep "$bios_path" "$XDG_DATA_HOME/fs-uae/Kickstarts"

        dir_prep "$logs_path/FS-UAE/Logs" "$XDG_DATA_HOME/fs-uae/Logs"
        dir_prep "$logs_path/FS-UAE/Cache/Logs" "$XDG_DATA_HOME/fs-uae/Cache/Logs"

        dir_prep "$states_path/FS-UAE" "$XDG_DATA_HOME/fs-uae/Save States"

        dir_prep "$screenshots_path/FS-UAE/Screenshots" "$XDG_DATA_HOME/fs-uae/Screenshots"
        
        dir_prep "$storage_path/FS-UAE/CD-ROMs" "$XDG_DATA_HOME/fs-uae/CD-ROMs"
        dir_prep "$storage_path/FS-UAE/Configurations" "$XDG_DATA_HOME/fs-uae/Configurations"
        dir_prep "$storage_path/FS-UAE/Controllers" "$XDG_DATA_HOME/fs-uae/Controllers"
        dir_prep "$storage_path/FS-UAE/Covers" "$XDG_DATA_HOME/fs-uae/Covers"
        dir_prep "$storage_path/FS-UAE/Custom" "$XDG_CONFIG_HOME/fs-uae/Custom"
        dir_prep "$storage_path/FS-UAE/Flash Memory" "$XDG_DATA_HOME/fs-uae/Flash Memory"
        dir_prep "$storage_path/FS-UAE/Floppy Overlays" "$XDG_DATA_HOME/fs-uae/Floppy Overlays"
        dir_prep "$storage_path/FS-UAE/Floppies" "$XDG_DATA_HOME/fs-uae/Floppies"
        dir_prep "$storage_path/FS-UAE/Hard Drives" "$XDG_DATA_HOME/fs-uae/Hard Drives"
        dir_prep "$storage_path/FS-UAE/Themes" "$XDG_DATA_HOME/fs-uae/Themes"
        dir_prep "$storage_path/FS-UAE/Titles" "$XDG_DATA_HOME/fs-uae/Titles"

    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving FS-UAE"
      log i "----------------------"

        dir_prep "$bios_path" "$XDG_DATA_HOME/fs-uae/Kickstarts"
        dir_prep "$bios_path" "$storage_path/FS-UAE/AmigaVision/Kickstarts"

        dir_prep "$logs_path/FS-UAE/Logs" "$XDG_DATA_HOME/fs-uae/Logs"
        dir_prep "$logs_path/FS-UAE/Cache/Logs" "$XDG_DATA_HOME/fs-uae/Cache/Logs"

        dir_prep "$states_path/FS-UAE" "$XDG_DATA_HOME/fs-uae/Save States"

        dir_prep "$screenshots_path/FS-UAE/Screenshots" "$XDG_DATA_HOME/fs-uae/Screenshots"
        
        dir_prep "$storage_path/FS-UAE/CD-ROMs" "$XDG_DATA_HOME/fs-uae/CD-ROMs"
        dir_prep "$storage_path/FS-UAE/Configurations" "$XDG_DATA_HOME/fs-uae/Configurations"
        dir_prep "$storage_path/FS-UAE/Controllers" "$XDG_DATA_HOME/fs-uae/Controllers"
        dir_prep "$storage_path/FS-UAE/Covers" "$XDG_DATA_HOME/fs-uae/Covers"
        dir_prep "$storage_path/FS-UAE/Custom" "$XDG_CONFIG_HOME/fs-uae/Custom"
        dir_prep "$storage_path/FS-UAE/Flash Memory" "$XDG_DATA_HOME/fs-uae/Flash Memory"
        dir_prep "$storage_path/FS-UAE/Floppy Overlays" "$XDG_DATA_HOME/fs-uae/Floppy Overlays"
        dir_prep "$storage_path/FS-UAE/Floppies" "$XDG_DATA_HOME/fs-uae/Floppies"
        dir_prep "$storage_path/FS-UAE/Hard Drives" "$XDG_DATA_HOME/fs-uae/Hard Drives"
        dir_prep "$storage_path/FS-UAE/Themes" "$XDG_DATA_HOME/fs-uae/Themes"
        dir_prep "$storage_path/FS-UAE/Titles" "$XDG_DATA_HOME/fs-uae/Titles"

    ;;
    
  esac
}

