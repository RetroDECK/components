#!/bin/bash

rpcs3_config="$XDG_CONFIG_HOME/rpcs3/config.yml"
rpcs3_config_evdev_positive_axis="$XDG_CONFIG_HOME/rpcs3/evdev_positive_axis.yml"
rpcs3_config_vfs="$XDG_CONFIG_HOME/rpcs3/vfs.yml"
rpcs3_gui_current_settings="$XDG_CONFIG_HOME/rpcs3/GuiConfigs/CurrentSettings.ini"
rpcs3_input_active_profiles="$XDG_CONFIG_HOME/rpcs3/input_configs/active_profiles.yml"
rpcs3_input_Default="$XDG_CONFIG_HOME/rpcs3/input_configs/global/Default.yml"
rpcs3_component_dir="$rd_components/rpcs3"
rpcs3_firmware="http://dus01.ps3.update.playstation.net/update/ps3/image/us/2025_0305_c179ad173bbc08b55431d30947725a4b/PS3UPDAT.PUP"

update_rpcs3_firmware() {
  if [[ $(check_network_connectivity) == "true" ]]; then
    configurator_generic_dialog "RetroDECK Configurator - Install: PS3 firmware" "This tool will download firmware required by RPCS3 to emulate PS3 games.\n\nThe process will take several minutes, and the emulator will launch to finish the installation.\nPlease close RPCS3 manually once the installation is complete."
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
    --title="Downloading PS3 Firmware" \
    --width=400 --height=200 \
    --text="Dowloading and installing PS3 Firmware, please be patient.\n\n<span foreground='$purple' size='larger'><b>NOTICE - If the process is taking too long:</b></span>\n\nSome windows might be running in the background that could require your attention: pop-ups from emulators or the upgrade itself that needs user input to continue.\n\n"
  else
    configurator_generic_dialog "RetroDECK Configurator - Install: PS3 Firmware" "You do not appear to currently have Internet access, which is required by this tool. Please try again when network access has been restored."
  fi
  configurator_tools_dialog
}
