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

  log i "MAME-SA, migrating samples to the new exposed folder: from \"$XDG_DATA_HOME/mame/assets/samples\" to \"$bios_path/mame-sa/samples\""
  create_dir "$bios_path/mame-sa/samples"
  mv -f "$XDG_DATA_HOME/mame/assets/samples/"* "$bios_path/mame-sa/samples"
  set_setting_value "$mameconf" "samplepath" "$bios_path/mame-sa/samples" "mame"

  log i "Placing cheats in \"$XDG_DATA_HOME/mame/cheat\""
  unzip -j -o "$config/mame/cheat0264.zip" 'cheat.7z' -d "$XDG_DATA_HOME/mame/cheat"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Preparing the shaders folder for MAME..."
  shaders_folder="$rdhome/shaders" && log i "Shaders folder set to \"$shaders_path\""
  conf_write && log i "Done"
  create_dir "$shaders_path/mame/bgfx"
  set_setting_value "$mameconf" "bgfx_path" "$shaders_path/mame/bgfx/" "mame"
  cp -fvr "/app/share/mame/bgfx/"* "$shaders_path/mame/bgfx"

  log i "Preparing the cheats for MAME..."
  create_dir "$cheats_path/mame"
  set_setting_value "$mameconf" "cheatpath" "$cheats_path/mame" "mame"
  unzip -j -o "$config/mame/cheat0264.zip" 'cheat.7z' -d "$cheats_path/mame" && log i "Cheats for MAME installed"
  rm -rf "$XDG_DATA_HOME/mame/cheat"
fi

# Legacy XDG Folders

# create_dir "$XDG_DATA_HOME/mame/plugin-data"
# create_dir "$XDG_DATA_HOME/mame/hash"
# create_dir "$XDG_DATA_HOME/mame/assets/artwork"
# create_dir "$XDG_DATA_HOME/mame/assets/fonts"
# create_dir "$XDG_DATA_HOME/mame/assets/crosshair"
# create_dir "$XDG_DATA_HOME/mame/plugins"
# create_dir "$XDG_DATA_HOME/mame/assets/language"
# create_dir "$XDG_DATA_HOME/mame/assets/software"
# create_dir "$XDG_DATA_HOME/mame/assets/comments"
# create_dir "$XDG_DATA_HOME/mame/assets/share"
# create_dir "$XDG_DATA_HOME/mame/dats"
# create_dir "$XDG_DATA_HOME/mame/folders"
# create_dir "$XDG_DATA_HOME/mame/assets/cabinets"
# create_dir "$XDG_DATA_HOME/mame/assets/cpanel"
# create_dir "$XDG_DATA_HOME/mame/assets/pcb"
# create_dir "$XDG_DATA_HOME/mame/assets/flyers"
# create_dir "$XDG_DATA_HOME/mame/assets/titles"
# create_dir "$XDG_DATA_HOME/mame/assets/ends"
# create_dir "$XDG_DATA_HOME/mame/assets/marquees"
# create_dir "$XDG_DATA_HOME/mame/assets/artwork-preview"
# create_dir "$XDG_DATA_HOME/mame/assets/bosses"
# create_dir "$XDG_DATA_HOME/mame/assets/logo"
# create_dir "$XDG_DATA_HOME/mame/assets/scores"
# create_dir "$XDG_DATA_HOME/mame/assets/versus"
# create_dir "$XDG_DATA_HOME/mame/assets/gameover"
# create_dir "$XDG_DATA_HOME/mame/assets/howto"
# create_dir "$XDG_DATA_HOME/mame/assets/select"
# create_dir "$XDG_DATA_HOME/mame/assets/icons"
# create_dir "$XDG_DATA_HOME/mame/assets/covers"
# create_dir "$XDG_DATA_HOME/mame/assets/ui"
