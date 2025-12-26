#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <component_dir> [--verbose]" >&2
  exit 2
}

if [[ $# -lt 1 ]]; then
  usage
fi

component="$1"
verbose=false
if [[ "${2:-}" == "--verbose" ]]; then
  verbose=true
fi

log() {
  $verbose && echo "[detect_changes] $*"
}

# If GITHUB_EVENT_PATH is set and points to a file, prefer PR metadata
event_json="${GITHUB_EVENT_PATH:-}"

detect_pr_changes() {
  local base_sha head_sha base_ref head_ref
  base_sha=$(jq -r '.pull_request.base.sha // empty' "$event_json" 2>/dev/null || true)
  head_sha=$(jq -r '.pull_request.head.sha // empty' "$event_json" 2>/dev/null || true)
  base_ref=$(jq -r '.pull_request.base.ref // empty' "$event_json" 2>/dev/null || true)
  head_ref=$(jq -r '.pull_request.head.ref // empty' "$event_json" 2>/dev/null || true)

  if [[ -n "$base_sha" && -n "$head_sha" ]]; then
    log "PR detected: base=$base_ref($base_sha) head=$head_ref($head_sha)"
    # Fetch refs; best-effort
    git fetch --no-tags --depth=1 origin "$base_sha" 2>/dev/null || git fetch --no-tags origin "$base_ref" 2>/dev/null || true
    git fetch --no-tags --depth=1 origin "$head_sha" 2>/dev/null || git fetch --no-tags origin "$head_ref" 2>/dev/null || true

    changed=$(git diff --name-only "$base_sha" "$head_sha" || true)
    echo "$changed" | grep -qE "^${component}(/|$)" && { log "changed (PR)"; return 0; } || { log "no change (PR)"; return 1; }
  fi
  return 1
}

detect_push_changes() {
  # Prefer push event SHAs (before/after) if available in event JSON
  if [[ -n "$event_json" && -f "$event_json" ]]; then
    before_sha=$(jq -r '.before // empty' "$event_json" 2>/dev/null || true)
    after_sha=$(jq -r '.after // empty' "$event_json" 2>/dev/null || true)
    if [[ -n "$before_sha" && -n "$after_sha" && "$before_sha" != "$after_sha" ]]; then
      log "Push event detected: before=$before_sha after=$after_sha"
      git fetch --no-tags --depth=1 origin "$before_sha" 2>/dev/null || git fetch --no-tags origin "$before_sha" 2>/dev/null || true
      git fetch --no-tags --depth=1 origin "$after_sha" 2>/dev/null || git fetch --no-tags origin "$after_sha" 2>/dev/null || true
      changed=$(git diff --name-only "$before_sha" "$after_sha" || true)
      echo "$changed" | grep -qE "^${component}(/|$)" && { log "changed (push event)"; return 0; } || { log "no change (push event)"; return 1; }
    fi
  fi

  # Next prefer comparing against a reference cooker release tag if present (downloaded to reference/)
  if [[ -f "reference/reference_tag.txt" ]]; then
    ref_tag=$(< reference/reference_tag.txt)
    if [[ -n "$ref_tag" ]]; then
      log "Comparing against reference tag: $ref_tag"
      git fetch --no-tags --depth=1 origin "refs/tags/$ref_tag" 2>/dev/null || git fetch --no-tags origin "$ref_tag" 2>/dev/null || true
      changed=$(git diff --name-only "$ref_tag" HEAD || true)
      echo "$changed" | grep -qE "^${component}(/|$)" && { log "changed (vs reference tag)"; return 0; } || { log "no change (vs reference tag)"; return 1; }
    fi
  fi

  # Fallback: compare HEAD to previous commit (covers simple cases and avoids always-true compare vs main)
  log "Falling back to compare HEAD^..HEAD"
  # Handle initial commit gracefully
  parent=$(git rev-parse --verify HEAD^ 2>/dev/null || true)
  if [[ -n "$parent" ]]; then
    changed=$(git diff --name-only "$parent" HEAD || true)
    echo "$changed" | grep -qE "^${component}(/|$)" && { log "changed (last commit)"; return 0; } || { log "no change (last commit)"; return 1; }
  fi

  log "No push-related changes detected"
  return 1
}

main() {
  # If there is event JSON, try PR detection first
  if [[ -n "$event_json" && -f "$event_json" ]]; then
    if detect_pr_changes; then
      exit 0
    fi
  fi

  # Otherwise try push/branch detection
  if detect_push_changes; then
    exit 0
  fi

  # Conservatively return 1 (no relevant changes)
  log "No changes detected for component: $component"
  exit 1
}

main
