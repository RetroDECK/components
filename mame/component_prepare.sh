#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_config="/app/retrodeck/components/$component_name/rd_config"
component_extras="/app/retrodeck/components/$component_name/rd_extras"

if [[ "$action" == "reset" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Resetting $component_name"
  log i "----------------------"

  # Saves and States

  create_dir "$saves_path/mame-sa"
  create_dir "$saves_path/mame-sa/nvram"
  create_dir "$states_path/mame-sa"
  create_dir "$saves_path/mame-sa/diff"
  dir_prep "$saves_path/mame-sa/hiscore" "$XDG_CONFIG_HOME/mame/hiscore"

  # Screenshots

  create_dir "$screenshots_path/mame"

  # Configs

  create_dir "$XDG_CONFIG_HOME/mame/ctrlr"
  create_dir "$XDG_CONFIG_HOME/mame/ini"
  create_dir "$XDG_CONFIG_HOME/mame/cfg"
  create_dir "$XDG_CONFIG_HOME/mame/inp"

  # Mods

  create_dir "$mods_path/mame/plugin-data"
  create_dir "$mods_path/mame/plugins"

  # BIOS

  create_dir "$bios_path/mame-sa/samples"

  # Shaders

  create_dir "$shaders_path/mame/bgfx/"

  # Cheats

  create_dir "$cheats_path/mame"

  # Storage assets

  create_dir "$storage_path/mame/hash"
  create_dir "$storage_path/mame/artwork"
  create_dir "$storage_path/mame/fonts"
  create_dir "$storage_path/mame/crosshair"
  create_dir "$storage_path/mame/language"
  create_dir "$storage_path/mame/software"
  create_dir "$storage_path/mame/comments"
  create_dir "$storage_path/mame/share"
  create_dir "$storage_path/mame/dats"
  create_dir "$storage_path/mame/folders"
  create_dir "$storage_path/mame/cabinets"
  create_dir "$storage_path/mame/cpanel"
  create_dir "$storage_path/mame/pcb"
  create_dir "$storage_path/mame/flyers"
  create_dir "$storage_path/mame/titles"
  create_dir "$storage_path/mame/ends"
  create_dir "$storage_path/mame/marquees"
  create_dir "$storage_path/mame/artwork-preview"
  create_dir "$storage_path/mame/bosses"
  create_dir "$storage_path/mame/logo"
  create_dir "$storage_path/mame/scores"
  create_dir "$storage_path/mame/versus"
  create_dir "$storage_path/mame/gameover"
  create_dir "$storage_path/mame/howto"
  create_dir "$storage_path/mame/select"
  create_dir "$storage_path/mame/icons"
  create_dir "$storage_path/mame/covers"
  create_dir "$storage_path/mame/ui"

  # Copy configs

  cp -fv "$component_config/mame.ini" "$mame_config"
  cp -fv "$component_config/ui.ini" "$mame_config_ui"
  cp -fv "$component_config/default.cfg" "$mame_config_default"
  cp -fvr "$rd_components/mame/share/mame/bgfx/"* "$shaders_path/mame/bgfx/"

  # Set config values

  sed -i 's#RETRODECKROMSDIR#'"$roms_path"'#g' "$mame_config" # one-off as roms folders are a lot
  set_setting_value "$mame_config" "nvram_directory" "$saves_path/mame-sa/nvram" "mame"
  set_setting_value "$mame_config" "state_directory" "$states_path/mame-sa" "mame"
  set_setting_value "$mame_config" "snapshot_directory" "$screenshots_path/mame" "mame"
  set_setting_value "$mame_config" "diff_directory" "$saves_path/mame-sa/diff" "mame"
  set_setting_value "$mame_config" "samplepath" "$bios_path/mame-sa/samples" "mame"
  set_setting_value "$mame_config" "cheatpath" "$cheats_path/mame" "mame"
  set_setting_value "$mame_config" "bgfx_path" "$shaders_path/mame/bgfx/" "mame"
  set_setting_value "$mame_config" "homepath" "$mods_path/mame/plugin-data" "mame"
  set_setting_value "$mame_config" "pluginspath" "$mods_path/mame/plugins" "mame"

  log i "Placing cheats in \"$cheats_path/mame\""
  cheat_zip=$(find "$component_extras" -type f -iname cheat*.zip)
  unzip -j -o "$cheat_zip" 'cheat.7z' -d "$cheats_path/mame"
fi

if [[ "$action" == "postmove" ]]; then # Run reset-only commands
  log i "----------------------"
  log i "Post-moving $component_name"
  log i "----------------------"

  dir_prep "$saves_path/mame-sa/hiscore" "$XDG_CONFIG_HOME/mame/hiscore"

  sed -i 's#RETRODECKROMSDIR#'"$roms_path"'#g' "$mame_config" # one-off as roms folders are a lot
  set_setting_value "$mame_config" "nvram_directory" "$saves_path/mame-sa/nvram" "mame"
  set_setting_value "$mame_config" "state_directory" "$states_path/mame-sa" "mame"
  set_setting_value "$mame_config" "snapshot_directory" "$screenshots_path/mame" "mame"
  set_setting_value "$mame_config" "diff_directory" "$saves_path/mame-sa/diff" "mame"
  set_setting_value "$mame_config" "samplepath" "$bios_path/mame-sa/samples" "mame"
  set_setting_value "$mame_config" "cheatpath" "$cheats_path/mame" "mame"
  set_setting_value "$mame_config" "bgfx_path" "$shaders_path/mame/bgfx/" "mame"
  set_setting_value "$mame_config" "homepath" "$mods_path/mame/plugin-data" "mame"
  set_setting_value "$mame_config" "pluginspath" "$mods_path/mame/plugins" "mame"
fi