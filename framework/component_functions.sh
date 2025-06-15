#!/bin/bash

# Static variables
rd_conf="$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg"                                                            # RetroDECK config file path
rd_conf_backup="$XDG_CONFIG_HOME/retrodeck/retrodeck.bak"                                                     # Backup of RetroDECK config file from update
config="/app/retrodeck/config"                                                                           # folder with all the default emulator configs
rd_defaults="$config/retrodeck/retrodeck.cfg"                                                            # A default RetroDECK config file
rd_update_patch="$XDG_CONFIG_HOME/retrodeck/rd_update.patch"                                                  # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="$config/retrodeck/reference_lists/bios.json"                                    # A config file listing BIOS file information that can be verified
input_validation="$config/retrodeck/reference_lists/input_validation.cfg"                                # A config file listing valid CLI inputs
finit_options_list="$config/retrodeck/reference_lists/finit_options_list.cfg"                            # A config file listing available optional installs during finit
splashscreen_dir="$XDG_CONFIG_HOME/ES-DE/resources/graphics/extra_splashes"                                   # The default location of extra splash screens
current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
default_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash-orig.svg"                               # The default RetroDECK splash screen
# TODO: instead of this maybe we can iterate the features.json
multi_user_emulator_config_dirs="$config/retrodeck/reference_lists/multi_user_emulator_config_dirs.cfg"  # A list of emulator config folders that can be safely linked/unlinked entirely in multi-user mode
rd_es_themes="/app/share/es-de/themes"                                                                   # The directory where themes packaged with RetroDECK are stored
lockfile="$XDG_CONFIG_HOME/retrodeck/.lock"                                                                   # Where the lockfile is located
sd_sdcard_default_path="/run/media/mmcblk0p1"                                                                        # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"                                                           # hardcoded version (in the readonly filesystem)
rd_repo="https://github.com/RetroDECK/RetroDECK"                                                         # The URL of the main RetroDECK GitHub repo
es_themes_list="https://gitlab.com/es-de/themes/themes-list/-/raw/master/themes.json"                    # The URL of the ES-DE 2.0 themes list
remote_network_target_1="https://flathub.org"                                                            # The URL of a common internet target for testing network access
remote_network_target_2="$rd_repo"                                                                       # The URL of a common internet target for testing network access
remote_network_target_3="https://one.one.one.one"                                                        # The URL of a common internet target for testing network access
helper_files_path="$config/retrodeck/helper_files"                                                     # The parent folder of RetroDECK documentation files for deployment
rd_metainfo="/app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"                                   # The shipped metainfo XML file for this version
rpcs3_firmware_url="http://dus01.ps3.update.playstation.net/update/ps3/image/us/2024_0227_3694eb3fb8d9915c112e6ab41a60c69f/PS3UPDAT.PUP" # RPCS3 Firmware download location
ra_cheevos_api_url="https://retroachievements.org/dorequest.php"                                                 # API URL for RetroAchievements.org
presets_dir="$config/retrodeck/presets"                                                                  # Repository for all system preset config files
git_organization_name="RetroDECK"                                                                        # The name of the organization in our git repository such as GitHub
cooker_repository_name="Cooker"                                                                          # The name of the cooker repository under RetroDECK organization
main_repository_name="RetroDECK"                                                                         # The name of the main repository under RetroDECK organization
features="$config/retrodeck/reference_lists/features.json"                                               # A file where all the RetroDECK and component capabilities are kept for querying
es_systems="/app/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list
es_find_rules="/app/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules

# API-related file locations

rd_api_dir="$XDG_CONFIG_HOME/retrodeck/api"
REQUEST_PIPE="$rd_api_dir/retrodeck_api_pipe"
PID_FILE="$rd_api_dir/retrodeck_api_server.pid"
rd_api_socket="$rd_api_dir/retrodeck_api_server.sock"

# File lock file for multi-threaded write operations to the same file

RD_FILE_LOCK="$rd_api_dir/retrodeck_file_lock"

