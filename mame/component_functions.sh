#!/bin/bash

mame_config="$XDG_CONFIG_HOME/mame/ini/mame.ini"
mame_config_ui="$XDG_CONFIG_HOME/mame/ini/ui.ini"
mame_config_default="$XDG_CONFIG_HOME/mame/cfg/default.cfg"

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
    awk -v key="$name" \
      '$1 == key { $1=""; print substr($0, index($0,$2)); exit }' "$file"
  elif [[ "$file" =~ \.cfg$ ]]; then
    local xpath="/mameconfig/system[@name='${section}']/input/port[@type='${name}']/newseq[@type='standard']"
    xml sel -t -v "$xpath" "$file"
  fi
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
