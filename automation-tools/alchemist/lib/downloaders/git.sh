#!/bin/bash

downloader_info() {
  echo "type:git"
}

download() {
  local url="$1"
  local dest="$2"
  local version="$3"
  local type="$4"
  local max_retries="${5:-3}"
  local initial_delay="${6:-2}"
  local max_delay="${7:-30}"

  local final_dest="$dest"
  local resolved_git_commit="$version"

  # Parse GitHub URL to get owner/repo
  local owner repo
  read -r owner repo <<< "$(parse_github_url "$url")"

  if [[ ! -n "$owner" || ! -n "$repo" ]]; then
    log error "Could not parse GitHub owner/repo from URL: $url"
    return 1
  fi

  if [[ ! "$final_dest" = /* ]]; then # If provided dest path is relative
    final_dest="$WORKDIR/$final_dest"
  elif [[ "$final_dest" == "$WORKDIR" ]]; then  # or is the base WORKDIR
    final_dest="$WORKDIR/$repo"
  fi

  if [[ ! -d "$final_dest" ]]; then
    log info "Dest directory $final_dest does not exist, creating..."
    mkdir -p "$final_dest"
  fi

  if [[ "$version" == "latest" ]]; then # Resolve "latest" commit if needed
    log info "Resolving $version commit for $url"
    resolved_git_commit=$(get_latest_git_commit_version "$owner" "$repo")
    if [[ $? -ne 0 || -z "$resolved_git_commit" ]]; then
      log error "Failed to resolve latest git commit"
      return 1
    fi
    log info "Resolved latest version: $resolved_git_commit"
  fi

  log info "Cloning repository: $url"
  log info "Commit hash: $resolved_git_commit"
  log info "Destination: $final_dest"

  download_cmd() {
    git clone --depth 1 "$1" "$2"
    cd "$2"
    git fetch --depth 1 origin "$3"
    git checkout "$3"
  }

  if ! try "$max_retries" "$initial_delay" "$max_delay" download_cmd "$url" "$final_dest" "$resolved_git_commit"; then
    log error "Git clone failed: $base_url"
    return 1
  fi

  # Verify clone succeeded
  if [[ ! -d "$final_dest/.git" ]]; then
    log error "Git clone verification failed: $final_dest"
    return 1
  fi

  log info "Clone completed successfully"
  echo "DOWNLOADED_VERSION=$resolved_git_commit"
  echo "DOWNLOADED_FILE=$final_dest"
  return 0
}
