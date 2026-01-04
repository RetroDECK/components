#!/bin/bash

asset_handler_info() {
  echo "type:cleanup,cleanup-dir"
}

handle_asset() {
  local type="$1"
  local source="$2"

  local final_source="$source"

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$EXTRACTED_PATH/$source"
  fi

  if [[ ! -e "$final_source" ]]; then
    log error "Provided source $final_source does not exist, cannot removed"
    return 1
  fi

  case "$type" in
    cleanup)
      process_asset_cmd() {
        rm -f "$1"
      }
    ;;
    cleanup-dir)
      process_asset_cmd() {
        rm -rf "$1"
      }
    ;;
    *)
      log error "Error: Unsupported type: $type"
      return 1
    ;;
  esac

  log info "Removing source: $final_source"

  if ! process_asset_cmd "$final_source"; then
    log error "Asset source \"$final_source\" could not be removed"
    return 1
  fi

  log info "Asset source \"$final_source\" removed"
  return 0
}
