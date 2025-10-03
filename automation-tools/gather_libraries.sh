#!/bin/bash

if [[ ! -f ".tmpfunc/logger.sh" ]]; 
then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

# Ensure logfile is set and exported for all log calls
if [ -z "$logfile" ]; then
    export logfile="assemble.log"
else
    export logfile
fi

# This script is meant to process component_libs.json files created by the build_missing_libs_json.sh script.
# It will iterate all the objects in the output JSON files, search for the defined libraries and copy them to the specified locations if they do not already exist there.
# A path to search for component_libs.json files can optionally be specified. The script will search this path 1 level deep, so will investigate any direct sub-folders of the supplied path. Otherwise the script will search the directory from which it was run.
# A destination path can be specified which will override the "shared-libs" destination, which is used when any specific destination is not defined for a given library in the component_libs.json file.

# USAGE: gather_libraries [-p|--path <path>] [-d|--dest <dest>] [-w|--work-dir <work_dir>]
# Can be sourced and called as a function or executed directly as a script.
# When called from assembler.sh, it will use WORK_DIR before it's disposed.

gather_libraries() {
  local root_to_search="."
  local gathered_libs_dest_root="./shared-libs"
  local flatpak_runtime_dir="/var/lib/flatpak/runtime"
  local current_rd_runtime="24.08"  # TODO: automate the extraction of the current RetroDECK runtime version
  local work_dir_override=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--path)
        root_to_search="$2"
        shift 2
      ;;
      -d|--dest)
        gathered_libs_dest_root="$2"
        shift 2
      ;;
      -w|--work-dir)
        work_dir_override="$2"
        shift 2
      ;;
      *)
        echo "Unknown option: $1"
        return 1
      ;;
    esac
    done
  
  # If WORK_DIR is set from assembler.sh and no override, search there first
  if [[ -n "$WORK_DIR" && -z "$work_dir_override" ]]; then
    work_dir_override="$WORK_DIR"
    log i  "Using WORK_DIR from assembler: $work_dir_override"
  fi
  
  # If work_dir_override is set, prioritize searching there
  if [[ -n "$work_dir_override" && -d "$work_dir_override" ]]; then
    log i  "Searching for component_libs.json in work directory: $work_dir_override"
    root_to_search="$work_dir_override"
  fi

    done
  
  # If WORK_DIR is set from assembler.sh and no override, search there first
  if [[ -n "$WORK_DIR" && -z "$work_dir_override" ]]; then
    work_dir_override="$WORK_DIR"
    log i  "Using WORK_DIR from assembler: $work_dir_override"
  fi
  
  # If work_dir_override is set, prioritize searching there
  if [[ -n "$work_dir_override" && -d "$work_dir_override" ]]; then
    log i  "Searching for component_libs.json in work directory: $work_dir_override"
    root_to_search="$work_dir_override"
  fi

  gathered_libs_dest_root=$(realpath $gathered_libs_dest_root)

  if [[ ! -e "$gathered_libs_dest_root" ]]; then
    mkdir -p "$gathered_libs_dest_root"
  fi

  while IFS= read -r component_libs_file; do
    component_libs_file=$(realpath $component_libs_file)
    log i  "Found $component_libs_file"
    while read -r lib; do
      qt_version=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .qt_version // empty' "$component_libs_file")
      lib_type=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .type // empty' "$component_libs_file")
      lib_src=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .source // empty' "$component_libs_file")
      lib_dest=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .dest // empty' "$component_libs_file")
      if [[ -n $qt_version ]]; then
        if [[ $lib_type == "qt_plugin" ]]; then
          log i  "Looking for Qt plugin at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib"
          if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib" ]]; then
            if [[ ! -n "$lib_dest" ]]; then
                lib_dest="$gathered_libs_dest_root/qt-$qt_version/plugins/$lib/"
            fi
            if [[ -e "$lib_dest" ]]; then
              log i  "Qt plugin folder already found in destination location $lib_dest, skipping..."
            else
              if [[ ! -e "$lib_dest" ]]; then
                mkdir -p "$lib_dest"
              fi
              log i  "Qt plugin not found in destination location $lib_dest, copying..."
              cp -ar "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib/"* "$lib_dest"
            fi
          else
            log i  "ERROR: Qt plugin folder not found at expected location."
          fi
        else
          log i  "Looking for Qt lib at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib"
          if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib" ]]; then
            if [[ ! -n "$lib_dest" ]]; then
                lib_dest="$gathered_libs_dest_root/qt-$qt_version"
            fi
            if [[ -e "$lib_dest/$lib" ]]; then
              log i  "Lib already found in destination location $lib_dest/$lib, skipping..."
            else
              if [[ ! -e "$lib_dest" ]]; then
                mkdir -p "$lib_dest"
              fi
              log i  "Library not found in destination location $lib_dest, copying..."
              cp -a "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib"* "$lib_dest/"
            fi
          else
            log i  "ERROR: Lib not found at expected location."
          fi
        fi
        continue
      fi
      if [[ ! -n "$lib_src" ]]; then
        lib_src="$flatpak_runtime_dir/$current_rd_runtime/active/files/lib/x86_64-linux-gnu"
      fi
      log i  "Looking for lib at $lib_src/$lib"
      if [[ -e "$lib_src/$lib" ]]; then
        if [[ ! -n "$lib_dest" ]]; then
          lib_dest="$gathered_libs_dest_root"
        fi
        if [[ -e "$lib_dest/$lib" ]]; then
            log i  "Lib already found in destination location $lib_dest, skipping..."
          else
            if [[ ! -e "$lib_dest" ]]; then
              mkdir -p "$lib_dest"
            fi
            log i  "Library not found in destination location $lib_dest, copying..."
            cp -a "$lib_src/$lib"* "$lib_dest/"
          fi
      else
        log i  "ERROR: Lib not found at expected location."
      fi
    done <<< "$(jq -r '.[].library' "$component_libs_file")"
  done < <(find "$root_to_search" -maxdepth 2 -type f -name "component_libs.json")
}

# Wrapper function for logging compatibility with assembler.sh
log_wrapper() {
  local message="$1"
  if declare -f log > /dev/null && [[ -n "$logfile" ]]; then
    log i "$message" "$logfile"
  else
    echo "$message"
  fi
}

# If script is executed directly (not sourced), call the function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gather_libraries "$@"
fi

