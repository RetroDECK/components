#!/bin/bash

set -euo pipefail

# Create dictionaries for extractor registry
declare -A EXTRACTOR_TYPES
declare -A EXTRACTOR_FILES

extractor_dir="$SCRIPT_DIR/lib/extractors"

load_extractors() {
  if [[ ! -d "$extractor_dir" ]]; then
    log error "Extractors directory not found: $extractor_dir"
    return 1
  fi

  for extractor_file in "$extractor_dir"/*.sh; do
    if [[ ! -f "$extractor_file" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$extractor_file")

    source "$extractor_file"

    if ! declare -f extractor_info > /dev/null; then # Check if extractor_info function exists
      log warn "Extractor $filename does not implement extractor_info()"
      continue
    fi

    # Parse extractor info
    local info
    info=$(extractor_info)

    local types
    types=$(echo "$info" | grep "^type:" | cut -d: -f2)

    if [[ ! -n "$types" ]]; then
      log error "Extractor $filename does not specify any types"
      continue
    fi

    # Register each type this extractor handles
    IFS=',' read -ra TYPE_ARRAY <<< "$types"
    for type in "${TYPE_ARRAY[@]}"; do
      type=$(echo "$type" | xargs)  # Trim whitespace
      EXTRACTOR_TYPES["$type"]="$filename"
      EXTRACTOR_FILES["$filename"]="$extractor_file"
    done

    log info "Loaded extractor: $filename (types: $types)"
  done
}

parse_extract_args() {
  file=""
  dest=""
  type=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        file="$2"
        shift 2
        ;;
      -d|--dest)
        dest="$2"
        shift 2
        ;;
      -t|--type)
        type="$2"
        shift 2
        ;;
      *)
        log error "Unknown option: $1"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ ! -n "$file" || ! -n "$dest" || ! -n "$type" ]]; then
    log error "Missing required arguments"
    exit 1
  fi
}

process_extract() {
  load_extractors

  parse_extract_args "$@"

  if [[ ! -n "${EXTRACTOR_TYPES[$type]:-}" ]]; then # Find appropriate extractor for the specified type
    log error "No extractor found for type: $type"
    return 1
  fi

  local extractor_file="${EXTRACTOR_TYPES[$type]}" # Pull the appropriate extractor module from the dictionary
  source "$extractor_dir/$extractor_file"
  log info "Using extractor: $extractor_file"

  if ! extract "$file" "$dest" "$type"; then
    log error "Extraction failed"
    return 1
  fi

  return 0
}
