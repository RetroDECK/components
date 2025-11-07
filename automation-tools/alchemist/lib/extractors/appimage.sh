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

  local final_dest="$dest/$(basename $archive)-extracted/squashfs-root"

  extract_cmd() {
    chmod +x "$archive"
    cd "$dest" && "$archive" --appimage-extract
    mkdir -p "$dest/$(basename $archive)-extracted"
    mv "$dest/squashfs-root" "$final_dest"
  }

  extract_cmd "$archive"

  if [[ ! -d "$final_dest" ]]; then
    log error "AppImage $archive could not be extracted"
    return 1
  fi

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
