#!/bin/bash

# Get the latest commit from a GitHub repo
# USAGE: get_latest_git_commit_version <repo>
# RETURNS: version commit hash
get_latest_git_commit_version() {
  local owner="$1"
  local repo="$2"

  local response
  response=$(curl -s "https://api.github.com/repos/$owner/$repo/commits/HEAD" 2>&1)
  local curl_exit=$?

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for https://api.github.com/repos/$owner/$repo/commits/HEAD"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r '.sha')

  if [[ -z "$version" ]]; then
    log error "Could not parse latest version git command"
    return 1
  fi

  echo "$version"
  return 0
}