configurator_portmaster_toggle_dialog(){

  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>visible</b></span> in ES-DE. Do you want to hide it?\n\nPlease note that the installed games will still be visible."

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>hidden</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes.\n\nIn order to launch PortMaster, you can access it from:\n<span foreground='$purple'><b>Configurator -> Open Component -> PortMaster</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>hidden</b></span> in ES-DE. Do you want to show it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "true"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>visible</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes."
    fi
  fi
}

portmaster_show(){
  log d "Setting PortMaster visibility in ES-DE"
  if [ "$1" = "true" ]; then
      log d "\"$rd_home_roms_path/portmaster/PortMaster.sh\" is not found, installing it"
      install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$rd_home_roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly showing in ES-DE"
      set_setting_value "$rd_conf" "portmaster_show" "true" retrodeck "options"
  elif [ "$1" = "false" ]; then
    rm -rf "$rd_home_roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly hidden in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "false" retrodeck "options"
  else
    log e "\"$1\" is not a valid choice, quitting"
  fi
}

configurator_bios_checker_dialog() {

  log d "Starting BIOS checker"

  (
    # Read the BIOS checklist from bios.json using jq
    total_bios=$(jq '.bios | length' "$bios_checklist")
    current_bios=0

    log d "Total BIOS files to check: $total_bios"

    bios_checked_list=()

     while IFS=$'\t' read -r bios_file bios_systems bios_desc required bios_md5 bios_paths; do

      # Expand any embedded shell variables (e.g. $rd_home_saves_path or $rd_home_bios_path) with their actual values
      bios_paths=$(echo "$bios_paths" | envsubst)

      bios_file_found="No"
      bios_md5_matched="No"

      IFS=', ' read -r -a paths_array <<< "$bios_paths"
      for path in "${paths_array[@]}"; do
        log d "Looking for $path/$bios_file"
        if [[ ! -f "$path/$bios_file" ]]; then
          log d "File $path/$bios_file not found"
          break
        else
          bios_file_found="Yes"
          computed_md5=$(md5sum "$path/$bios_file" | awk '{print $1}')

          IFS=', ' read -ra expected_md5_array <<< "$bios_md5"
          for expected in "${expected_md5_array[@]}"; do
            expected=$(echo "$expected" | xargs)
            if [ "$computed_md5" == "$expected" ]; then
              bios_md5_matched="Yes"
              break
            fi
          done
          log d "BIOS file found: $bios_file_found, Hash matched: $bios_md5_matched"
          log d "Expected path: $path/$bios_file"
          log d "Expected MD5: $bios_md5"
        fi
      done

        log d "Adding BIOS entry: \"$bios_file $bios_systems $bios_file_found $bios_md5_matched $bios_desc $bios_paths $bios_md5\" to the bios_checked_list"

        bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_systems" "$bios_file_found" "$bios_md5_matched" "$required" "$bios_paths" "$bios_desc" "$bios_md5")

        current_bios=$((current_bios + 1))
        echo "$((current_bios * 100 / total_bios))"

    done < <(jq -r '
          .bios
          | to_entries[]
          | [
              .key,
              (.value.system | if type=="array" then join(", ") elif type=="string" then . else "Unknown" end),
              (.value.description // "No description provided"),
              (.value.required // "No"),
              (.value.md5 | if type=="array" then join(", ") elif type=="string" then . else "Unknown" end),
              (.value.paths | if type=="array" then join(", ") elif type=="string" then . else "$rd_home_bios_path" end)
            ]
          | @tsv
        ' "$bios_checklist")

    log d "Finished checking BIOS files"

    rd_zenity --list --title="RetroDECK Configurator Utility - BIOS Checker" --no-cancel \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --column "BIOS File Name" \
      --column "Systems" \
      --column "Found" \
      --column "Hash Matches" \
      --column "Required" \
      --column "Expected Path" \
      --column "Description" \
      --column "MD5" \
      "${bios_checked_list[@]}"

  ) |
  rd_zenity --progress --auto-close --no-cancel \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - BIOS Checker - Scanning" \
    --text="The BIOS Checker is scanning for BIOS & Firmware files that RetroDECK recognizes as supported by each system.\n\nPlease note that not all BIOS & Firmware files are necessary for games to work.\n\nBIOS files not recognized by this tool may still function correctly.\n\nSome emulators have additional built-in methods to verify the functionality of BIOS & Firmware files.\n\n<span foreground='$purple'><b>The BIOS Checker is now scanning your BIOS files, please wait...</b></span>\n\n" \
    --width=400 --height=100

  configurator_tools_dialog
}

configurator_compression_tool_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library and compression choices, the process can sometimes take a long time.\nPlease be patient once it is started!"

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Compression Tool" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Compress Single Game" "Compress a single game into a compatible format." \
  "Compress Multiple Games: CHD" "Compress one or more games into the CHD format." \
  "Compress Multiple Games: ZIP" "Compress one or more games into the ZIP format." \
  "Compress Multiple Games: RVZ" "Compress one or more games into the RVZ format." \
  "Compress Multiple Games: All Formats" "Compress one or more games into any format." \
  "Compress All Games" "Compress all games into compatible formats." )

  case $choice in

  "Compress Single Game" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games: CHD" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "chd"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: ZIP" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "zip"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: RVZ" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "rvz"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: All Formats" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "all"
    configurator_compression_tool_dialog
  ;;

  "Compress All Games" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "everything"
    configurator_compression_tool_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_tools_dialog
  ;;

  esac
}

configurator_compress_single_game_dialog() {
  local file=$(file_browse "Game to compress")
  if [[ ! -z "$file" ]]; then
    local system=$(echo "$file" | grep -oE "$rd_home_roms_path/[^/]+" | grep -oE "[^/]+$")
    local compatible_compression_format=$(find_compatible_compression_format "$file")
    if [[ ! $compatible_compression_format == "none" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      (
      echo "# Compressing $(basename "$file") to $compatible_compression_format format" # This updates the Zenity dialog
      log i "Compressing $(basename "$file") to $compatible_compression_format format"
      compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup" "$system"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --width="800" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete."
      configurator_compression_tool_dialog

    else
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The selected file does not have any compatible compression formats."
      configurator_compression_tool_dialog
    fi
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compress_multiple_games_dialog() {
  log d "Starting to compress \"$1\""

  (
    parse_json_to_array checklist_entries api_get_compressible_games "$1"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" --text "RetroDECK is searching for compressible games, please wait..."

  if [[ -s "$compressible_games_list_file" ]]; then
    mapfile -t all_compressible_games < "$compressible_games_list_file"
    log d "Found the following games to compress: ${all_compressible_games[*]}"
  else
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "No compressible files were found."
    configurator_compression_tool_dialog
  fi

  local games_to_compress=()
  if [[ "$1" != "everything" ]]; then
    local checklist_entries=()
    for line in "${all_compressible_games[@]}"; do
      IFS="^" read -r game comp <<< "$line"
      local short_game="${game#$rd_home_roms_path}"
      checklist_entries+=( "TRUE" "$short_game" "$line" )
    done

    local choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - Compression Tool" \
      --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
      --separator="^" --print-column=3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Game Full Path and Compression Format" \
      "${checklist_entries[@]}")

    local rc=$?
    log d "User choice: $choice"
    if [[ $rc == 0 && -n "$choice" && ! "$choice" == "Compress All" ]]; then
      IFS='^' read -r -a temp_array <<< "$choice"
      games_to_compress=()
      for ((i=0; i<${#temp_array[@]}; i+=2)); do
        games_to_compress+=("${temp_array[i]}^${temp_array[i+1]}")
      done
    elif [[ "$choice" == "Compress All" ]]; then
      games_to_compress=("${all_compressible_games[@]}")
    else
      configurator_compression_tool_dialog
    fi
  else
    games_to_compress=("${all_compressible_games[@]}")
  fi

  local post_compression_cleanup=$(configurator_compression_cleanup_dialog)

  local total_games=${#games_to_compress[@]}
  local games_left=$total_games

  (
  for game_line in "${games_to_compress[@]}"; do
    while (( $(jobs -p | wc -l) >= $max_threads )); do
    sleep 0.1
    done
    (
    IFS="^" read -r game compression_format <<< "$game_line"

    local system
    system=$(echo "$game" | grep -oE "$rd_home_roms_path/[^/]+" | grep -oE "[^/]+$")
    log i "Compressing $(basename "$game") into $compression_format format"

    echo "#Compressing $(basename "$game") into $compression_format format.\n\n$games_left games left to compress." # Update Zenity dialog text

    compress_game "$compression_format" "$game" "$post_compression_cleanup" "$system"

    games_left=$(( games_left - 1 ))
    local progress=$(( 99 - (( 99 / total_games ) * games_left) ))
    echo "$progress" # Update Zenity dialog progress bar
    ) &
  done
  wait # wait for background tasks to finish
  echo "100" # Close Zenity progress dialog when finished
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck/retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator Utility - Compression in Progress"

  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The compression process is complete!"
  configurator_compression_tool_dialog
}

configurator_compression_cleanup_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" \
  --text="Do you want to remove old files after they are compressed?\n\nClicking \"No\" will leave all files behind which will need to be cleaned up manually and may result in game duplicates showing in the RetroDECK library.\n\nPlease make sure you have a backup of your ROMs before using automatic cleanup."
  local rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    echo "true"
  else # If "No" was clicked
    echo "false"
  fi
}

configurator_update_notify_dialog() {
  if [[ $(get_setting_value "$rd_conf" "update_check" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently enabled.\n\nDo you want to disable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    else # User clicked "Cancel"
      configurator_tools_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently disabled.\n\nDo you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    else # User clicked "Cancel"
      configurator_tools_dialog
    fi
  fi
}

configurator_repair_paths_dialog() {
  repair_paths
  configurator_tools_dialog
}

configurator_change_logging_level_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Change Logging Level" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Level 1: Informational" "The default setting, logs only basic important information." \
  "Level 2: Warnings" "Logs general warnings." \
  "Level 3: Errors" "Logs more detailed error messages." \
  "Level 4: Debug" "Logs everything, which may generate a lot of logs.")

  case $choice in

  "Level 1: Informational" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "logging_level" "info" "retrodeck" "options"
    declare -g "$logging_level=info"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to Level 1: Informational"
  ;;

  "Level 2: Warnings" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "logging_level" "warn" "retrodeck" "options"
    declare -g "$logging_level=warn"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to Level 2: Warnings"
  ;;

  "Level 3: Errors" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "logging_level" "error" "retrodeck" "options"
    declare -g "$logging_level=error"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to Level 3: Errors"
  ;;

  "Level 4: Debug" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "logging_level" "debug" "retrodeck" "options"
    declare -g "$logging_level=debug"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to Level 4: Debug"
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
  ;;

  esac
  configurator_tools_dialog
}

configurator_retrodeck_backup_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "This tool will compress one or more RetroDECK userdata folders into a single zip file.\n\nPlease note that this process may take several minutes.\n\n<span foreground='$purple'><b>The resulting zip file will be located in $rd_home_backups_path.</b></span>\n\n"

  choice=$(rd_zenity --title "RetroDECK Configurator - Backup Userdata" --info --no-wrap --ok-label="Cancel" --extra-button="Core Backup" --extra-button="Custom Backup" --extra-button="Complete Backup" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Would you like to backup some or all of the RetroDECK userdata?\n\nChoose one of the following options:\n\n1. Core Backup: Only essential files (such as saves, states, and gamelists).\n\n2. Custom Backup: You will be given the option to select specific folders to backup.\n\n3. Complete Backup: All data, including games and downloaded media, will be backed up.\n\n<span foreground='$purple'><b>PLEASE NOTE: A complete backup may require a significant amount of space.</b></span>\n\n")

  case $choice in
    "Core Backup" )
      log i "User chose to backup core userdata prior to update."
      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "core"
    ;;
    "Custom Backup" )
      log i "User chose to backup custom userdata prior to update."
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rd_home_path|sdcard|rd_home_backups_path) ]]; then # Ignore these locations
        log d "Adding $current_setting_name to compressible paths."
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          compressible_paths=("${compressible_paths[@]}" "false" "$current_setting_name" "$current_setting_value")
        fi
      done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')

      choice=$(rd_zenity \
      --list --width=1200 --height=720 \
      --checklist \
      --separator="^" \
      --print-column=3 \
      --text="Please select the folders you wish to compress..." \
      --column "Backup?" \
      --column "Folder Name" \
      --column "Path" \
      "${compressible_paths[@]}")

      choices=() # Expand choice string into passable array
      IFS='^' read -ra choices <<< "$choice"

      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "custom" "${choices[@]}" # Expand array of choices into individual arguments
    ;;
    "Complete Backup" )
      log i "User chose to backup all userdata prior to update."
      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "complete"
    ;;
  esac

  configurator_data_management_dialog
}

configurator_clean_empty_systems_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "Before removing any identified empty system folders,\nplease ensure your game collection is backed up, just in case!"
  configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "Searching for empty system folders, please be patient..."
  find_empty_rom_folders

  choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - RetroDECK: Clean Empty System Folders" \
      --checklist --hide-column=3 --ok-label="Remove Selected" --extra-button="Remove All" \
      --separator="^" --print-column=2 \
      --text="Choose which empty ROM folders to remove:" \
      --column "Remove?" \
      --column "System" \
      "${empty_rom_folders_list[@]}")

  local rc=$?
  if [[ $rc == "0" && ! -z $choice ]]; then # User clicked "Remove Selected" with at least one system selected
    IFS="^" read -ra folders_to_remove <<< "$choice"
    for folder in "${folders_to_remove[@]}"; do
      log i "Removing empty folder $folder"
      rm -rf "$folder"
    done
    configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "The removal process is complete."
  elif [[ ! -z $choice ]]; then # User clicked "Remove All"
    for folder in "${all_empty_folders[@]}"; do
      log i "Removing empty folder $folder"
      rm -rf "$folder"
    done
    configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "The removal process is complete."
  fi

  configurator_data_management_dialog
}

configurator_rebuild_esde_systems() {
  es-de --create-system-dirs
  configurator_generic_dialog "RetroDECK Configurator - Rebuild System Folders" "The rebuilding process is complete.\n\nAll missing default system folders will now exist in $rd_home_roms_path"
  configurator_data_management_dialog
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n "$rd_metainfo"))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK Version History" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Full RetroDECK Changelog" "View the list of all changes that have ever been made to RetroDECK" \
  "${all_versions_list[@]}")

  case $choice in

  "Full RetroDECK Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    changelog_dialog "all"
  ;;

  "RetroDECK"*"Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    local version=$(echo "$choice" | sed 's/^RetroDECK \(.*\) Changelog$/\1/')
    changelog_dialog "$version"
  ;;

  esac

  configurator_about_retrodeck_dialog
}

configurator_retrodeck_credits_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Credits" \
  --filename="$config/retrodeck/reference_lists/retrodeck_credits.txt"
  configurator_about_retrodeck_dialog
}

