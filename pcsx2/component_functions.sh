#!/bin/bash

export pcsx2_config="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2.ini"
export pcsx2_config_PCSX2_vm="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2_vm.ini"
export pcsx2_config_PCSX2_ui="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2_ui.ini"
export pcsx2_config_GS="$XDG_CONFIG_HOME/PCSX2/inis/GS.ini"
export pcsx2_rd_config_dir="$rd_components/pcsx2/rd_config"
export pcsx2_rd_extras_dir="$rd_components/pcsx2/rd_extras"
export pcsx2_textures_path="$XDG_CONFIG_HOME/PCSX2/textures"
export pcsx2_vidoes_path="$XDG_CONFIG_HOME/PCSX2/videos"
export pcsx2_patches_path="$XDG_CONFIG_HOME/PCSX2/patches"
export pcsx2_cheats_path="$XDG_CONFIG_HOME/PCSX2/cheats"
export pcsx2_logs_path="$XDG_CONFIG_HOME/PCSX2/logs"
export pcsx2_secrets_ini="$XDG_CONFIG_HOME/PCSX2/inis/secrets.ini"

_set_setting_value::pcsx2() {
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

_get_setting_value::pcsx2() {
  local file="$1" name="$2" section="${3:-}"

  if [[ -n "$section" ]]; then
    KEY="$name" SECTION="[$section]" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       $0 == section { in_section=1; next }
       /^\[/ { in_section=0 }
       in_section && index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  else
    KEY="$name" awk -F'=' \
      'NR==1 { sub(/^\xEF\xBB\xBF/, "") }
       BEGIN { key=ENVIRON["KEY"] }
       index($0, key " =") == 1 {
         print substr($0, index($0,"=")+2); exit
       }' "$file"
  fi
}

_prepare_component::pcsx2() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"
  local component_extras="$(get_own_component_path)/rd_extras"

  case "$action" in

    reset)
      log i "------------------------"
      log i "Resetting PCSX2"
      log i "------------------------"

      # General Folders
      create_dir -d "$XDG_CONFIG_HOME/PCSX2/inis"
      cp -fvr "$component_config/"* "$XDG_CONFIG_HOME/PCSX2/inis"
      set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"

      # Screenshots
      create_dir -d "$screenshots_path/PCSX2"
      set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path/PCSX2" "pcsx2" "Folders"

      # Saves
      create_dir "$states_path/ps2/pcsx2"
      set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
      create_dir "$saves_path/ps2/pcsx2/memcards"
      set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"

      # Logs
      create_dir -d "$logs_path/PCSX2"
      set_setting_value "$pcsx2_config" "Logs" "$logs_path/PCSX2" "pcsx2" "Folders"

      # Cheats
      create_dir -d "$cheats_path/PCSX2/cheats_ws"
      create_dir -d "$cheats_path/PCSX2/cheats_ni"
      tar -xzf "$component_extras/pcsx2-cheats.tar.gz" -C "$cheats_path/PCSX2" --overwrite
      set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "CheatsWS" "$cheats_path/PCSX2/cheats_ws" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "CheatsNI" "$cheats_path/PCSX2/cheats_ni" "pcsx2" "Folders"

      # Covers
      create_dir -d "$storage_path/PCSX2/covers"
      set_setting_value "$pcsx2_config" "Covers" "$storage_path/PCSX2/covers" "pcsx2" "Folders"

      # Textures
      create_dir -d "$texture_packs_path/PCSX2/textures"
      set_setting_value "$pcsx2_config" "Textures" "$texture_packs_path/PCSX2/textures" "pcsx2" "Folders"

      # Textures
      create_dir -d "$videos_path/PCSX2"
      set_setting_value "$pcsx2_config" "Videos" "$videos_path/PCSX2" "pcsx2" "Folders"

      # Mods
      dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"

      ## Backups Old Cheats
      if [[ -d "$cheats_path/PCSX2" && "$(ls -A "$cheats_path/PCSX2")" ]]; then
        backup_file="$backups_path/cheats/PCSX2-$(date +%y%m%d).tar.gz"
        create_dir "$(dirname "$backup_file")"
        tar -czf "$backup_file" -C "$cheats_path" PCSX2
        log i "PCSX2 cheats backed up to $backup_file"
      fi

      ## Backups Mods / Patches
      if [[ -d "$mods_path/PCSX2" && "$(ls -A "$mods_path/PCSX2")" ]]; then
        backup_file="$backups_path/mods/PCSX2-$(date +%y%m%d).tar.gz"
        create_dir "$(dirname "$backup_file")"
        tar -czf "$backup_file" -C "$mods_path" PCSX2
        log i "PCSX2 patches backed up to $backup_file"
      fi
      tar -xzf "$component_extras/pcsx2-patches.tar.gz" -C "$mods_path/PCSX2/patches" --overwrite
    ;;

    postmove)
      log i "------------------------"
      log i "Post-moving PCSX2"
      log i "------------------------"

      set_setting_value "$pcsx2_config" "Bios" "$bios_path" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "RecursivePaths" "$roms_path/ps2" "pcsx2" "GameList"
      set_setting_value "$pcsx2_config" "Snapshots" "$screenshots_path/PCSX2" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "SaveStates" "$states_path/ps2/pcsx2" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "MemoryCards" "$saves_path/ps2/pcsx2/memcards" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "Logs" "$logs_path/PCSX2/" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "CheatsWS" "$cheats_path/PCSX2/cheats_ws" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "CheatsNI" "$cheats_path/PCSX2/cheats_ni" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "Covers" "$storage_path/PCSX2/covers" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "Textures" "$texture_packs_path/PCSX2/textures" "pcsx2" "Folders"
      set_setting_value "$pcsx2_config" "Videos" "$videos_path/PCSX2/" "pcsx2" "Folders"
      dir_prep "$mods_path/PCSX2/patches" "$pcsx2_patches_path"
    ;;

  esac
}

