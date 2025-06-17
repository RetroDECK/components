#!/bin/bash

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
config="/app/retrodeck/components/$component_name/rd_config"

mame_conf="$XDG_CONFIG_HOME/mame/ini/mame.ini"
mame_ui_conf="$XDG_CONFIG_HOME/mame/ini/ui.ini"
mame_default_conf="$XDG_CONFIG_HOME/mame/cfg/default.cfg"

# TODO: do a proper script
# This is just a placeholder script to test the emulator's flow
log i "----------------------"
log i "Preparing $component_name"
log i "----------------------"

# TODO: probably some of these needs to be put elsewhere
create_dir "$rd_home_saves_path/mame-sa"
create_dir "$rd_home_saves_path/mame-sa/nvram"
create_dir "$rd_home_states_path/mame-sa"
create_dir "$rd_home_path/screenshots/mame-sa"
create_dir "$rd_home_saves_path/mame-sa/diff"

create_dir "$XDG_CONFIG_HOME/ctrlr"
create_dir "$XDG_CONFIG_HOME/mame/ini"
create_dir "$XDG_CONFIG_HOME/mame/cfg"
create_dir "$XDG_CONFIG_HOME/mame/inp"

create_dir "$XDG_DATA_HOME/mame/plugin-data"
create_dir "$XDG_DATA_HOME/mame/hash"
create_dir "$rd_home_bios_path/mame-sa/samples"
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
create_dir "$rd_home_shaders_path/mame/bgfx/"

dir_prep "$rd_home_saves_path/mame-sa/hiscore" "$XDG_CONFIG_HOME/mame/hiscore"
cp -fvr "$config/mame.ini" "$mame_conf"
cp -fvr "$config/ui.ini" "$mame_ui_conf"
cp -fvr "$config/default.cfg" "$mame_default_conf"
cp -fvr "/app/retrodeck/components/mame/share/mame/bgfx/"* "$rd_home_shaders_path/mame/bgfx"

sed -i 's#RETRODECKROMSDIR#'"$rd_home_roms_path"'#g' "$mame_conf" # one-off as roms folders are a lot
set_setting_value "$mame_conf" "nvram_directory" "$rd_home_saves_path/mame-sa/nvram" "mame"
set_setting_value "$mame_conf" "state_directory" "$rd_home_states_path/mame-sa" "mame"
set_setting_value "$mame_conf" "snapshot_directory" "$rd_home_screenshots_path/mame-sa" "mame"
set_setting_value "$mame_conf" "diff_directory" "$rd_home_saves_path/mame-sa/diff" "mame"
set_setting_value "$mame_conf" "samplepath" "$rd_home_bios_path/mame-sa/samples" "mame"
set_setting_value "$mame_conf" "cheatpath" "$rd_home_cheats_path/mame" "mame"
set_setting_value "$mame_conf" "bgfx_path" "$rd_home_shaders_path/mame/bgfx/" "mame"

log i "Placing cheats in \"$rd_home_cheats_path/mame\""
unzip -j -o "$config/cheat0264.zip" 'cheat.7z' -d "$rd_home_cheats_path/mame"
