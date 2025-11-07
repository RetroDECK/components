#!/bin/bash

asset_handler_info() {
  echo "type:create"
}

handle_asset() {
  local type="$1"
  local source="$2"
  local dest="$3"
  local contents="$4"

  local final_dest="$dest"

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"
  fi

  log info "Creating file $final_dest"

  if [[ -n "$contents" ]]; then
    process_asset_cmd() {
      echo "$2" > "$1"
    }
  else
    process_asset_cmd() {
      touch "$1"
    }
  fi

  if ! process_asset_cmd "$final_dest" "$contents"; then
    log error "File $final_dest could not be created"
    return 1
  fi

  log info "File $final_dest created"
  return 0
}
