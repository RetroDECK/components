#!/bin/bash

export vita3k_config="$XDG_CONFIG_HOME/Vita3K/config.yml"
export vita3k_config_user="$XDG_CONFIG_HOME/Vita3K/ux0/user/00/user.xml"
export vita3k_vu_firmware_url="http://dus01.psv.update.playstation.net/update/psv/image/2022_0209/rel_f2c7b12fe85496ec88a0391b514d6e3b/PSVUPDAT.PUP"
export vita3k_2u_firmware_url="http://dus01.psp2.update.playstation.net/update/psp2/image/2019_0924/sd_8b5f60b56c3da8365b973dba570c53a5/PSP2UPDAT.PUP?dest=us"
export vita3k_component_dir="$rd_components/vita3k"
export vita3k_textures_path="$storage_path/psvita/Vita3K/ux0/textures/import"
export vita3k_lang_path="$XDG_DATA_HOME/Vita3K/lang"
export vita3k_patch_path="$XDG_DATA_HOME/Vita3K/patch"
export vita3k_shaders_path="$XDG_CACHE_HOME/Vita3K/shaders"
export vita3k_rd_config_dir="$rd_components/vita3k/rd_config"

update_vita3k_firmware() {
  if [[ $(check_network_connectivity) == "true" ]]; then
    configurator_generic_dialog "RetroDECK Configurator - Install: Vita3K firmware" "This tool will download the <span foreground='$purple'><b>firmware required by Vita3K</b></span>.\n\nThe process may take several minutes"
    (
      download_file "$vita3k_vu_firmware_url" "/tmp/PSVUPDAT.PUP" "Vita3K Firmware file: PSVUPDAT.PUP"
      download_file "$vita3k_2u_firmware_url" "/tmp/PSP2UPDAT.PUP" "Vita3K Firmware file: PSP2UPDAT.PUP"
      bash "$vita3k_component_dir/component_launcher.sh" --firmware /tmp/PSVUPDAT.PUP
      bash "$vita3k_component_dir/component_launcher.sh" --firmware /tmp/PSP2UPDAT.PUP
    ) |
    rd_zenity --progress --pulsate \
    --icon-name=net.retrodeck.retrodeck \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="Downloading: Vita3K Firmware" \
    --no-cancel \
    --auto-close
  else
    configurator_generic_dialog "RetroDECK Configurator - Warning: Install Vita3K Firmware - No Internet" "Warning: You do not appear to currently have Internet access, which is required by this tool.\n\nPlease try again when network access has been restored."
  fi
  configurator_tools_dialog
}

finit_install_vita3k_firmware_dialog() {
  rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Vita3K Firmware" --cancel-label="No " --ok-label "Yes" \
  --text="Would you like to install the Vita3K firmware as part of the initial RetroDECK setup?\n\n\This process may take several minutes and requires an active internet connection.\n\n\<span foreground='$purple'><b>Vita3K will launch automatically</b></span> at the end of the RetroDECK setup.\nAfter the firmware installation is complete,<span foreground='$purple'><b> please close the emulator window</b></span> to finish the process if needed."
}

_set_setting_value::vita3k() {
  local file="$1" name="$2" value="$3"

  VAL="$value" yq -i ".[\"${name}\"] = env(VAL)" "$file"
}

_get_setting_value::vita3k() {
  local file="$1" name="$2"

  yq -r ".[\"${name}\"]" "$file"
}

_prepare_component::vita3k() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Vita3k"
      log i "------------------------"

      # NOTE: the component is writing in "." so it must be placed in the rw filesystem. A symlink of the binary is already placed in /app/bin/Vita3K
      rm -rf "$XDG_CONFIG_HOME/Vita3K"
      create_dir "$XDG_CONFIG_HOME/Vita3K"
      cp -fv "$component_config/config.yml" "$vita3k_config" # component config
      create_dir "$storage_path/psvita/Vita3K/"
      cp -frv "$component_config/ux0" "$storage_path/psvita/Vita3K/" # User config
      set_setting_value "$vita3k_config" "pref-path" "$storage_path/psvita/Vita3K/" "vita3k"
      dir_prep "$saves_path/psvita/vita3k" "$storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
      dir_prep "$texture_packs_path/Vita3K/import" "$vita3k_textures_path" # Textures
      dir_prep "$storage_path/psvita/Vita3K/lang"  "$vita3k_lang_path"
      dir_prep "$storage_path/psvita/Vita3K/patch"  "$vita3k_patch_path"
      dir_prep "$shaders_path/Vita3K/"  "$vita3k_shaders_path"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Vita3k"
      log i "------------------------"

      dir_prep "$saves_path/psvita/vita3k" "$storage_path/psvita/Vita3K/ux0/user/00/savedata" # Multi-user safe?
      dir_prep "$texture_packs_path/Vita3K/import" "$vita3k_textures_path" # Textures
      dir_prep "$storage_path/psvita/Vita3K/lang"  "$vita3k_lang_path"
      dir_prep "$storage_path/psvita/Vita3K/patch"  "$vita3k_patch_path"
      dir_prep "$shaders_path/Vita3K/"  "$vita3k_shaders_path"
      set_setting_value "$vita3k_config" "pref-path" "$storage_path/psvita/Vita3K/" "vita3k"
    ;;

  esac
}

_post_update::vita3k() {
  local previous_version="$1"

}

_post_update_legacy::vita3k() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

    prepare_component "reset" "vita3k"
  fi

  if check_version_is_older_than "$previous_version" "0.8.2b"; then
    log i "Vita3K changed some paths, reflecting them: moving \"$XDG_DATA_HOME/Vita3K\" in \"$XDG_CONFIG_HOME/Vita3K\""
    move "$XDG_DATA_HOME/Vita3K" "$XDG_CONFIG_HOME/Vita3K"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then

    log i "0.10.0b Upgrade - Postmove: Vita3K - Folder Creation"

    create_dir "$storage_path/psvita/Vita3K/"
    cp -frv "$vita3k_rd_config_dir/ux0" "$storage_path/psvita/Vita3K/" # User config
    prepare_component "postmove" "vita3k"
  fi
}
