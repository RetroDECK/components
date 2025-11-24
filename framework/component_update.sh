#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.2b") == "true" ]]; then
  # In version 0.6.2b, the following changes were made that required config file updates/reset:
  # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!

  dir_prep "$rdhome/saves/duckstation" "$XDG_DATA_HOME/duckstation/memcards"
  dir_prep "$rdhome/states/duckstation" "$XDG_DATA_HOME/duckstation/savestates"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.3b") == "true" ]]; then
  # In version 0.6.3b, the following changes were made that required config file updates/reset:
  # - Overwrite Citra and Yuzu configs, as controller mapping was broken due to emulator updates.

  cp -f "$config/citra/qt-config.ini" "$XDG_CONFIG_HOME/citra-emu/qt-config.ini"
  sed -i 's#RETRODECKHOMEDIR#'"$rdhome"'#g' "$XDG_CONFIG_HOME/citra-emu/qt-config.ini"
  cp -fr "$config/yuzu/"* "$XDG_CONFIG_HOME/yuzu/"
  sed -i 's#RETRODECKHOMEDIR#'"$rdhome"'#g' "$XDG_CONFIG_HOME/yuzu/qt-config.ini"

  # Remove unneeded tools folder, as location has changed to RO space
  rm -rfv "$XDG_CONFIG_HOME/retrodeck/tools/"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.4b") == "true" ]]; then
  # In version 0.6.4b, the following changes were made:
  # Changed settings in Primehack: The audio output was not selected by default, default AR was also incorrect.
  # Changed settings in Duckstation and PCSX2: The "ask on exit" was disabled and "save on exit" was enabled.
  # The default configs have been updated for new installs and resets, a patch was created to address existing installs.

  deploy_multi_patch "config/patches/updates/064b_update.patch"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.6.5b") == "true" ]]; then
  # In version 0.6.5b, the following changes were made:
  # Change Yuzu GPU accuracy to normal for better performance

  set_setting_value "$yuzuconf" "gpu_accuracy" "0" "yuzu" "Renderer"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.7.0b") == "true" ]]; then
  # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # - Update retrodeck.cfg and set new paths to $rdhome by default
  # - Update Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from $XDG_DATA_HOME to $XDG_CONFIG_HOME
  # - New ~/retrodeck/mods and ~/retrodeck/texture_packs directories are added and symlinked to multiple different emulators (where supported)
  # - Move Duckstation saves and states to new locations
  # - Clean up legacy tools files (Configurator is now accessible through the main ES-DE menu)
  # - Disable auto-save/load in existing Duckstation installs for proper preset functionality
  # - Disable ask-on-exit in existing Duckstation installs for proper preset functionality

  update_rd_conf # Expand retrodeck.cfg to latest template
  set_setting_value "$rd_conf" "screenshots_folder" "$rdhome/screenshots"
  set_setting_value "$rd_conf" "mods_folder" "$rdhome/mods"
  set_setting_value "$rd_conf" "texture_packs_folder" "$rdhome/texture_packs"
  set_setting_value "$rd_conf" "borders_folder" "$rdhome/borders"
  conf_read

  dir_prep "$XDG_CONFIG_HOME/duckstation" "$XDG_DATA_HOME/duckstation"
  mv -f "$duckstationconf" "$duckstationconf.bak"
  generate_single_patch "$config/duckstation/settings.ini" "$duckstationconf.bak" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" pcsx2
  deploy_single_patch "$config/duckstation/settings.ini" "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch" "$duckstationconf"
  rm -f "$XDG_CONFIG_HOME/duckstation/duckstation-cheevos-upgrade.patch"

  create_dir "$mods_folder"
  create_dir "$texture_packs_folder"
  create_dir "$borders_folder"

  dir_prep "$mods_folder/Citra" "$XDG_DATA_HOME/citra-emu/load/mods"
  dir_prep "$texture_packs_folder/Citra" "$XDG_DATA_HOME/citra-emu/load/textures"
  dir_prep "$mods_folder/Yuzu" "$XDG_DATA_HOME/yuzu/load"
  dir_prep "$texture_packs_folder/Duckstation" "$XDG_CONFIG_HOME/duckstation/textures"

  if [[ -f "$saves_folder/duckstation/shared_card_1.mcd" || -f "$saves_folder/duckstation/shared_card_2.mcd" ]]; then
    configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update, the location of saves and states for Duckstation has been changed.\n\nYour files will be moved automatically, and can now be found at\n\n~.../saves/psx/duckstation/memcards/\nand\n~.../states/psx/duckstation/"
  fi
  create_dir "$saves_folder/psx/duckstation/memcards"
  mv "$saves_folder/duckstation/"* "$saves_folder/psx/duckstation/memcards/"
  rmdir "$saves_folder/duckstation" # File-safe folder cleanup
  unlink "$XDG_CONFIG_HOME/duckstation/memcards"
  set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
  set_setting_value "$duckstationconf" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
  create_dir "$states_folder/psx"
  mv -t "$states_folder/psx/" "$states_folder/duckstation"
  unlink "$XDG_CONFIG_HOME/duckstation/savestates"
  dir_prep "$states_folder/psx/duckstation" "$XDG_CONFIG_HOME/duckstation/savestates"

  rm -rf "$XDG_CONFIG_HOME/retrodeck/tools"

  set_setting_value "$duckstationconf" "SaveStateOnExit" "false" "duckstation" "Main"
  set_setting_value "$duckstationconf" "Enabled" "false" "duckstation" "Cheevos"

  set_setting_value "$citraconf" "confirmClose" "false" "citra" "UI"
  set_setting_value "$citraconf" "confirmClose\default" "false" "citra" "UI"
  set_setting_value "$duckstationconf" "ConfirmPowerOff" "false" "duckstation" "Main"

  configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "Would you like to install the official controller profile?\n(this will reset your custom emulator settings)\n\nAfter installation you can enable it from from Controller Settings\t->\tTemplates."
  if [[ $(configurator_generic_question_dialog "RetroDECK Official Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
    install_retrodeck_controller_profile
    prepare_component "reset" "all"
  fi
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.0b") == "true" ]]; then
  log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- Remove RetroDECK controller profile from existing template location"
  log i "- Change section name in retrodeck.cfg for ABXY button swap preset"

  # Removing old controller configs
  local controller_configs_path="$HOME/.steam/steam/controller_base/templates"
  local controller_configs=(
    "$controller_configs_path/RetroDECK_controller_config.vdf"
    "$controller_configs_path/RetroDECK_controller_generic_standard.vdf"
    "$controller_configs_path/RetroDECK_controller_ps3_dualshock3.vdf"
    "$controller_configs_path/RetroDECK_controller_ps4_dualshock4.vdf"
    "$controller_configs_path/RetroDECK_controller_ps5_dualsense.vdf"
    "$controller_configs_path/RetroDECK_controller_steam_controller_gordon.vdf"
    "$controller_configs_path/RetroDECK_controller_neptune.vdf"
    "$controller_configs_path/RetroDECK_controller_switch_pro.vdf"
    "$controller_configs_path/RetroDECK_controller_xbox360.vdf"
    "$controller_configs_path/RetroDECK_controller_xboxone.vdf"
  )

  for this_vdf in "${controller_configs[@]}"; do
    if [[ -f "$this_vdf" ]]; then
      log d "Found an old Steam Controller profile, removing it: \"$this_vdf\""
      rm -f "$this_vdf"
    fi
  done

  log d "Renaming \"nintendo_button_layout\" into \"abxy_button_swap\" in the retrodeck config file: \"$rd_conf\""
  sed -i 's^nintendo_button_layout^abxy_button_swap^' "$rd_conf" # This is a one-off sed statement as there are no functions for replacing section names

  if [ -d "$rdhome/.logs" ]; then
    mv "$rdhome/.logs" "$logs_folder"
    log i "Old log folder \"$rdhome/.logs\" found. Renamed it as \"$logs_folder\""
  fi

  log i "Switch firmware folder should be moved in \"$bios_folder/switch/firmware\" from \"$bios_folder/switch/registered\""
  mv "$bios_folder/switch/registered" "$bios_folder/switch/firmware"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.1b") == "true" ]]; then
  log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
  log i "- Give the user the option to reset Ryujinx, which was not properly initialized in 0.8.0b"

  log d "Verifying with user if they want to reset Ryujinx"
  if [[ "$(configurator_generic_question_dialog "RetroDECK 0.8.1b Ryujinx Reset" "In RetroDECK 0.8.0b the Ryujinx emulator was not properly initialized for upgrading users.\nThis would cause Ryujinx to not work properly.\n\nWould you like to reset Ryujinx to default RetroDECK settings now?\n\nIf you have made your own changes to the Ryujinx config, you can decline this reset.")" == "true" ]]; then
    log d "User agreed to Ryujinx reset"
    prepare_component "reset" "ryujinx"
  fi
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.2b") == "true" ]]; then
  log i "Moving ES-DE downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\" due to a RetroDECK Framework bug"
  move "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" in \"$rdhome/ES-DE\" folder completed"
  move "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" in \"$rdhome/ES-DE\" folder completed"
  move "$rdhome/gamelists" "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" in \"$rdhome/ES-DE\" folder completed"
  move "$rdhome/collections" "$rdhome/ES-DE/collections" && log d "Move of \"$rdhome/collections/\" in \"$rdhome/ES-DE\" folder completed"
  log i "Since in this version we moved to a PR build of Ryujinx we need to symlink it."
  ln -sv "$ryujinxconf" "$(dirname "$ryujinxconf")/PRConfig.json"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.3b") == "true" ]]; then
  # In version 0.8.3b, the following changes were made:
  # - Recovery from a failed move of the themes, downloaded_media and gamelists folder to their new ES-DE locations.
  if [[ ! -d "$rdhome/ES-DE/themes" || ! -d "$rdhome/ES-DE/downloaded_media" || ! -d "$rdhome/ES-DE/gamelists" ]]; then
    log i "Moving ES-DE downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\" due to a RetroDECK Framework bug"

    # Ask user if they want to move and overwrite the data
    if [[ $(configurator_generic_question_dialog "Move Data" "In the previous version some users suffered a bug where ES-DE appeared empty (no scraped data or collections for example).\n\n<span foreground='$purple' size='larger'><b>Your data is not gone!</b></span>\n\nit's just in a different path.\n\nDo you want to recover your old data replacing the actual one?\nBy choosing no instead, the folder with be moved but no data will be replaced and it will be availalbe in the retrodeck folder.\n\nThe affected folders are:\n\nretrodeck/themes\t\t\t\t->\t\"$rdhome/ES-DE\"/themes\nretrodeck/downloaded_media\t->\t\"$rdhome/ES-DE\"/downloaded_media\nretrodeck/gamelists\t\t\t\t->\t\"$rdhome/ES-DE\"/gamelist\nretrodeck/collections\t\t\t->\t\"$rdhome/ES-DE\"/collections") == "true" ]]; then
      move_cmd="mv -f"  # Use mv with overwrite
      log i "User chose to move and overwrite the data."
    else
      move_cmd="move"  # Use existing move function
      log i "User chose to move the data without overwriting."
    fi
  fi
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.8.4b") == "true" ]]; then
  # In version 0.8.4b, the following changes were made:
  # - Recovery from a failed move of the themes, downloaded_media and gamelists folder to their new ES-DE locations (AGAIN)

  log d "Injecting the new retrodeck/ES-DE subdir into the retrodeck.cfg"
  # Check if ES-DE already exists in media_folder or themes_folder
  if grep -E '^(media_folder|themes_folder)=.*ES-DE' "$rd_conf"; then
    log d "ES-DE path already exists in media_folder or themes_folder"
  else
    # Update the paths if ES-DE does not exist
    sed -i -e '/media_folder=/s|retrodeck/|retrodeck/ES-DE/|g' -e '/themes_folder=/s|retrodeck/|retrodeck/ES-DE/|g' "$rd_conf" && log d "Injection successful"
  fi
  log d "$(grep media_folder "$rd_conf")"
  log d "$(grep themes_folder "$rd_conf")"
  conf_read
  conf_write

  log i "Checking if ES-DE downloaded_media, gamelist, and themes folder must be migrated from \"$rdhome\" to \"$rdhome/ES-DE\" due to a RetroDECK Framework bug"

  # Use rsync to merge directories and overwrite existing files
  if [[ -d "$rdhome/themes" ]]; then
    rsync -a "$rdhome/themes/" "$rdhome/ES-DE/themes/" && log d "Move of \"$rdhome/themes\" to \"$rdhome/ES-DE/themes\" completed"
    rm -rf "$rdhome/themes" # Remove the original directory after merging
  else
    log i "ES-DE themes appear to have already been migrated."
  fi

  if [[ -d "$rdhome/downloaded_media" ]]; then
    rsync -a "$rdhome/downloaded_media/" "$rdhome/ES-DE/downloaded_media/" && log d "Move of \"$rdhome/downloaded_media\" to \"$rdhome/ES-DE/downloaded_media\" completed"
    rm -rf "$rdhome/downloaded_media" # Remove the original directory after merging
  else
    log i "ES-DE downloaded media appear to have already been migrated."
  fi

  if [[ -d "$rdhome/gamelists" ]]; then
    rsync -a "$rdhome/gamelists/" "$rdhome/ES-DE/gamelists/" && log d "Move of \"$rdhome/gamelists\" to \"$rdhome/ES-DE/gamelists\" completed"
    rm -rf "$rdhome/gamelists" # Remove the original directory after merging
  else
    log i "ES-DE gamelists appear to have already been migrated."
  fi

  if [[ -d "$rdhome/collections" ]]; then
    rsync -a "$rdhome/collections/" "$rdhome/ES-DE/collections/" && log d "Move of \"$rdhome/collections\" to \"$rdhome/ES-DE/collections\" completed"
    rm -rf "$rdhome/collections" # Remove the original directory after merging
  else
    log i "ES-DE collections appear to have already been migrated."
  fi

  # Setting the correct variables once again
  set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
  set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.0b") == "true" ]]; then
  # Create a Zenity window with checkboxes for each reset option and two buttons
  while true; do
    choices=$(rd_zenity --list --checklist --title="RetroDECK Reset Options" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="The following components have been updated and need to be reset or fixed to ensure compatibility with the new version: select the components you want to reset.\n\nNot resetting them may cause serious issues with your installation.\nYou can also reset them manually later via Configurator -> Troubleshooting -> Reset Component.\n\nNote: Your games, saves, game collections and scraped data will not be affected." \
    --column="Select" --column="Component" --column="Description" --width="1100" --height="700" \
    TRUE "ES-DE" "Needs to be reset to accommodate new paths, theme settings, and general configurations" \
    TRUE "Duckstation" "Configuration reset to RetroDECK defaults to ensure compatibility" \
    TRUE "Ryujinx" "Configuration reset, firmware might need to be reinstalled by user" \
    TRUE "Dolphin" "Setting screen size to 'Auto' instead of 'Widescreen' to ensure better game compatibility" \
    TRUE "Primehack" "Setting screen size to 'Auto' instead of 'Widescreen' to ensure better game compatibility" \
    --separator=":" \
    --extra-button="Execute All" \
    --ok-label="Execute Selected Only" \
    --cancel-label="Execute None")

    log d "User selected: $choices"
    log d "User pressed: $?"

    # Check if "Execute All" button was pressed
    if [[ "$choices" == "Execute All" ]]; then
      execute_all=true
      break
    else
      execute_all=false
      # Split the choices into an array
      IFS=":" read -r -a selected_choices <<< "$choices"
    fi

    if [[ $? -eq 0 && -n "$choices" ]]; then
      if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to proceed with only the selected options?\n\nThis might cause issues in RetroDECK"; then
        log i "User is not sure, showing the checklist window again."
        continue
      else
        log i "User confirmed to proceed with only the selected options."
        break
      fi
    fi

    if [[ $? == 0 ]]; then
    if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to skip the reset process?\n\nThis might cause issues in RetroDECK"; then
      log i "User is not sure, showing the checklist window again."
      continue
    else
      log i "User confirmed to proceed without any reset."
      break
    fi
    fi

    break
  done

  # Execute the selected resets

  # ES-DE reset
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " ES-DE " ]]; then
    log i "User agreed to ES-DE reset"
    prepare_component "reset" "es-de"
  fi
  rm -rf "$rd_logs_folder/ES-DE" && log d "Removing the logs/ES-DE folder as we don't need it anymore"
  rm -rf "$es_source_logs" && mkdir -p "$es_source_logs"

  # Cemu key file migration
  if [[ -f "$XDG_DATA_HOME/Cemu/keys.txt" ]]; then
    log i "Found Cemu keys.txt in \"$XDG_DATA_HOME/Cemu/keys.txt\", moving it to \"$bios_folder/cemu/keys.txt\""
    mv -f "$XDG_DATA_HOME/Cemu/keys.txt" "$bios_folder/cemu/keys.txt"
    ln -s "$bios_folder/cemu/keys.txt" "$XDG_DATA_HOME/Cemu/keys.txt"
  fi

  # Duckstation reset
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Duckstation " ]]; then
    log i "User agreed to Duckstation reset"
    prepare_component "reset" "duckstation"
  fi

  # Ryujinx reset
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Ryujinx " ]]; then
    log i "User agreed to Ryujinx reset"
    prepare_component "reset" "ryujinx"
  else
    create_dir "$logs_folder/ryujinx"
    create_dir "$mods_folder/ryujinx"
    create_dir "$screenshots_folder/ryujinx"
  fi

  # Dolphin reset: Setting screen size to 'Auto' instead of 'Widescreen' to ensure better game compatibility
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Dolphin " ]]; then
    log i "User agreed to Dolphin reset"
    set_setting_value "$dolphingfxconf" "AspectRatio" "0" "dolphin" "Settings"
  fi

  # Primehack reset: Setting screen size to 'Auto' instead of 'Widescreen' to ensure better game compatibility
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Primehack " ]]; then
    log i "User agreed to Primehack reset"
    set_setting_value "$primehackgfxconf" "AspectRatio" "0" "dolphin" "Settings"
  fi

  # --- ALWAYS EXECUTED IN 0.9.0b ---

  log i "Moving Ryujinx data to the new locations"
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/bis" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/bis"/* "$saves_folder/switch/ryujinx/nand" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/bis" && log i "Migrated Ryujinx nand data to the new location"
  fi
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/sdcard" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/sdcard"/* "$saves_folder/switch/ryujinx/sdcard" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/sdcard" && log i "Migrated Ryujinx sdcard data to the new location"
  fi
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/bis/system/Contents/registered" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/bis/system/Contents/registered"/* "$bios_folder/switch/firmware" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/bis/system/Contents/registered" && log i "Migration of Ryujinx firmware data to the new location"
  fi
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/system" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/system"/* "$bios_folder/switch/keys" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/system" && log i "Migrated Ryujinx keys data to the new location"
  fi
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/mods" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/mods"/* "$mods_folder/ryujinx" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/mods" && log i "Migrated Ryujinx mods data to the new location"
  fi
  if [[ -d "$XDG_CONFIG_HOME/Ryujinx/screenshots" ]]; then
    mv -f "$XDG_CONFIG_HOME/Ryujinx/screenshots"/* "$screenshots_folder/ryujinx" && rm -rf "$XDG_CONFIG_HOME/Ryujinx/screenshots" && log i "Migrated Ryujinx screenshots to the new location"
  fi
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.1b") == "true" ]]; then
  log i "Running the 0.9.1b post update process"

  # Create a Zenity window with checkboxes for each reset option and two buttons
  while true; do
    choices=$(rd_zenity --list --checklist --title="RetroDECK Reset Options" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="The following components have been updated and need to be reset or fixed to ensure compatibility with the new version: select the components you want to reset.\n\nNot resetting them may cause serious issues with your installation.\nYou can also reset them manually later via Configurator -> Troubleshooting -> Reset Component.\n\nNote: Your games, saves, game collections and scraped data will not be affected." \
    --column="Select" --column="Component" --column="Description" --width="1100" --height="700" \
    TRUE "Dolphin - GameCube Controller" "The GameCube controller configuration needs to be reset to fix a trigger issue" \
    TRUE "RetroArch" "Needs to be reset to fix the borders issue on some sytems such as psx" \
    TRUE "Steam ROM Manager" "Needs to add the \"Add RetroDECk to Steam\" functionality" \
    --separator=":" \
    --extra-button="Execute All" \
    --ok-label="Execute Selected Only" \
    --cancel-label="Execute None")

    log d "User selected: $choices"
    log d "User pressed: $?"

    # Check if "Execute All" button was pressed
    if [[ "$choices" == "Execute All" ]]; then
      execute_all=true
      break
    else
      execute_all=false
      # Split the choices into an array
      IFS=":" read -r -a selected_choices <<< "$choices"
    fi

    if [[ $? -eq 0 && -n "$choices" ]]; then
      if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to proceed with only the selected options?\n\nThis might cause issues in RetroDECK"; then
        log i "User is not sure, showing the checklist window again."
        continue
      else
        log i "User confirmed to proceed with only the selected options."
        break
      fi
    fi

    if [[ $? == 0 ]]; then
    if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to skip the reset process?\n\nThis might cause issues in RetroDECK"; then
      log i "User is not sure, showing the checklist window again."
      continue
    else
      log i "User confirmed to proceed without any reset."
      break
    fi
    fi

    break
  done

  # Execute the selected resets

  # RetroArch reset
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " RetroArch " ]]; then
    log i "User agreed to RetroArch reset"
    local currently_enabled_emulators=""
    local current_border_settings=$(sed -n '/\[borders\]/, /\[/{ /\[borders\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')

    while IFS= read -r config_line; do
      local system_name=$(get_setting_name "$config_line" "retrodeck")
      local system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "borders")
      if [[ "$system_value" == "true" ]]; then
        if [[ -n $currently_enabled_emulators ]]; then
          currently_enabled_emulators+="," # Add comma delimiter if list has already been started
        fi
        currently_enabled_emulators+="$system_name" # Add emulator to list of currently enabled ones
      fi
    done < <(printf '%s\n' "$current_border_settings")

    # Disable all systems in the borders preset, then re-enable the ones that were previously on
    make_preset_changes "borders" "" # Disable all systems in borders preset block
    make_preset_changes "borders" "$currently_enabled_emulators" # Re-enable previously enabled systems in the borders preset block
  fi

  # Dolphin - GameCube Controller
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Dolphin - GameCube Controller " ]]; then
    log i "User agreed to reset Dolphin - GameCube Controller"
    cp -f "$config/dolphin/GCPadNew.ini" "$dolphingcpadconf" && log i "Done"
  fi

  # Steam ROM Manager - Add to Steam fix
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Steam ROM Manager " ]]; then
    log i "User agreed to reset Steam ROM Manager - Add to Steam fix"
    prepare_component reset steam-rom-manager
  fi
fi

if [[ $(check_version_is_older_than "$version_being_updated" "0.9.2b") == "true" ]]; then
  # In version 0.9.2b, the following changes were made that required config file updates/reset or other changes to the filesystem:
  # Steam Sync completely rebuilt into new manifest system. Favorites may need to be nuked and, if steam_sync is enabled will be rebuilt. This is an optional step.

  # Reset SRM first to ensure the latest configs are loaded.
  prepare_component "reset" "steam-rom-manager"

  while true; do
    choices=$(rd_zenity --list --checklist --title="RetroDECK Steam Sync Reset Options" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="In RetroDECK 0.9.2b, we upgraded our Steam Sync feature, which may require <span foreground='$purple' size='larger'><b>rebuilding the shortcuts</b></span> in Steam.\nYour ES-DE favorites will remain unchanged. Any games you have favorited will be recreated, but <span foreground='$purple' size='larger'><b>last-played information and custom artwork changes may be lost</b></span>.\nIf you added RetroDECK to Steam through our Configurator, it will also be re-added during this process.\n\nSelect the actions you want to perform:" \
    --column="Select" --column="Action" --column="Description" --width="1100" --height="700" \
    TRUE "Refresh Steam Sync" "Rebuild the Steam Sync system, recreating shortcuts and removing outdated data" \
    TRUE "Add RetroDECK Shortcut to Steam" "Add the RetroDECK launcher back to Steam after refreshing Steam Sync" \
    TRUE "Regenerate ES-DE Folders" "Recreate the ES-DE system folders to ensure proper structure and functionality" \
    --separator=":" \
    --extra-button="Execute All" \
    --ok-label="Execute Selected Only" \
    --cancel-label="Execute None")

    log d "User selected: $choices"
    log d "User pressed: $?"

    # Check if "Execute All" button was pressed
    if [[ "$choices" == "Execute All" ]]; then
      execute_all=true
      break
    else
      execute_all=false
      # Split the choices into an array
      IFS=":" read -r -a selected_choices <<< "$choices"
    fi

    if [[ $? -eq 0 && -n "$choices" ]]; then
      if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to proceed with only the selected options?\n\nThis might cause issues in RetroDECK"; then
        log i "User is not sure, showing the checklist window again."
        continue
      else
        log i "User confirmed to proceed with only the selected options."
        break
      fi
    fi

    if [[ $? == 0 ]]; then
      if ! rd_zenity --question --title="Confirmation" --text="Are you sure you want to skip the Steam Sync reset process?\n\nThis might cause issues in RetroDECK"; then
        log i "User is not sure, showing the checklist window again."
        continue
      else
        log i "User confirmed to proceed without any reset."
        break
      fi
    fi

    break
  done

  # Execute the selected actions

  # Refresh Steam Sync
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Refresh Steam Sync " ]]; then
    log i "User agreed to refresh Steam Sync"
    steam-rom-manager nuke
    export CONFIGURATOR_GUI="zenity"
    steam_sync
  fi

  # Add RetroDECK Shortcut to Steam
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Add RetroDECK Shortcut to Steam " ]]; then
    log i "User agreed to add RetroDECK shortcut to Steam"
    (
    steam-rom-manager enable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    steam-rom-manager add >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="RetroDECK Configurator: Add RetroDECK to Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="Adding RetroDECK to Steam...\n\n<span foreground='$purple'>Please wait until the operation is finished and you need to restart Steam afterwards.</span>" \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  fi

  # Regenerate ES-DE Folders
  if [[ "$execute_all" == "true" || " ${selected_choices[@]} " =~ " Regenerate ES-DE Folders " ]]; then
    log i "User agreed to regenerate ES-DE folders"
    es-de --create-system-dirs
  fi
fi

#######################################
# These actions happen at every update
#######################################

if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
  install_retrodeck_controller_profile
fi

update_splashscreens
deploy_helper_files
build_retrodeck_current_presets
