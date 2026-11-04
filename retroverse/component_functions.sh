#!/bin/bash

export retroverse_data="$XDG_CONFIG_HOME/retroverse"

#########################################
# Helpers
#########################################

get_client_schema::retroverse() {
  # Print the client schema version declared in this component's manifest
  # USAGE: get_client_schema::retroverse

  local schema
  schema=$(jq -r '.[] | .manifest | select(has("retroverse")) | .retroverse.client_schema_version // empty' "$component_manifest_cache_file")
  if [[ ! "$schema" =~ ^[0-9]+$ ]]; then
    log e "RetroVERSE client_schema_version is missing or not an integer in the component manifest"
    return 1
  fi
  printf '%s' "$schema"
}

get_supported_store_schema::retroverse() {
  # Print the highest store schema version this client can read, from this component's manifest
  # USAGE: get_supported_store_schema::retroverse

  local schema
  schema=$(jq -r '.[] | .manifest | select(has("retroverse")) | .retroverse.store_schema_version // empty' "$component_manifest_cache_file")
  if [[ ! "$schema" =~ ^[0-9]+$ ]]; then
    log e "RetroVERSE store_schema_version is missing or not an integer in the component manifest"
    return 1
  fi
  printf '%s' "$schema"
}

get_source_repo::retroverse() {
  # Print the GitHub owner/repo for a configured store source.
  # USAGE: get_source_repo::retroverse "$source_id"

  local source_id="$1"
  local repo
  repo=$(jq -r --arg source "$source_id" '.[] | .manifest | select(has("retroverse")) | .retroverse.sources[$source].repo // empty' "$component_manifest_cache_file")
  if [[ -z "$repo" ]]; then
    log e "No RetroVERSE source named $source_id is configured"
    return 1
  fi
  printf '%s' "$repo"
}

resolve_path::retroverse() {
  # Resolve $name and ${name} tokens anywhere in a path, failing on any unset or empty variable or malformed token
  # The result must be an absolute path. It is written to the named variable; nothing is written on failure.
  # USAGE: resolve_path::retroverse "$path" "$output_variable_name"

  local rv_input="$1"
  local -n rv_resolve_out="$2"
  local rv_remaining="$rv_input"
  local rv_result=""
  local rv_name
  local rv_token_regex='^([^$]*)\$(\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))(.*)$'

  while [[ "$rv_remaining" == *'$'* ]]; do
    if [[ ! "$rv_remaining" =~ $rv_token_regex ]]; then
      log e "Malformed token in path: $rv_input"
      return 1
    fi
    rv_result+="${BASH_REMATCH[1]}"
    rv_name="${BASH_REMATCH[3]:-${BASH_REMATCH[4]}}"
    rv_remaining="${BASH_REMATCH[5]}"
    if [[ -z "${!rv_name+x}" || -z "${!rv_name}" ]]; then
      log e "Unresolvable token \$$rv_name in path: $rv_input"
      return 1
    fi
    rv_result+="${!rv_name}"
  done
  rv_result+="$rv_remaining"

  if [[ "$rv_result" != /* ]]; then
    log e "Path does not resolve to an absolute path: $rv_input -> $rv_result"
    return 1
  fi

  rv_resolve_out="$rv_result"
}

#########################################
# Installed version records handlers, too complicated for set_component_option
#########################################

edit_rd_conf::retroverse() {
  # Apply changes to $rd_conf based on passed filter and arguments
  # USAGE: edit_rd_conf::retroverse "$filter" "[$jq_args...]"

  local filter="$1"
  shift
  if ! jq "$@" "$filter" "$rd_conf" > "$rd_conf.tmp"; then
    rm -f "$rd_conf.tmp"
    log e "Failed to update $rd_conf"
    return 1
  fi
  mv "$rd_conf.tmp" "$rd_conf"
}

get_installed_version::retroverse() {
  # Print the recorded version of an installed item
  # Returns 1 if no version is recorded
  # USAGE: get_installed_version::retroverse "$source_id" "$item_id"

  jq -er --arg source "$1" --arg item "$2" '.retroverse_installed[$source][$item] // empty' "$rd_conf" || return 1
}

set_installed_version::retroverse() {
  # Record the installed version of an item, creating the section as needed
  # USAGE: set_installed_version::retroverse "$source_id" "$item_id" "$version"

  edit_rd_conf::retroverse '.retroverse_installed[$source][$item] = $version' \
    --arg source "$1" --arg item "$2" --arg version "$3"
}

remove_installed_version::retroverse() {
  # Remove an item's version record, dropping the source and the whole section when they become empty
  # USAGE: remove_installed_version::retroverse "$source_id" "$item_id"

  edit_rd_conf::retroverse '
    del(.retroverse_installed[$source][$item])
    | if (.retroverse_installed[$source] // {}) == {} then del(.retroverse_installed[$source]) else . end
    | if (.retroverse_installed // {}) == {} then del(.retroverse_installed) else . end
  ' --arg source "$1" --arg item "$2"
}
