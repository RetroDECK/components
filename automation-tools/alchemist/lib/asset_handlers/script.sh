#!/bin/bash

asset_handler_info() {
  echo "type:script,source,execute"
}

handle_asset() {
  local type="$1"
  local source="$2"
  local contents"$4"

  local final_source="$source"

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$EXTRACTED_PATH/$source"
  fi

  if [[ ! -e "$final_source" ]]; then
    log error "Provided source $final_source does not exist, cannot process asset"
    return 1
  fi

  if [[ "$type" == "script" ]]; then # Default to "source" action if type is default "script"
    type="source"
  fi

  case "$type" in
    source)
      process_asset_cmd() {
        bash "$1"
      }
    ;;
    execute)
      process_asset_cmd() {
        bash "$1" "$2"
      }
    ;;
    *)
      log error "Error: Unsupported type: $type"
      return 1
    ;;
  esac

  log info "Running script: $final_source"

  if ! process_asset_cmd "$final_source" "$contents"; then
    log error "Asset script \"$final_source\" could not be processed."
    return 1
  fi

  log info "Asset script \"$final_source\" successfully run."
  return 0
}
