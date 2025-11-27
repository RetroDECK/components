#!/bin/bash

downloader_info() {
  echo "type:github_release,github-release"
}

is_github_release_url() {
  local url="$1"
  [[ "$url" =~ github\.com/[^/]+/[^/]+/releases ]]
}

download() {
  local url="$1"
  local dest="$2"
  local version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"

  local resolved_version="$version"
  local final_url="$url"

  if [[ ! -d "$dest" ]]; then
    log info "Dest directory $dest does not exist, creating..."
    mkdir -p "$dest"
  fi

  if is_github_release_url "$url"; then # Validate URL is for a GitHub release
    log info "Processing GitHub release URL"

    # Parse GitHub URL to get owner/repo
    local owner repo
    read -r owner repo <<< "$(parse_github_url "$url")"

    if [[ ! -n "$owner" || ! -n "$repo" ]]; then
      log error "Could not parse GitHub owner/repo from URL: $url"
      return 1
    fi

    if [[ "$version" == "latest" ]]; then # Resolve "latest" version if needed
      log info "Resolving $version version for $owner/$repo"
      resolved_version=$(get_latest_github_release_version "$owner" "$repo")
      if [[ $? -ne 0 || -z "$resolved_version" ]]; then
        log error "Failed to resolve latest version"
        return 1
      fi
      log info "Resolved latest version: $resolved_version"
    elif [[ "$version" == "newest" ]]; then
      log info "Resolving $version version for $owner/$repo"
      resolved_version=$(get_newest_github_release_version "$owner" "$repo")
      if [[ $? -ne 0 || -z "$resolved_version" ]]; then
        log error "Failed to resolve newest version"
        return 1
      fi
      log info "Resolved newest version: $resolved_version"
    fi

    if has_version_placeholder "$url"; then # Substitute version in URL, if needed
      final_url=$(substitute_version "$url" "$resolved_version")
    else
      final_url="$url"
    fi

    # Check if URL contains wildcards and resolve if needed
    local asset_name
    asset_name=$(basename "$final_url")
    if [[ "$asset_name" == *"*"* ]]; then
      log info "Resolving wildcard pattern: $asset_name"
      final_url=$(get_github_release_asset_url "$owner" "$repo" "$resolved_version" "$asset_name")
      if [[ $? -ne 0 || -z "$final_url" ]]; then
        log error "Failed to resolve asset URL"
        return 1
      fi
      log info "Resolved asset URL: $final_url"
    fi
  else
    log error "Provided URL is not for a GitHub release"
    return 1
  fi

  local final_dest="$dest"
  if [[ -d "$dest" ]]; then # If dest is a directory, extract filename from URL
    local filename
    filename=$(basename "$final_url" | sed 's/[?#].*//')
    final_dest="$dest/$filename"
  fi

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
  echo "DOWNLOADED_VERSION=$resolved_version"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
