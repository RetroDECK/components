#!/bin/bash

set -euo pipefail

# Associative arrays for asset handler registry
declare -A ASSET_HANDLER_TYPES
declare -A ASSET_HANDLER_FILES

# Load all asset handler plugins
load_asset_handlers() {
  local asset_handler_dir="$SCRIPT_DIR/lib/asset_handlers"

  if [[ ! -d "$asset_handler_dir" ]]; then
    log error "Asset handler directory not found: $asset_handler_dir"
    return 1
  fi

  for asset_handler_file in "$asset_handler_dir"/*.sh; do
    if [[ ! -f "$asset_handler_file" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$asset_handler_file")

    # Source the asset handler
    source "$asset_handler_file"

    # Check if asset_handler_info function exists
    if ! declare -f asset_handler_info > /dev/null; then
      log w "Asset handler $filename does not implement asset_handler_info()"
      continue
    fi

    # Parse asset handler info
    local info
    info=$(asset_handler_info)

    local types
    types=$(echo "$info" | grep "^type:" | cut -d: -f2)

    if [[ ! -n "$types" ]]; then
      log error "Asset handler $filename does not specify any types"
      continue
    fi

    # Register each type this asset handler handles
    IFS=',' read -ra TYPE_ARRAY <<< "$types"
    for type in "${TYPE_ARRAY[@]}"; do
      type=$(echo "$type" | xargs)  # Trim whitespace
      ASSET_HANDLER_TYPES["$type"]="$filename"
      ASSET_HANDLER_FILES["$filename"]="$asset_handler_file"
    done

    log info "Loaded asset handler: $filename (types: $types)"
  done
}

parse_asset_args() {
  type=""
  source=""
  dest=""
  contents=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        type="$2"
        shift 2
        ;;
      -s|--source)
        source="$2"
        shift 2
        ;;
      -d|--dest)
        dest="$2"
        shift 2
        ;;
      -c|--contents)
        contents="$2"
        shift 2
        ;;
      *)
        log error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$type" || ( ! -n "$source" && ! -n "$dest" ) ]]; then
    log error "Missing required arguments"
    return 1
  fi
}

process_asset() {
  load_asset_handlers

  parse_asset_args "$@"

  # Find appropriate asset handler for the specified type
  if [[ ! -n "${ASSET_HANDLER_TYPES[$type]:-}" ]]; then
    log error "No asset handler found for type: $type"
    return 1
  fi

  local asset_handler_file="${ASSET_HANDLER_TYPES[$type]}"
  source "$SCRIPT_DIR/lib/asset_handlers/$asset_handler_file"
  log info "Using asset handler: $asset_handler_file"

  if ! handle_asset "$type" "$source" "$dest" "$contents"; then
    log error "Processing asset files failed"
    return 1
  fi

  return 0
}
