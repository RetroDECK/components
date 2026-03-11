#!/bin/bash

export duckstation_config="$XDG_CONFIG_HOME/duckstation/settings.ini"
export duckstation_rd_config_dir="$rd_components/duckstation/rd_config"
export duckstation_textures_path="$XDG_CONFIG_HOME/duckstation/textures"
export duckstation_screenshots_path="$XDG_CONFIG_HOME/duckstation/screenshots"
export duckstation_videos_path="$XDG_CONFIG_HOME/duckstation/videos"
export duckstation_gamesettings_path="$XDG_CONFIG_HOME/duckstation/gamesettings"
export duckstation_shaders_path="$XDG_CONFIG_HOME/duckstation/shaders"
export duckstation_dump_textures_path="$XDG_CONFIG_HOME/duckstation/dump/textures"
export duckstation_dump_audio_path="$XDG_CONFIG_HOME/duckstation/dump/audio"
export duckstation_covers_path="$XDG_CONFIG_HOME/duckstation/covers"

_set_setting_value::duckstation() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")
  local section="${4:-}"

  if [[ -n "$section" ]]; then
    section=$(sed_escape_pattern "$section")
    sed -i '\^\['"$section"'\]^,\^\^'"$name"' =^s^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  else
    sed -i 's^\^'"$name"' =.*^'"$name"' = '"$value"'^' "$file"
  fi
}

_get_setting_value::duckstation() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    awk -v section="[$section]" -v key="$name" \
      '$0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    awk -v key="$name" \
      'index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  fi
}

_prepare_component::duckstation() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting Duckstation"
      log i "------------------------"
      
      create_dir -d "$XDG_CONFIG_HOME/duckstation/"
      create_dir "$saves_path/psx/duckstation/memcards"
      cp -fv "$component_config/"* "$XDG_CONFIG_HOME/duckstation"
      set_setting_value "$duckstation_config" "SearchDirectory" "$bios_path" "duckstation" "BIOS"
      set_setting_value "$duckstation_config" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
      dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
      dir_prep "$texture_packs_path/Duckstation/textures" "$duckstation_textures_path"
      dir_prep "$screenshots_path/Duckstation/" "$duckstation_screenshots_path"
      dir_prep "$shaders_path/Duckstation/" "$duckstation_shaders_path"
      dir_prep "$storage_path/Duckstation/dump/textures" "$duckstation_dump_textures_path"
      dir_prep "$storage_path/Duckstation/dump/audio" "$duckstation_dump_audio_path"
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving Duckstation"
      log i "------------------------"

      set_setting_value "$duckstation_config" "SearchDirectory" "$bios_path" "duckstation" "BIOS"
      set_setting_value "$duckstation_config" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
      set_setting_value "$duckstation_config" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
      dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates" # This is hard-coded in Duckstation, always needed
      dir_prep "$texture_packs_path/Duckstation/textures" "$duckstation_textures_path"
      dir_prep "$screenshots_path/Duckstation/" "$duckstation_screenshots_path"
      dir_prep "$shaders_path/Duckstation/" "$duckstation_shaders_path"
      dir_prep "$storage_path/Duckstation/dump/textures" "$duckstation_dump_textures_path"
      dir_prep "$storage_path/Duckstation/dump/audio" "$duckstation_dump_audio_path"
    ;;

  esac
}

_post_update::duckstation() {
  local previous_version="$1"

}

_post_update_legacy::duckstation() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.6.2b"; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!

    dir_prep "$rdhome/saves/duckstation" "$XDG_DATA_HOME/duckstation/memcards"
    dir_prep "$rdhome/states/duckstation" "$XDG_DATA_HOME/duckstation/savestates"
  fi

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Update Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
    # - Move Duckstation saves and states to new locations
    # - Disable ask-on-exit in existing Duckstation installs for proper preset functionality

    dir_prep "$XDG_CONFIG_HOME/duckstation" "$XDG_DATA_HOME/duckstation"
    mv -f "$duckstationconf" "$duckstationconf.bak"
    generate_single_patch "$config/duckstation/settings.ini" "$duckstationconf.bak" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" pcsx2
    deploy_single_patch "$config/duckstation/settings.ini" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" "$duckstationconf"
    rm -f "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch"

    if [[ -f "$saves_path/duckstation/shared_card_1.mcd" || -f "$saves_path/duckstation/shared_card_2.mcd" ]]; then
      configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update, the location of saves and states for Duckstation has been changed.\n\nYour files will be moved automatically, and can now be found at\n\n~.../saves/psx/duckstation/memcards/\nand\n~.../states/psx/duckstation/"
    fi
    create_dir "$saves_path/psx/duckstation/memcards"
    mv "$saves_path/duckstation/"* "$saves_path/psx/duckstation/memcards/"
    rmdir "$saves_path/duckstation" # File-safe folder cleanup
    unlink "$XDG_CONFIG_HOME/duckstation/memcards"
    set_setting_value "$duckstationconf" "Card1Path" "$saves_path/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Card2Path" "$saves_path/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Directory" "$saves_path/psx/duckstation/memcards" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "RecursivePaths" "$roms_path/psx" "duckstation" "GameList"
    create_dir "$states_path/psx"
    mv -t "$states_path/psx/" "$states_path/duckstation"
    unlink "$XDG_CONFIG_HOME/duckstation/savestates"
    dir_prep "$states_path/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates"

    set_setting_value "$duckstationconf" "SaveStateOnExit" "false" "duckstation" "Main"
    set_setting_value "$duckstationconf" "Enabled" "false" "duckstation" "Cheevos"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then

    log i "0.10.0b Upgrade - Postmove: Duckstation (Legacy)"

    prepare_component "postmove" "duckstation"
  fi
}
