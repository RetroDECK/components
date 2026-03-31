#!/bin/bash

export pico8_config="$XDG_CONFIG_HOME/pico-8/config.txt"
export pico8_config_sdl_controllers="$XDG_CONFIG_HOME/pico-8/sdl_controllers.txt"

_set_setting_value::pico-8() {
  local file="$1"
  local name=$(sed_escape_pattern "$2")
  local value=$(sed_escape_replacement "$3")

  local sed_cmd
  # Lines with inline comments: preserve the comment
  sed_cmd='s^\(^'"$name"' \).*\( //.*\)^\1'"$value"'\2^; t end;'
  # Lines without comments
  sed_cmd+='s^\(^'"$name"' \).*^\1'"$value"'^; :end'

  sed -i "$sed_cmd" "$file"
}

_get_setting_value::pico-8() {
  local file="$1" name="$2"

  KEY="$name" SECTION="[$section]" awk -F'=' \
      'BEGIN { key=ENVIRON["KEY"]; section=ENVIRON["SECTION"] }
       index($0, key " ") == 1 {
       val = substr($0, length(key) + 2)
       idx = index(val, " //")
       if (idx > 0) val = substr(val, 1, idx - 1)
       gsub(/[[:space:]]+$/, "", val)
       print val; exit
     }' "$file"
}

_prepare_component::pico-8() {
  local action="$1"

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset|postmove)
      log i "------------------------"
      log i "Performing PICO-8 $action actions"
      log i "------------------------"

      if [[ -d "$roms_path/pico8" ]]; then
        dir_prep "$roms_path/pico8" "$bios_path/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
        dir_prep "$roms_path/pico8" "$bios_path/pico-8/bbs/carts" # Symlink spolre download location to RD roms
      fi
      dir_prep "$bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
      dir_prep "$saves_path/pico-8" "$bios_path/pico-8/cdata"  # PICO-8 saves folder
      create_dir "$XDG_CONFIG_HOME/pico-8/"
      cp -fv "$component_config/config.txt" "$pico8_config"
      cp -fv "$component_config/sdl_controllers.txt" "$pico8_config_sdl_controllers"
    ;;

    startup)
      log i "------------------------"
      log i "Performing PICO-8 $action actions"
      log i "------------------------"

      rsync -rlD --delete --mkpath "$roms_path/pico8/" "$esde_downloaded_media_path/pico8/covers/"
    ;;

  esac
}

_post_update::pico-8() {
  local previous_version="$1"

}

_post_update_legacy::pico-8() {
  # This function is to cover users upgrading from prior to 0.11.0, when per-component versioning was introduced. It can be removed once we are confident all users are running 0.11.0 or higher
  
  local previous_version="$1"

  if check_version_is_older_than "$previous_version" "0.6.2b"; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Fix PICO-8 folder structure. ROM and save folders are now sane and binary files will go into ~/retrodeck/bios/pico-8/

    mv "$bios_path/pico8" "$bios_path/pico8_olddata" # Move legacy (and incorrect / non-functional ) PICO-8 location for future cleanup / less confusion
    dir_prep "$bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$roms_path/pico8" "$bios_path/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    dir_prep "$bios_path/pico-8/cdata" "$saves_path/pico-8" # PICO-8 saves folder
  fi

  if check_version_is_older_than "$previous_version" "0.6.3b"; then
    # In version 0.6.3b, the following changes were made that required config file updates/reset:
    # - Fix symlink to hard-coded PICO-8 config folder (dir_prep doesn't like ~)

    rm -rf "$HOME/~/" # Remove old incorrect location from 0.6.2b
    rm -f "$HOME/.lexaloffle/pico-8" # Remove old symlink to prevent recursion
    dir_prep "$bios_path/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$saves_path/pico-8" "$bios_path/pico-8/cdata" # PICO-8 saves folder structure was backwards, fixing for consistency.
  fi

  if check_version_is_older_than "$previous_version" "0.7.0b"; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Init PICO-8 as it has newly-shipped config files

    prepare_component "reset" "pico-8"
  fi
}

configurator_splore_toggle_dialog() {
  if [[ ! $(get_component_option "pico-8" "splore_visible") == "false" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PICO-8 Splore Visibility" \
    --text="PICO-8 Splore visibility is currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to disable it?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      remove_gamelist_entry "pico-8" "pico8_splore"
      set_component_option "pico-8" "splore_visible" "false"
      
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PICO-8 Splore Visibility" \
      --text="PICO-8 Splore visibility is now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PICO-8 Splore Visibility" \
    --text="PICO-8 Splore visibility is currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      create_gamelist_entry "pico-8" "pico8_splore"
      set_component_option "pico-8" "splore_visible" "true"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PICO-8 Splore Visibility" \
      --text="PICO-8 Splore visibility is now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi
}
