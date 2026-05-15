#!/bin/bash

source /app/libexec/launcher_functions.sh
source /app/libexec/components.sh

if [[ ! -f "$roms_path/satellaview_plus/bs-x.sfc" ]]; then
  zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK: Satellaview+ - Error: ROM not found" \
        --text="Satellaview+ ROM not found.\n\nPlease provide the 'bs-x.sfc' ROM file in the\n\n'$roms_path/satellaview_plus'\n\ndirectory and try again.\n\nNote: you would need either an \"English + No DRM\" or \"Japanese + No DRM\" version to work with Satellaview+.\nRun the BIOS Checker Tool in the Configurator for more information about the required ROMs and their checksums."
  exit 1
else
  cp "$roms_path/satellaview_plus/bs-x.sfc" "$satellaview_plus_bsx_path/bs-x.sfc"
  # TODO: if we need to patch the roms we can do it here
fi

# Setting component name and path based on the directory name
component_name="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"
log d "Library path is: $LD_LIBRARY_PATH"

satellaview_tuner() {

    export LD_LIBRARY_PATH="$component_path/usr/lib/:$component_path/lib:$rd_shared_libs:${DEFAULT_LD_LIBRARY_PATH}"
    export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}"
    export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH}"

    log i "Opening Satellaview+ Tuner command"

    # We move here because the config file is read from ./
    cd "$satellaview_plus_config_path"
    exec "$component_path/AppRun"

}

run_satellaview(){

    export satellaview_plus_download_path="$storage_path/satellaview_plus/"
    export satellaview_plus_bsx_path="$storage_path/satellaview_plus/roms/bs-x"

    log i "Running Satellaview+ SNES9X"

    cd "$storage_path/satellaview_plus/"

    # WORKAROUND: the launcher is supposed to move the doiwnloaded satdata into the rom folder (in storage) but is not doing it,
    # so we are symlinking it by ourselves before launching the game and cleaning it up later
    ln -s "$satellaview_plus_download_path/satdata/"* "$satellaview_plus_bsx_path/"

    if [ "$(get_component_option satellaview_plus satellaview_plus_soundlink_stream_toggle)" == "true" ]; then

      log i "Soundlink+ stream toggle is enabled, starting the stream"

      # Start soundlink+ streaming in the background
      ffplay -nodisp -autoexit "$satellaview_soundlink_stream" >/dev/null 2>&1 &
      STREAM_PID=$!

      # Auto cleanup the stream when the game is closed
      cleanup() {
          kill "$STREAM_PID" 2>/dev/null
      }

      trap cleanup EXIT INT TERM

    else
      log i "Soundlink+ stream toggle is disabled, skipping the stream"
    fi

    XDG_CONFIG_HOME="$XDG_CONFIG_HOME/satellaview_plus/snes9x" "$component_path/bin/snes9x-gtk" "$satellaview_plus_bsx_path/bs-x.sfc"

    # Cleanup the symlinks after the game is closed
    log d "Cleaning up symlinks in BS-X ROM directory"
    find "$satellaview_plus_bsx_path" -type l -delete

}

# This function is called by the .sh launchers in the rom folder and it decides which command to run based on the content of the launcher script
if [[ -f "$1" ]]; then
  log i "Reading command from file '$1'"
    command=$(cat "$1")
    log i "Command read from file '$1': $command"
elif [[ -n "$1" ]]; then
    log i "\"$1\" appears to be a command argument. Using the argument as command."
    command="$1"
else
    log w "Command file '$1' not found, falling back to default run command"
    command="run"
fi

case $command in

  tuner|--tuner|-t)
    satellaview_tuner
  ;;

  run|--run|-r)
    run_satellaview
  ;;

  help|--help|-h)
    log i "Available commands in the launcher script:"
    log i "  tuner, --tuner, -t: Launch the Satellaview+ Tuner"
    log i "  run, --run, -r: Run the Satellaview+ SNES9X emulator"
    log i "  help, --help, -h: Show this help message"
  ;;

  *)
    log e "Unknown command '$command' in launcher script '$1'"
    log w "Falling back to Satellaview+ run command"
    run_satellaview
  ;;

esac