#!/bin/bash

parse_gitlab_url() {
  local url="$1"

  url="${url%.git}" # Remove .git suffix if present

  if [[ "$url" =~ (https?://[^/]+)/([^/]+)/([^/#?]+) ]]; then
    local instance="${BASH_REMATCH[1]}"
    local owner="${BASH_REMATCH[2]}"
    local repo="${BASH_REMATCH[3]}"
    echo "$instance $owner $repo"
    return 0
  fi

  return 1
}

urlencode_project_path() {
  local owner="$1"
  local repo="$2"
  echo "${owner}%2F${repo}"
}

get_latest_gitlab_release_version() {
  local instance="$1"
  local owner="$2"
  local repo="$3"

  local project_path
  project_path=$(urlencode_project_path "$owner" "$repo")

  local api_url="${instance}/api/v4/projects/${project_path}/releases/permalink/latest"
  local response
  response=$(curl -fsSL "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for $owner/$repo from $instance"
    log debug "GitLab API response:"
    log debug "$response"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r '.tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse version from GitLab API response"
    log debug "GitLab API response parsed version:"
    log debug "$version"
    return 1
  fi

  echo "$version"
  return 0
}

get_newest_gitlab_release_version() {
  local instance="$1"
  local owner="$2"
  local repo="$3"

  local project_path
  project_path=$(urlencode_project_path "$owner" "$repo")

  local api_url="${instance}/api/v4/projects/${project_path}/releases"
  local response
  response=$(curl -fsSL "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for $owner/$repo from $instance"
    log debug "GitLab API response:"
    log debug "$response"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r 'sort_by(.released_at) | reverse | .[0].tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse version from GitLab API response"
    log debug "GitLab API response parsed version:"
    log debug "$version"
    return 1
  fi

  echo "$version"
  return 0
}

get_gitlab_release_asset_url() {
  local instance="$1"
  local owner="$2"
  local repo="$3"
  local version="$4"
  local pattern="$5"

  local project_path
  project_path=$(urlencode_project_path "$owner" "$repo")

  local api_url="${instance}/api/v4/projects/${project_path}/releases/${version}"
  local response
  response=$(curl -fsSL "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch release $version for $owner/$repo from $instance"
    log debug "GitLab API response:"
    log debug "$response"
    return 1
  fi

  local grep_pattern="${pattern//\*/.*}"

  local assets
  assets=$(echo "$response" | jq -r '.assets.links[].url')

  local matched_url
  while IFS= read -r url; do
    local filename
    filename=$(basename "$url" | sed 's/[?#].*//')
    log debug "Checking release url: $url"
    if [[ "$filename" =~ ^${grep_pattern}$ ]]; then
      matched_url="$url"
      break
    fi
  done <<< "$assets"

  if [[ -z "$matched_url" ]]; then
    log error "No asset matching pattern '$pattern' found in release $version"
    return 1
  fi

  echo "$matched_url"
  return 0
}
