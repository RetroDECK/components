#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

# TODO: do a proper script
# This is just a placeholder script to test the emulator's flow
log i "----------------------"
log i "Prepearing MAME"
log i "----------------------"

# TODO: probably some of these needs to be put elsewhere
create_dir "$saves_folder/mame-sa"
create_dir "$saves_folder/mame-sa/nvram"
create_dir "$states_folder/mame-sa"
create_dir "$rdhome/screenshots/mame-sa"
create_dir "$saves_folder/mame-sa/diff"

create_dir "$XDG_CONFIG_HOME/ctrlr"
create_dir "$XDG_CONFIG_HOME/mame/ini"
create_dir "$XDG_CONFIG_HOME/mame/cfg"
create_dir "$XDG_CONFIG_HOME/mame/inp"

create_dir "$XDG_DATA_HOME/mame/plugin-data"
create_dir "$XDG_DATA_HOME/mame/hash"
create_dir "$bios_folder/mame-sa/samples"
create_dir "$XDG_DATA_HOME/mame/assets/artwork"
create_dir "$XDG_DATA_HOME/mame/assets/fonts"
create_dir "$XDG_DATA_HOME/mame/assets/crosshair"
create_dir "$XDG_DATA_HOME/mame/plugins"
create_dir "$XDG_DATA_HOME/mame/assets/language"
create_dir "$XDG_DATA_HOME/mame/assets/software"
create_dir "$XDG_DATA_HOME/mame/assets/comments"
create_dir "$XDG_DATA_HOME/mame/assets/share"
create_dir "$XDG_DATA_HOME/mame/dats"
create_dir "$XDG_DATA_HOME/mame/folders"
create_dir "$XDG_DATA_HOME/mame/assets/cabinets"
create_dir "$XDG_DATA_HOME/mame/assets/cpanel"
create_dir "$XDG_DATA_HOME/mame/assets/pcb"
create_dir "$XDG_DATA_HOME/mame/assets/flyers"
create_dir "$XDG_DATA_HOME/mame/assets/titles"
create_dir "$XDG_DATA_HOME/mame/assets/ends"
create_dir "$XDG_DATA_HOME/mame/assets/marquees"
create_dir "$XDG_DATA_HOME/mame/assets/artwork-preview"
create_dir "$XDG_DATA_HOME/mame/assets/bosses"
create_dir "$XDG_DATA_HOME/mame/assets/logo"
create_dir "$XDG_DATA_HOME/mame/assets/scores"
create_dir "$XDG_DATA_HOME/mame/assets/versus"
create_dir "$XDG_DATA_HOME/mame/assets/gameover"
create_dir "$XDG_DATA_HOME/mame/assets/howto"
create_dir "$XDG_DATA_HOME/mame/assets/select"
create_dir "$XDG_DATA_HOME/mame/assets/icons"
create_dir "$XDG_DATA_HOME/mame/assets/covers"
create_dir "$XDG_DATA_HOME/mame/assets/ui"
create_dir "$shaders_folder/mame/bgfx/"

dir_prep "$saves_folder/mame-sa/hiscore" "$XDG_CONFIG_HOME/mame/hiscore"
cp -fvr "$config/mame.ini" "$mameconf"
cp -fvr "$config/ui.ini" "$mameuiconf"
cp -fvr "$config/default.cfg" "$mamedefconf"
cp -fvr "/app/retrodeck/components/mame/share/mame/bgfx/"* "$shaders_folder/mame/bgfx"

sed -i 's#RETRODECKROMSDIR#'"$roms_folder"'#g' "$mameconf" # one-off as roms folders are a lot
set_setting_value "$mameconf" "nvram_directory" "$saves_folder/mame-sa/nvram" "mame"
set_setting_value "$mameconf" "state_directory" "$states_folder/mame-sa" "mame"
set_setting_value "$mameconf" "snapshot_directory" "$screenshots_folder/mame-sa" "mame"
set_setting_value "$mameconf" "diff_directory" "$saves_folder/mame-sa/diff" "mame"
set_setting_value "$mameconf" "samplepath" "$bios_folder/mame-sa/samples" "mame"
set_setting_value "$mameconf" "cheatpath" "$cheats_folder/mame" "mame"
set_setting_value "$mameconf" "bgfx_path" "$shaders_folder/mame/bgfx/" "mame"

log i "Placing cheats in \"$cheats_folder/mame\""
unzip -j -o "$config/cheat0264.zip" 'cheat.7z' -d "$cheats_folder/mame"
