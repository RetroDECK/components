#!/bin/bash

set -euo pipefail

# Source tooling libraries
source "$SCRIPT_DIR/lib/tools/install_flatpak.sh"

parse_gather_lib_args() {
  name=""
  dest=""
  source=""
  runtime_name=""
  runtime_version=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name)
        name="$2"
        shift 2
        ;;
      -d|--dest)
        dest="$2"
        shift 2
        ;;
      -s|--source)
        source="$2"
        shift 2
        ;;
      -rn|--runtime-name)
        runtime_name="$2"
        shift 2
        ;;
      -rv|--runtime-version)
        runtime_version="$2"
        shift 2
        ;;
      *)
        log error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$name" || ! -n "$dest" || ((( -n "$runtime_name" && ! -n "$runtime_version" ) || ( ! -n "$runtime_name" && -n "$runtime_version" )) || ( ! -n "$source" && ! -n "$runtime_name" && ! -n "$runtime_version" )) ]]; then
    log error "Missing required arguments"
    return 1
  fi
}

gather_lib() {
  local name="$1"
  local dest="$2"
  local runtime_name="$3"
  local runtime_version="$4"
  local source="$5"

  local final_source final_dest

  local lib_basename="${name%%\.so*}.so"

  if [[ ! "$source" = /* ]]; then # If provided source path is relative
    source="$EXTRACTED_PATH/$source"
  fi

  if [[ -n "$runtime_name" && -n "$runtime_version" ]]; then # Lib is from a Flatpak runtime
    final_dest="$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version"
    if [[ -e "$final_dest/$name" ]]; then # If lib already exists at the destination
      log info "Library $name already exists at $final_dest, skipping..."
      return 0
    fi
    if ! install_flatpak "$runtime_name" "$runtime_version" "$FLATPAK_DEFAULT_INSTALL_MODE" "runtime"; then # Attempt to install the source runtime
      log error "Library source runtime $runtime_name could not be installed."
      return 1
    fi
    
    if [[ "$FLATPAK_DEFAULT_INSTALL_MODE" == "user" ]]; then
      local flatpak_current_root="$FLATPAK_USER_ROOT"
    elif [[ "$FLATPAK_DEFAULT_INSTALL_MODE" == "system" ]]; then
      local flatpak_current_root="$$FLATPAK_SYSTEM_ROOT"
    else
      log error "Default Flatpak install mode is not defined."
      return 1
    fi

    local flatpak_root_to_search="$flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files" # Set base runtime path to search

    local flatpak_found_libs=($(find "$flatpak_root_to_search" -name "$name")) # Search for libs with this exact name in the runtime
    if [[ ${#flatpak_found_libs[@]} -gt 1 ]]; then
      log error "Multiple files found, file name may need to be more specific in manifest"
      return 1
    elif [ ${#flatpak_found_libs[@]} -eq 0 ]; then
      log error "Library $name could not be found at $flatpak_root_to_search"
      return 1
    else
      final_source="$(dirname ${flatpak_found_libs[0]})/$lib_basename"
    fi
  else # Lib has a specific defined source
    if [[ ! "$dest" = /* ]]; then # If provided source path is relative
      final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"
    else
      final_dest="$dest"
    fi
    if [[ -e "$final_dest/$name" ]]; then # If lib already exists at the destination
      log info "Library $name already exists at $final_dest, skipping..."
      return 0
    fi
    if [[ ! -e "$source/$name" ]]; then
      log error "Library $name not found at defined source $source/$name"
      return 1
    fi
    final_source="$source/$lib_basename"
  fi

  if [[ ! -d "$final_dest" ]]; then
    log info "Library destination directory $final_dest does not exist, creating..."
    mkdir -p "$final_dest"
  fi

  if ! cp -a "$final_source"* "$final_dest/"; then
    log error "Library $final_source.* could not be copied to $final_dest/"
    return 1
  fi

  log info "Library(s) $final_source* copied to $final_dest/ successfully"

  if [[ "$runtime_name" == "org.kde.Platform" ]]; then # Collect Qt plugins if needed
    if [[ ! -d "$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version/plugins" ]]; then
      log info "Qt library version $runtime_version does not currently have plugins in $dest. Copying..."
      if [[ -d "$flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files/lib/plugins" ]]; then
        mkdir -p "$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version/plugins"
        cp -r "$flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files/lib/plugins/"* "$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version/plugins"
      elif [[ -d "$flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files/plugins" ]]; then
        mkdir -p "$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version/plugins"
        cp -r "$flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files/plugins/"* "$COMPONENT_ARTIFACT_ROOT/$dest/$runtime_name/$runtime_version/plugins"
      else
        log error "Qt plugins for version $runtime_version could not be found at $flatpak_current_root/runtime/$runtime_name/x86_64/$runtime_version/active/files/lib/plugins"
        return 1
      fi
    else
      log info "Qt library version $runtime_version already has plugins in $dest. Skipping..."
    fi
  fi

  return 0
}

process_gather_lib() {
  if ! parse_gather_lib_args "$@"; then
    return 1
  fi

  if ! gather_lib "$name" "$dest" "$runtime_name" "$runtime_version" "$source"; then
    log error "Gathering component library $name failed"
    return 1
  fi

  return 0
}
