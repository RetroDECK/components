#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

  prepare_component "reset" "mame"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.1b") == "true" ]]; then
  log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

  log i "MAME-SA, migrating samples to the new exposed folder: from \"$XDG_DATA_HOME/mame/assets/samples\" to \"$bios_folder/mame-sa/samples\""
  create_dir "$bios_folder/mame-sa/samples"
  mv -f "$XDG_DATA_HOME/mame/assets/samples/"* "$bios_folder/mame-sa/samples"
  set_setting_value "$mameconf" "samplepath" "$bios_folder/mame-sa/samples" "mame"

  log i "Placing cheats in \"$XDG_DATA_HOME/mame/cheat\""
  unzip -j -o "$config/mame/cheat0264.zip" 'cheat.7z' -d "$XDG_DATA_HOME/mame/cheat"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the shaders folder for MAME..."
  shaders_folder="$rdhome/shaders" && log i "Shaders folder set to \"$shaders_folder\""
  conf_write && log i "Done"
  create_dir "$shaders_folder/mame/bgfx"
  set_setting_value "$mameconf" "bgfx_path" "$shaders_folder/mame/bgfx/" "mame"
  cp -fvr "/app/share/mame/bgfx/"* "$shaders_folder/mame/bgfx"

  log i "Preparing the cheats for MAME..."
  create_dir "$cheats_folder/mame"
  set_setting_value "$mameconf" "cheatpath" "$cheats_folder/mame" "mame"
  unzip -j -o "$config/mame/cheat0264.zip" 'cheat.7z' -d "$cheats_folder/mame" && log i "Cheats for MAME installed"
  rm -rf "$XDG_DATA_HOME/mame/cheat"
fi