configurator_browse_retrodeck_wiki_dialog() {
  xdg-open "https://github.com/RetroDECK/RetroDECK/wiki"
  configurator_developer_dialog
}

configurator_install_retrodeck_starter_pack_dialog() {
  if [[ $(configurator_generic_question_dialog "Install: RetroDECK Starter Pack" "The RetroDECK creators have put together a collection of classic retro games you might enjoy!\n\nWould you like to have them automatically added to your library?") == "true" ]]; then
    install_retrodeck_starterpack
  fi
  configurator_developer_dialog
}

configurator_retrodeck_multiuser_dialog() {
  if [[ $(get_setting_value "$rd_conf" "multi_user_mode" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user Support" \
    --text="Multi-user mode is currently enabled. Do you want to disable it?\n\nIf there is more than one user configured, you will be given a choice of which user to keep as the single RetroDECK user.\n\nThis user's files will be moved to the default locations.\n\nOther users' files will remain in the mutli-user-data folder.\n"

    if [ $? == 0 ] # User clicked "Yes"
    then
      multi_user_disable_multi_user_mode
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user support" \
    --text="Multi-user mode is currently disabled. Do you want to enable it?\n\nThe current user's saves and states will be backed up and moved to the \"retrodeck/multi-user-data\" folder.\nAdditional users will automatically be stored in their own folder here as they are added."

    if [ $? == 0 ]
    then
      multi_user_enable_multi_user_mode
    else
      configurator_developer_dialog
    fi
  fi
}

configurator_online_update_channel_dialog() {
  if [[ $(get_setting_value "$rd_conf" "update_repo" retrodeck "options") == "RetroDECK" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Change Update Branch" \
    --text="You are currently on the stable branch of RetroDECK updates. Would you like to switch to the cooker branch?\n\nAfter installing a cooker build, you may need to remove the \"stable\" branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    fi
  else
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    release_selector
  fi
  configurator_developer_dialog
}

configurator_usb_import_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Prepare USB device" "Create ROM and BIOS folders on a selected USB device" \
  "Import from USB" "Import collection from a previously prepared device" )

  case $choice in

  "Prepare USB device" )
    log i "Configurator: opening \"$choice\" menu"

    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "If you have an SD card installed that is not currently configured in RetroDECK, it may show up in this list but may not be suitable for USB import.\n\nPlease select your desired drive carefully."
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        create_dir "$choice/RetroDECK Import"
        es-de --home "$choice/RetroDECK Import" --create-system-dirs
        rm -rf "$choice/RetroDECK Import/ES-DE" # Cleanup unnecessary folder


        # Prepare default BIOS folder subfolders
        create_dir "$choice/RetroDECK Import/BIOS/np2kai"
        create_dir "$choice/RetroDECK Import/BIOS/dc"
        create_dir "$choice/RetroDECK Import/BIOS/Mupen64plus"
        create_dir "$choice/RetroDECK Import/BIOS/quasi88"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/samples"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/cheats"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/blend"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/patched"
        create_dir "$choice/RetroDECK Import/BIOS/citra/sysdata"
        create_dir "$choice/RetroDECK Import/BIOS/cemu"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/carts"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/cdata"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd0"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd1"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash2"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash3"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_bdvd"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_usb000"
        create_dir "$choice/RetroDECK Import/BIOS/Vita3K/"
        create_dir "$choice/RetroDECK Import/BIOS/mame-sa/samples"
        create_dir "$choice/RetroDECK Import/BIOS/gzdoom"
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found."
    fi
    configurator_usb_import_dialog
  ;;

  "Import from USB" )
    log i "Configurator: opening \"$choice\" menu"
    external_devices=()

    while read -r size device_path; do
      if [[ -d "$device_path/RetroDECK Import/ROMs" ]]; then
        device_name=$(basename "$device_path")
        external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
      fi
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if [[ $(verify_space "$choice/RetroDECK Import/ROMs" "$rd_home_roms_path") == "false" || $(verify_space "$choice/RetroDECK Import/BIOS" "$rd_home_bios_path") == "false" ]]; then
          if [[ $(configurator_generic_question_dialog "RetroDECK Configurator Utility - USB Migration Tool" "You MAY not have enough free space to import this ROM/BIOS library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same files in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?") == "true" ]]; then
            (
            rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$rd_home_roms_path"
            rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$rd_home_bios_path"
            ) |
            rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - USB Import In Progress"
            configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$rd_home_roms_path"
          rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$rd_home_bios_path"
          ) |
          rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator Utility - USB Import In Progress"
          configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
        fi
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found with an importable folder."
    fi
    configurator_usb_import_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_developer_dialog
  ;;
  esac
}
