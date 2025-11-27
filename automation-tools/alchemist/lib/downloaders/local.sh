#!/bin/bash

downloader_info() {
  echo "type:local"
}

download() {
  local source="$1"
  local dest="$2"

  local final_source="$source"
  local final_dest="$dest"

  if [[ ! -d "$dest" ]]; then
    log error "Dest directory $dest does not exist, exiting..."
    return 1
  fi

  # If supplied file name / path contains version placeholders
  if has_version_placeholder "$source"; then
    final_source=$(substitute_version "$source" "$version")
  fi

  if [[ ! "$final_source" = /* ]]; then # If provided source path is relative
    final_source="$WORKDIR/$final_source"
  fi

  # Check if local filename contains wildcards and resolve if needed
  if [[ "$(basename "$final_source")" == *"*"* ]]; then
    log info "Resolving wildcard pattern: $(basename "$final_source")"

    # Convert wildcard pattern to grep pattern
    local wildcard_filename=$(basename "$final_source")
    local grep_pattern="${wildcard_filename//\*/.*}"

    while IFS= read -r file; do
      local found_filename
      found_filename=$(basename "$file")
      if [[ "$found_filename" =~ ^${grep_pattern}$ ]]; then
        final_source="$(dirname $final_source)/$file"
        break
      fi
    done < <(ls -1 "$(dirname "$final_source")")
  
    if [[ -z "$final_source" ]]; then
      log error "Failed to resolve local file wildcards"
      return 1
    fi
    log info "Resolved wildcard local file: $final_source"
  fi

  if [[ -d "$dest" ]]; then # If the provided dest is a directory
    log info "Destination $dest is a directory, constructing full destination path..."
    final_dest="$dest/$(basename $final_source)"
  fi

  if [[ ! -e "$final_source" ]]; then
    log error "Supplied local source could not be found at $final_source"
    return 1
  fi

  final_dest="$final_source"

  log info "Local source $final_dest validated, proceeding to extraction"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