_post_update::pcsx2() {
  local previous_version="$1"

}

_post_update_legacy::pcsx2() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Update PCSX2 and Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
    # - Disable auto-save/load in existing RA / PCSX2 / Duckstation installs for proper preset functionality

    mv -f "$pcsx2_config" "$pcsx2_config.bak"
    generate_single_patch "$config/PCSX2/PCSX2.ini" "$pcsx2_config.bak" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" pcsx2
    deploy_single_patch "$config/PCSX2/PCSX2.ini" "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch" "$pcsx2_config"
    rm -f "$XDG_CONFIG_HOME/PCSX2/inis/PCSX2-cheevos-upgrade.patch"

    dir_prep "$texture_packs_path/PCSX2/textures" "$pcsx2_textures_path"

    set_setting_value "$pcsx2_config" "SaveStateOnShutdown" "false" "pcsx2" "EmuCore"
  fi

  if check_version_is_older_than "$previous_version" "0.9.1b"; then
    log i "Preparing the cheats for PCSX2..."
    create_dir "$cheats_path/PCSX2"
    set_setting_value "$pcsx2_config" "Cheats" "$cheats_path/PCSX2" "pcsx2" "Folders"
    tar --strip-components=1 -xzf "/app/retrodeck/cheats/pcsx2.tar.gz" -C "$cheats_path/PCSX2" --overwrite && log i "Cheats for PCSX2 installed"
  fi

  if check_version_is_older_than "$previous_version" "0.10.0b"; then
    log i "0.10.0b Upgrade: PCSX2 - Postmove, mods and cheats and folder creation"

    create_dir -d "$screenshots_path/PCSX2"
    create_dir -d "$logs_path/PCSX2"
    create_dir -d "$cheats_path/PCSX2/cheats_ws"
    create_dir -d "$cheats_path/PCSX2/cheats_ni"
    move "$cheats_path/pcsx2" "$cheats_path/PCSX2"
    tar -xzf "$pcsx2_rd_extras_dir/pcsx2-cheats.tar.gz" -C "$cheats_path/PCSX2" --overwrite
    create_dir -d "$storage_path/PCSX2/covers"
    create_dir -d "$texture_packs_path/PCSX2/textures"
    create_dir -d "$videos_path/PCSX2"
    prepare_component "postmove" "pcsx2"
    tar -xzf "$pcsx2_rd_extras_dir/pcsx2-patches.tar.gz" -C "$mods_path/PCSX2/patches" --overwrite

    set_setting_value "$pcsx2_config" "Renderer" "-1" "pcsx2" "EmuCore/GS"
  fi
}
