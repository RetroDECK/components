#!/bin/bash

# Extract owner and repo from Codeberg URL
# USAGE: parse_codeberg_url <url>
# RETURNS: owner repo (space-separated)
parse_codeberg_url() {
  local url="$1"

  url="${url%.git}" # Remove .git suffix if present

  if [[ "$url" =~ codeberg\.org[/:]([^/]+)/([^/#?]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
    echo "$owner $repo"
    return 0
  fi

  return 1
}

# Get the latest release version from Codeberg
# USAGE: get_latest_codeberg_release_version <owner> <repo>
# RETURNS: version tag (e.g., v1.2.3)
get_latest_codeberg_release_version() {
  local owner="$1"
  local repo="$2"

  local api_url="https://codeberg.org/api/v1/repos/$owner/$repo/releases"
  
  local response
  response=$(curl -sS "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for $owner/$repo"
    log debug "Codeberg API response:"
    log debug "$response"
    return 1
  fi

  # Parse tag_name from JSON response
  local version
  version=$(echo "$response" | jq -r '.tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse latest version from Codeberg API response"
    log debug "Codeberg API response parsed version:"
    log debug "$version"
    return 1
  fi

  echo "$version"
  return 0
}

# Get the most recent release version from Codeberg, including pre-releases
# USAGE: get_newest_codeberg_release_version <owner> <repo>
# RETURNS: version tag (e.g., v1.2.3)
get_newest_codeberg_release_version() {
  local owner="$1"
  local repo="$2"

  local api_url="https://codeberg.org/api/v1/repos/$owner/$repo/releases"
  
  local response
  response=$(curl -sS "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch newest release for $owner/$repo"
    log debug "Codeberg API response:"
    log debug "$response"
    return 1
  fi

  # Parse tag_name from JSON response
  local version
  version=$(echo "$response" | jq -r 'sort_by(.published_at) | reverse | .[0].tag_name')

  if [[ -z "$version" ]]; then
    log error "Could not parse newest version from Codeberg API response"
    log debug "Codeberg API response parsed version:"
    log debug "$version"
    return 1
  fi

  echo "$version"
  return 0
}

# Get release asset download URL matching a pattern
# USAGE: get_release_asset_url <owner> <repo> <version> <pattern>
# RETURNS: download URL
get_codeberg_release_asset_url() {
  local owner="$1"
  local repo="$2"
  local version="$3"
  local pattern="$4"

  local api_url="https://codeberg.org/api/v1/repos/$owner/$repo/releases/tags/$version"
  
  local response
  response=$(curl -sS -D "$headers_file" "$api_url" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch release $version for $owner/$repo"
    log debug "Codeberg API response:"
    log debug "$response"
    return 1
  fi

  # Convert wildcard pattern to grep pattern
  local grep_pattern="${pattern//\*/.*}"

  # Extract all asset names and URLs
  local assets
  assets=$(echo "$response" | jq -r '.assets[].browser_download_url')

  # Find matching asset
  local matched_url
  while IFS= read -r url; do
    local filename
    filename=$(basename "$url")
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
