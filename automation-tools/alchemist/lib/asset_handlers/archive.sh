#!/bin/bash

asset_handler_info() {
  echo "type:archive,7z,zip,tar.gz,tgz,tar.bz2,tbz2,tar.xz,txz,tar"
}

handle_asset() {
  local type="$1"
  local source="$2"
  local dest="$3"

  local archive_type

  if [[ "$type" == "archive" ]]; then
    archive_type="tar.gz"
  else
    archive_type="$type"
  fi

  local final_source="$source"
  local final_dest="$dest"

  if [[ ! "$final_source" = /* ]]; then # If provided dest path is relative
    final_source="$EXTRACTED_PATH/$source"
  fi

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$COMPONENT_ARTIFACT_ROOT/$dest"
  fi

  final_dest="$final_dest.$archive_type"

  if [[ ! -d "$(dirname "$final_dest")" ]]; then
    log info "Destination directory $(dirname "$final_dest") does not exist. Creating..."
    mkdir -p "$(dirname "$final_dest")"
  fi

  log info "Creating archive file $final_dest"

  case "$archive_type" in
    7z)
      process_asset_cmd() {
        7z a "$2" "$1"
      }
      ;;
    zip)
      process_asset_cmd() {
        zip -r "$2" "$1"
      }
      ;;
    tar.gz|tgz)
      process_asset_cmd() {
        tar -czf "$2" "$1"
      }
      ;;
    tar.bz2|tbz2)
      process_asset_cmd() {
        tar -cjf "$2" "$1"
      }
      ;;
    tar.xz|txz)
      process_asset_cmd() {
        tar -cJf "$2" "$1"
      }
      ;;
    tar)
      process_asset_cmd() {
        tar -cf "$2" "$1"
      }
      ;;
    *)
      log error "Error: Unsupported archive type: $archive_type"
      return 1
      ;;
  esac

  cd "$(dirname $final_source)"
  final_source="$(basename $final_source)"

  if ! process_asset_cmd "$final_source" "$final_dest"; then
    log error "Archive $final_dest could not be created"
    return 1
  fi

  log info "Archive $final_dest created"
  return 0
}
