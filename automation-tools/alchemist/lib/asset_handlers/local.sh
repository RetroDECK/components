#!/bin/bash

asset_handler_info() {
  echo "type:dir,file,merge,file-rename"
}

handle_asset() {
  local type="$1"
  local source="$2"
  local dest="$3"

  local final_source="$source"
  local final_dest="$dest"

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$EXTRACTED_PATH/$source"
  fi

  if [[ ! -e "$final_source" ]]; then
    log error "Provided source $final_source does not exist, cannot grab asset"
    return 1
  fi

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"
  fi

  if [[ "$type" == "file" ]]; then
    final_dest="$final_dest/$(basename $final_source)"
    if [[ ! -d "$(dirname $final_dest)" ]]; then # If destination dir does not already exist
      log info "Destination dir $(dirname $final_dest) does not exist, creating..."
      mkdir -p "$(dirname $final_dest)"
    fi
  elif [[ "$type" == "dir" ]]; then
    if [[ ! -d "$final_dest" ]]; then # If destination dir does not already exist
      log info "Destination dir $final_dest does not exist, creating..."
      mkdir -p "$final_dest"
    fi
  elif [[ "$type" == "file-rename" ]]; then
    if [[ ! -d "$(dirname "$final_dest")"]]; then
      log info "Destination dir $(basename $(dirname $final_dest)) does not exist, creating..."
      mkdir -p "$(dirname "$final_dest")"
    fi
  fi

  case "$type" in
    file)
      process_asset_cmd() {
        cp "$1" "$2"
      }
    ;;
    dir)
      process_asset_cmd() {
        cp -r "$1/"* "$2"
      }
    ;;
    merge)
      process_asset_cmd() {
        cp -nr "$1/"* "$2"
      }
    ;;
    file-rename)
      process_asset_cmd() {
        mv "$1" "$2"
      }
    ;;
    *)
      log error "Error: Unsupported type: $type"
      return 1
    ;;
  esac

  log info "Copying source: $final_source"
  log info "Copying destination: $final_dest"

  if ! process_asset_cmd "$final_source" "$final_dest"; then
    log error "Asset source \"$final_source\" could not be processed to dest \"$final_dest\""
    return 1
  fi

  if [[ ! -e "$final_dest" ]]; then
    log error "Asset $final_dest could not be validated, exiting."
    return 1
  fi

  log info "Asset source \"$final_source\" processed to dest \"$final_dest\""
  return 0
}
