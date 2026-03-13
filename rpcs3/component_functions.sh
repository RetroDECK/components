#!/bin/bash

export rpcs3_config="$XDG_CONFIG_HOME/rpcs3/config.yml"
export rpcs3_config_evdev_positive_axis="$XDG_CONFIG_HOME/rpcs3/evdev_positive_axis.yml"
export rpcs3_log="$XDG_CACHE_HOME/rpcs3/RPCS3.log"
export rpcs3_config_vfs="$XDG_CONFIG_HOME/rpcs3/vfs.yml"
export rpcs3_gui_current_settings="$XDG_CONFIG_HOME/rpcs3/GuiConfigs/CurrentSettings.ini"
export rpcs3_input_active_profiles="$XDG_CONFIG_HOME/rpcs3/input_configs/active_profiles.yml"
export rpcs3_input_Default="$XDG_CONFIG_HOME/rpcs3/input_configs/global/Default.yml"
export rpcs3_component_dir="$rd_components/rpcs3"
export rpcs3_firmware="http://dus01.ps3.update.playstation.net/update/ps3/image/us/2025_0305_c179ad173bbc08b55431d30947725a4b/PS3UPDAT.PUP"

update_rpcs3_firmware() {
  if check_network_connectivity; then
    configurator_generic_dialog "RetroDECK Configurator - Install: RPCS3 Firmware" "This tool will download the <span foreground='$purple'><b>firmware required by RPCS3</b></span>.\n\nThe process may take several minutes, and the emulator will start to complete the installation.\n\n<span foreground='$purple'><b>Please close RPCS3 manually</b></span> once the installation is finished."
    (
      create_dir "$roms_path/ps3/tmp"
      chmod 777 "$roms_path/ps3/tmp"
      download_file "$rpcs3_firmware" "$roms_path/ps3/tmp/PS3UPDAT.PUP" "RPCS3 Firmware"
      bash "$rpcs3_component_dir/component_launcher.sh" --installfw "$roms_path/ps3/tmp/PS3UPDAT.PUP"
      rm -rf "$roms_path/ps3/tmp"
    ) |
    rd_zenity --progress --no-cancel --pulsate --auto-close \
    --icon-name=net.retrodeck.retrodeck \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="Downloading: RPCS3 Firmware" \
    --width=400 --height=200 \
    --text="Downloading and installing RPCS3 Firmware, please be patient.\n\n<span foreground='$purple' size="larger"><b>NOTICE - If the process is taking too long:</b></span>\n\nSome windows may be running in the background that require your attention, such as popups from emulators or the upgrade itself that needs user input to continue.\n\n<span foreground='$purple'><b>Please finish these processes and close the windows to continue.</b></span>>"
  else
    configurator_generic_dialog "RetroDECK Configurator - Warning: Install RPCS3 Firmware - No Internet" "Warning: You do not appear to currently have Internet access, which is required by this tool.\n\nPlease try again when network access has been restored."
  fi
}

finit_install_rpcs3_firmware_dialog() {
  rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - RPCS3 Firmware" --cancel-label="No " --ok-label "Yes" \
  --text="Would you like to install the RPCS3 firmware as part of the initial RetroDECK setup?\n\nThis process may take several minutes and requires an active Internet connection.\n\n<span foreground='$purple'><b>RPCS3 will launch automatically</b></span> at the end of the RetroDECK setup.\nAfter the firmware installation is complete,<span foreground='$purple'><b> please close the emulator window</b></span> to finish the process."
}

correct_rpcs3_desktop_files::rpcs3() {
  rpcs3_component_path="$(get_own_component_path)/component_launcher.sh"

  while IFS= read -r file; do
    sed -i "s|^Exec=\"[^\"]*\"\(.*\)|Exec=\"${rpcs3_component_path}\"\1|" "$file"
  done < <(find "$roms_path/ps3" -mindepth 1 -type f -iname "*.desktop")
}

