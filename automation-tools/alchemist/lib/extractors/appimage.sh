#!/bin/bash

extractor_info() {
  echo "type:appimage"
}

extract() {
  local archive="$1"
  local dest="$2"
  local type="$3"

  if [[ ! -f "$archive" ]]; then
    log error "File $archive not found"
    return 1
  fi

  local final_dest="$dest/$(basename $archive)-extracted"

  extract_cmd() {
    mkdir -p "$final_dest"
    chmod +x "$archive"
    cd "$final_dest" && "$archive" --appimage-extract
  }

  extract_cmd "$archive"

  if [[ ! -e "$final_dest/squashfs-root" ]]; then
    log error "AppImage $archive could not be extracted"
    return 1
  fi

  final_dest="$final_dest/squashfs-root"

  if [[ ! "$DRYRUN" == "true" ]]; then
    log info "Extraction successful, removing downloaded archive $archive"
    rm "$archive"
  else
    log info "Extraction successful, skipping downloaded archive remove for dry-run"
  fi

  log info "AppImage $archive was successfully extracted"
  echo "EXTRACTED_PATH=$final_dest"
  return 0
}
