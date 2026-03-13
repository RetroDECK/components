#!/bin/bash

export mame_config="$XDG_CONFIG_HOME/mame/ini/mame.ini"
export mame_config_ui="$XDG_CONFIG_HOME/mame/ini/ui.ini"
export mame_config_default="$XDG_CONFIG_HOME/mame/cfg/default.cfg"

_set_setting_value::mame() {
  local file="$1"
  local name="$2"
  local value="$3"
  local section="${4:-}"

  if [[ "$file" =~ \.ini$ ]]; then
    local esc_name=$(sed_escape_pattern "$name")
    local esc_value=$(sed_escape_replacement "$value")
    sed -i 's^\(^'"$esc_name"'\s\+\).*^\1'"$esc_value"'^' "$file"

  elif [[ "$file" =~ \.cfg$ ]]; then
    local xpath="/mameconfig/system[@name='${section}']/input/port[@type='${name}']/newseq[@type='standard']"
    xml ed -L -u "$xpath" -v "$value" "$file"
  fi
}

_get_setting_value::mame() {
  local file="$1" name="$2" section="${3:-}"

  if [[ "$file" =~ \.ini$ ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $1 == key { $1=""; print substr($0, index($0,$2)); exit }' "$file"
  elif [[ "$file" =~ \.cfg$ ]]; then
    local xpath="/mameconfig/system[@name='${section}']/input/port[@type='${name}']/newseq[@type='standard']"
    xml sel -t -v "$xpath" "$file"
  fi
}

_prepare_component::mame() {
  local action="$1"
  shift

  local component_path="$(get_own_component_path)"
  local component_config="$(get_own_component_path)/rd_config"
  local component_extras="$(get_own_component_path)/rd_extras"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting MAME"
      log i "------------------------"

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
      cp -fvr "$component_path/share/mame/bgfx/"* "$shaders_path/mame/bgfx/"

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
    ;;

    postmove)
      log i "----------------------"
      log i "Post-moving MAME"
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
    ;;

  esac
}

_validate_for_compression::chd() {
  # Validate whether a file is a valid candidate for CHD compression.
  # USAGE: _validate_for_compression::chd "$input_file"

  local file="$1"
  local normalized_filename=$(echo "$file" | tr '[:upper:]' '[:lower:]')

  if echo "$normalized_filename" | grep -qE '\.iso|\.gdi'; then
    return 0
  fi

  if [[ "$normalized_filename" == *".cue" ]]; then
    local file_path=$(dirname "$(realpath "$file")")
    if [[ ! "$file_path" == *"dreamcast"* ]]; then # .bin/.cue compression may not work for Dreamcast, only GDI or ISO # TODO: verify
      log i "Validating .cue associated .bin files"
      local cue_bin_files=$(grep -o -P '(?<=FILE ").*(?=".*$)' "$file")
      log i "Associated bin files read:"
      log i "$(printf '%s\n' "$cue_bin_files")"
      if [[ -z "$cue_bin_files" ]]; then
        return 1
      fi
      while IFS= read -r line; do
        log i "Looking for $file_path/$line"
        if [[ ! -f "$file_path/$line" ]]; then
          log e ".bin file NOT found at $file_path/$line"
          log e ".cue file could not be validated. Please verify your .cue file contains the correct corresponding .bin file information and retry."
          return 1
        fi
      done <<< "$cue_bin_files"
      return 0
    fi
  fi

  return 1
}

_compress_game::chd() {
  # Compress a file to CHD format using chdman.
  # USAGE: _compress_game::chd "$source_file" "$dest_file_without_extension"

  local source_file="$1"
  local dest_file="$2"
  local system="$3"

  case "$system" in # Check platform-specific compression options
    "psp" )
      log d "Compressing PSP game $source_file into $dest_file"
      /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createdvd --hunksize 2048 -i "$source_file" -o "$dest_file".chd -c zstd
    ;;
    "ps2" )
      if [[ "$filename_extension" == "cue" ]]; then
        /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createcd -i "$source_file" -o "$dest_file".chd
      else
        /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createdvd -i "$source_file" -o "$dest_file".chd -c zstd
      fi
    ;;
    * )
      /bin/bash "$rd_components/mame/component_launcher.sh" chdman_compression createcd -i "$source_file" -o "$dest_file".chd
    ;;
  esac
}

_post_compression_cleanup::chd() {
  local file_to_cleanup="$1"
  log i "Removing $file_to_cleanup as part of post-compression cleanup"
  if [[ "$file_to_cleanup" == *".cue" ]]; then
    local file_path=$(dirname "$(realpath "$file_to_cleanup")")
    while IFS= read -r bin_file; do
      log i "Removing file $file_path/$bin_file"
      rm -f "$file_path/$bin_file"
    done < <(grep -o -P '(?<=FILE ").*(?=".*$)' "$file_to_cleanup")
  fi
  rm -f "$file_to_cleanup"
}

_post_update_legacy::mame() {
  local previous_version="$1"

}

_post_update_legacy::mame() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.8.0b"; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"

    prepare_component "reset" "mame"
  fi

  if check_version_is_older_than "$previous_version" "0.8.1b"; then
    log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"

    log i "MAME-SA, migrating samples to the new exposed folder: from \"$XDG_DATA_HOME/mame/assets/samples\" to \"$bios_path/mame-sa/samples\""
    create_dir "$bios_path/mame-sa/samples"
    mv -f "$XDG_DATA_HOME/mame/assets/samples/"* "$bios_path/mame-sa/samples"
    set_setting_value "$mameconf" "samplepath" "$bios_path/mame-sa/samples" "mame"

    log i "Placing cheats in \"$XDG_DATA_HOME/mame/cheat\""
    unzip -j -o "$config/mame/cheat0264.zip" 'cheat.7z' -d "$XDG_DATA_HOME/mame/cheat"
  fi

  if check_version_is_older_than "$previous_version" "0.9.1b"; then
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

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    log i "0.10.0b Upgrade - Reset: MAME"

    prepare_component "reset" "mame" # MAME needs to be reset because of major config changes.
  fi
}