_set_setting_value::rpcs3() {
  local file="$1" name="$2" value="$3" section="${4:-}"

  if [[ "$file" =~ \.ini$ ]]; then
    local esc_name=$(sed_escape_pattern "$name")
    local esc_value=$(sed_escape_replacement "$value")
    if [[ -n "$section" ]]; then
      local esc_section=$(sed_escape_pattern "$section")
      sed -i '\^\['"$esc_section"'\]^,\^\^'"$esc_name"'=^s^\^'"$esc_name"'=.*^'"$esc_name"'='"$esc_value"'^' "$file"
    else
      sed -i 's^\^'"$esc_name"'=.*^'"$esc_name"'='"$esc_value"'^' "$file"
    fi

  elif [[ "$file" =~ \.yml$ ]]; then
    local yq_path=""
    if [[ -n "$section" ]]; then
      while IFS= read -r segment; do
        [[ -n "$segment" ]] && yq_path+=".[\"${segment}\"]"
      done <<< "${section//::/$'\n'}"
    fi
    yq_path+=".[\"${name}\"]"
    VAL="$value" yq -i "${yq_path} = env(VAL)" "$file"
  fi
}

_get_setting_value::rpcs3() {
  local file="$1" name="$2" section="${3:-}"

  if [[ "$file" =~ \.ini$ ]]; then
    if [[ -n "$section" ]]; then
      KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
         /^\[/ { in_section=0 }
         in_section && $1 == key {
           print substr($0, index($0,"=")+1); exit
         }' "$file"
    else
      KEY="$name" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"] }
       $1 == key {
           print substr($0, index($0,"=")+1); exit
         }' "$file"
    fi

  elif [[ "$file" =~ \.yml$ ]]; then
    local yq_path=""
    if [[ -n "$section" ]]; then
      while IFS= read -r segment; do
        [[ -n "$segment" ]] && yq_path+=".[\"${segment}\"]"
      done <<< "${section//::/$'\n'}"
    fi
    yq_path+=".[\"${name}\"]"
    yq -r "${yq_path}" "$file"
  fi
}

_prepare_component::rpcs3() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting RPCS3"
      log i "------------------------"

      create_dir -d "$XDG_CONFIG_HOME/rpcs3/"
      cp -fr "$component_config/"* "$XDG_CONFIG_HOME/rpcs3/"
      # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
      sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$storage_path/rpcs3/"'^' "$rpcs3_config_vfs"
      set_setting_value "$rpcs3_config_vfs" "/games/" "$roms_path/ps3/" "rpcs3"
      dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
      dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
      create_dir "$storage_path/rpcs3/dev_hdd0"
      create_dir "$storage_path/rpcs3/dev_hdd1"
      create_dir "$storage_path/rpcs3/dev_flash"
      create_dir "$storage_path/rpcs3/dev_flash2"
      create_dir "$storage_path/rpcs3/dev_flash3"
      create_dir "$storage_path/rpcs3/dev_bdvd"
      create_dir "$storage_path/rpcs3/dev_usb000"
      dir_prep "$storage_path/rpcs3/captures" "$XDG_CONFIG_HOME/rpcs3/captures"
      dir_prep "$storage_path/rpcs3/patches" "$XDG_CONFIG_HOME/rpcs3/patches"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving RPCS3"
      log i "------------------------"

      # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
      sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$storage_path/rpcs3/"'^' "$rpcs3_config_vfs"
      set_setting_value "$rpcs3_config_vfs" "/games/" "$roms_path/ps3" "rpcs3"
      dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
      dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
      dir_prep "$storage_path/rpcs3/captures" "$XDG_CONFIG_HOME/rpcs3/captures"
      dir_prep "$storage_path/rpcs3/patches" "$XDG_CONFIG_HOME/rpcs3/patches"
    ;;

    startup)
      log i "------------------------"
      log i "Performing RPCS3 startup actions"
      log i "------------------------"

      correct_rpcs3_desktop_files::rpcs3
    ;;

  esac
}

