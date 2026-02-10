#!/bin/bash

downloader_info() {
  echo "type:http"
}

download() {
  local url="$1"
  local dest="$2"
  local version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"
  local resolve_version="$8"

  local resolved_version="$version"
  local final_url="$url"
  local final_dest="$dest"

  if [[ "$resolve_version" == "true" ]]; then
    echo "DOWNLOADED_VERSION=$SOURCE_VERSION"
    return 0
  fi

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$WORKDIR/$dest"
  fi

  if [[ ! -d "$final_dest" ]]; then
    log info "Dest directory $final_dest does not exist, creating..."
    mkdir -p "$final_dest"
  fi

  if has_version_placeholder "$url"; then # Substitute version placeholder if present
    final_url=$(substitute_version "$url" "$version")
  fi

  # Check if URL looks like it ends with a filename
  local url_basename
  url_basename=$(basename "$final_url" | sed 's/[?#].*//')

  if [[ ! "$url_basename" =~ \.[a-zA-Z0-9]+$ ]]; then # URL doesn't end with a filename, resolve redirects to get final URL
    log info "Resolving redirects to determine filename..."

    local resolved_url
    resolved_url=$(curl -Ls -o /dev/null -w '%{url_effective}' "$final_url" 2>&1)
    if [[ $? -eq 0 && -n "$resolved_url" ]]; then
      log info "Resolved URL: $resolved_url"
      final_url="$resolved_url"
      url_basename=$(basename "$resolved_url" | sed 's/[?#].*//')
    else
      log warn "Could not resolve redirect, using URL basename"
    fi
  fi
  final_dest="$final_dest/$url_basename"

  log info "Downloading: $final_url"
  log info "Destination: $final_dest"

  download_cmd() {
    wget -q -O "$final_dest" "$final_url" 2>&1
  }

  if ! try "$max_retries" "$initial_delay" "$max_delay" download_cmd; then
    log error "Download failed: $final_url"
    return 1
  fi

  if [[ ! -f "$final_dest" || ! -s "$final_dest" ]]; then # Verify file exists and is not empty
    log error "Downloaded file is missing or empty: $dest"
    return 1
  fi

  log info "Download completed successfully"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
