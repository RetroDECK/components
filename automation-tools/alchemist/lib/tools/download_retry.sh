#!/bin/bash

# Retry a command with increasing backoff delays
# Usage: try <max_retries> <initial_delay> <max_delay> <command> [args...]
try() {
  local max_retries="$1"
  local initial_delay="$2"
  local max_delay="$3"
  shift 3

  local attempt=1
  local delay="$initial_delay"

  while [ "$attempt" -le "$max_retries" ]; do
    if "$@"; then
      return 0
    fi

    local exit_code=$?

    if [ "$attempt" -eq "$max_retries" ]; then
      echo "ERROR: Command failed after $max_retries attempts" >&2
      return "$exit_code"
    fi

    echo "WARNING: Attempt $attempt/$max_retries failed. Retrying in ${delay}s..." >&2
    sleep "$delay"

    delay=$((delay * 2))
    if [ "$delay" -gt "$max_delay" ]; then
      delay="$max_delay"
    fi

    attempt=$((attempt + 1))
  done

  return 1
}