_post_update::rpcs3() {
  local previous_version="$1"

}

_post_update_legacy::rpcs3() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Update RPCS3 vfs file contents. migrate from old location if needed

    cp -f "$config/rpcs3/vfs.yml" "$XDG_CONFIG_HOME/rpcs3/vfs.yml"
    sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_path/rpcs3/"'^' "$rpcs3vfsconf"
    set_setting_value "$rpcs3vfsconf" "/games/" "$roms_path/ps3/" "rpcs3"
    if [[ -d "$roms_path/ps3/emudir" ]]; then # The old location exists, meaning the emulator was run at least once.
      mkdir "$bios_path/rpcs3"
      mv "$roms_path/ps3/emudir/"* "$bios_path/rpcs3/"
      rm "$roms_path/ps3/emudir"
      configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update and due to a RPCS3 config upgrade, the files that used to exist at\n\n~/retrodeck/roms/ps3/emudir\n\nare now located at\n\n~/retrodeck/bios/rpcs3.\nYour existing files have been moved automatically."
    fi
    create_dir "$storage_path/rpcs3/dev_hdd0"
    create_dir "$storage_path/rpcs3/dev_hdd1"
    create_dir "$storage_path/rpcs3/dev_flash"
    create_dir "$storage_path/rpcs3/dev_flash2"
    create_dir "$storage_path/rpcs3/dev_flash3"
    create_dir "$storage_path/rpcs3/dev_bdvd"
    create_dir "$storage_path/rpcs3/dev_usb000"
    dir_prep "$saves_path/ps3/rpcs3" "$storage_path/rpcs3/dev_hdd0/home/00000001/savedata"
    dir_prep "$states_path/ps3/rpcs3" "$XDG_CONFIG_HOME/rpcs3/savestates"
  fi

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

    # The save folder of rpcs3 was inverted so we're moving the saves into the real one
    log i "RPCS3 saves needs to be migrated, executing."
    if [[ "$(ls -A "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata")" ]]; then
      log i "Existing RPCS3 savedata found, backing up..."
      create_dir "$backups_folder"
      zip -rq9 "$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip" "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata"
    fi
    dir_prep "$saves_path/ps3/rpcs3" "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata"
    log i "RPCS3 saves migration completed, a backup was made here: \"$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip\"."
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then

    log i "0.10.0b Upgrade - Postmove: RPCS3 - Folder Creation, Move old location"

    create_dir "$storage_path/rpcs3/dev_hdd0"
    create_dir "$storage_path/rpcs3/dev_hdd1"
    create_dir "$storage_path/rpcs3/dev_flash"
    create_dir "$storage_path/rpcs3/dev_flash2"
    create_dir "$storage_path/rpcs3/dev_flash3"
    create_dir "$storage_path/rpcs3/dev_bdvd"
    create_dir "$storage_path/rpcs3/dev_usb000"

    prepare_component "postmove" "rpcs3"

    # Since in 0.10.0b we added the storage folder we need to migrate the folders

    unlink "$bios_path/rpcs3/dev_hdd0/home/00000001/savedata"
    move "$bios_path/rpcs3/dev_hdd0" "$storage_path/rpcs3/dev_hdd0"
    move "$bios_path/rpcs3/dev_hdd1" "$storage_path/rpcs3/dev_hdd1"
    move "$bios_path/rpcs3/dev_flash" "$storage_path/rpcs3/dev_flash"
    move "$bios_path/rpcs3/dev_flash2" "$storage_path/rpcs3/dev_flash2"
    move "$bios_path/rpcs3/dev_flash3" "$storage_path/rpcs3/dev_flash3"
    move "$bios_path/rpcs3/dev_bdvd" "$storage_path/rpcs3/dev_bdvd"
    move "$bios_path/rpcs3/dev_usb000" "$storage_path/rpcs3/dev_usb000"
  fi
}
