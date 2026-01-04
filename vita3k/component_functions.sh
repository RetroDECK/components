#!/bin/bash

vita3k_config="$XDG_CONFIG_HOME/Vita3K/config.yml"
vita3k_config_user="$XDG_CONFIG_HOME/Vita3K/ux0/user/00/user.xml"
vita3k_vu_firmware_url="http://dus01.psv.update.playstation.net/update/psv/image/2022_0209/rel_f2c7b12fe85496ec88a0391b514d6e3b/PSVUPDAT.PUP"
vita3k_2u_firmware_url="http://dus01.psp2.update.playstation.net/update/psp2/image/2019_0924/sd_8b5f60b56c3da8365b973dba570c53a5/PSP2UPDAT.PUP?dest=us"
vita3k_component_dir="$rd_components/vita3k"
vita3k_textures_path="$storage_path/Vita3K/ux0/textures/import"
vita3k_lang_path="$XDG_DATA_HOME/Vita3K/lang"
vita3k_patch_path="$XDG_DATA_HOME/Vita3K/patch"
vita3k_shaders_path="$XDG_CACHE_HOME/Vita3K/shaders"

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
