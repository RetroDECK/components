#!/bin/bash

# Get the latest commit from a GitHub repo
# USAGE: get_latest_git_commit_version <repo>
# RETURNS: version commit hash
get_latest_git_commit_version() {
  local owner="$1"
  local repo="$2"
  local GH_TOKEN="${GH_TOKEN:-}"

  local response
  if [[ -n "$GH_TOKEN" ]]; then
    log debug "GH_TOKEN detected."
    response=$(curl -s -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$owner/$repo/commits/HEAD" 2>&1)
    local curl_exit=$?
  else
    log debug "No GH_TOKEN detected."
    response=$(curl -s "https://api.github.com/repos/$owner/$repo/commits/HEAD" 2>&1)
    local curl_exit=$?
  fi

  if [[ "$curl_exit" -ne 0 ]]; then
    log error "Failed to fetch latest release for https://api.github.com/repos/$owner/$repo/commits/HEAD"
    log debug "GitHub API response:"
    log debug "$response"
    return 1
  fi

  local version
  version=$(echo "$response" | jq -r '.sha')

  if [[ -z "$version" ]]; then
    log error "Could not parse latest version git command"
    log debug "GitHub API response parsed version:"
    log debug "$version"
    return 1
  fi

  echo "$version"
  return 0
}
