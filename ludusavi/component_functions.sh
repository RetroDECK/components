#!/bin/bash

# Component paths
export LUDUSAVI_CONFIG_DIR="$XDG_CONFIG_HOME/ludusavi"
export LUDUSAVI_CONFIG_FILE="$LUDUSAVI_CONFIG_DIR/config.yaml"
export LUDUSAVI_RCLONE_CONFIG_FILE="$XDG_CONFIG_HOME/ludusavi/rclone.conf"
# sidecar_read::ludusavi exit codes
export LUDUSAVI_READ_OK=0
export LUDUSAVI_READ_MISSING=1       # no sidecar present on the remote
export LUDUSAVI_READ_MALFORMED=2     # present but not valid/complete JSON
export LUDUSAVI_READ_UNREACHABLE=3   # network/auth/config failure

# evaluate_gate::ludusavi exit codes
export LUDUSAVI_GATE_SYNC=0          # remote moved since this install last converged with it
export LUDUSAVI_GATE_NOTHING_NEW=1   # remote unchanged since this install last converged
export LUDUSAVI_GATE_FIRST_UPLOAD=2  # remote is empty; mark pending upload
export LUDUSAVI_GATE_BLOCKED=3       # remote is newer than local
export LUDUSAVI_GATE_UNSAFE=4        # unknown state; refuse rather than assume
export LUDUSAVI_GATE_UNREACHABLE=5   # could not reach the remote
# Component definitions
export LUDUSAVI_PROVIDERS=(
  "drive|Google Drive|drive|oauth"
  "dropbox|Dropbox|dropbox|oauth"
  "onedrive|OneDrive|onedrive|oauth"
  "box|Box|box|oauth"
  "smb|Network share (SMB)|smb|form"
  "ftp|FTP server|ftp|form"
  "webdav|WebDAV (Nextcloud, ownCloud)|webdav|form"
)
export LUDUSAVI_OAUTH_PORT=53682
export LUDUSAVI_TEST_TIMEOUT="${LUDUSAVI_TEST_TIMEOUT:-10s}"
export LUDUSAVI_RCLONE_TIMEOUT="${LUDUSAVI_RCLONE_TIMEOUT:-10s}"
export LUDUSAVI_RCLONE_CONNECTION_TIMEOUT="${LUDUSAVI_RCLONE_CONNECTION_TIMEOUT:-5s}"
export LUDUSAVI_SIDECAR_NAME="retrodeck-sync.json"
export LUDUSAVI_SIDECAR_SCHEMA=1

_prepare_component::ludusavi() {
  local action="$1"
  shift

  local component_config="$(get_own_component_path)/rd_config"

  case "$action" in

    reset)
      log i "--------------------------------"
      log i "Resetting Ludusavi"
      log i "--------------------------------"

      create_dir -d "$LUDUSAVI_CONFIG_DIR"
      cp -fv "$component_config/config.yaml" "$LUDUSAVI_CONFIG_FILE"
    ;;

    startup)
      log i "--------------------------------"
      log i "Starting Ludusavi"
      log i "--------------------------------"
      local component_path="$(get_own_component_path)"

      run_ludusavi_backup "startup"
    ;;

    shutdown)
      log i "--------------------------------"
      log i "Shutting down Ludusavi"
      log i "--------------------------------"

      run_ludusavi_backup "shutdown"
    ;;

  esac
}

start::ludusavi() {
  log d "Starting Ludusavi"
  local component_path="$(get_own_component_path)"
  /bin/bash ${component_path}/component_launcher.sh "$@"
}

# ------------------
# Ludusavi helpers
# ------------------

load_config::ludusavi() {
  # USAGE: load_config::ludusavi
  # Reads the user settings into LUDUSAVI_* for this run
  # Returns 1 when cloud sync is enabled but not fully configured

  export LUDUSAVI_CLOUD_SYNC_ENABLED="$(get_component_option "ludusavi" "cloud_sync")"
  export LUDUSAVI_BACKUP_PATH="$(get_component_option "ludusavi" "backup_path")"
  export LUDUSAVI_REMOTE="$(get_component_option "ludusavi" "cloud_remote")"
  export LUDUSAVI_REMOTE_ROOT="$(get_component_option "ludusavi" "cloud_remote_root")"

  if [[ -z "$LUDUSAVI_BACKUP_PATH" ]]; then
    log e "backup_path is not set for Ludusavi cloud sync"
    return 1
  fi

  if [[ "$LUDUSAVI_CLOUD_SYNC_ENABLED" == "true" && -z "$LUDUSAVI_REMOTE" ]]; then
    log e "cloud sync is enabled but cloud_remote is not set"
    return 1
  fi

  return 0
}

setup_checks::ludusavi() {
  # USAGE: setup_checks::ludusavi
  # Validates the Ludusavi and rclone setup is complete before first sync run

  local component_path="$(get_own_component_path)"

  if ! command -v "$component_path/bin/rclone" > /dev/null 2>&1; then
    log e "rclone not found: $component_path/bin/rclone"
    return 1
  fi

  if [[ ! -r "$LUDUSAVI_RCLONE_CONFIG_FILE" ]]; then
    log e "rclone config not readable: $LUDUSAVI_RCLONE_CONFIG_FILE"
    return 1
  fi

  if [[ -z "$LUDUSAVI_REMOTE" ]]; then
    log e "LUDUSAVI_REMOTE is unset"
    return 1
  fi

  if ! rclone::ludusavi lsf "$LUDUSAVI_REMOTE" --max-depth 1 > /dev/null 2>&1; then
    log e "remote does not resolve: $LUDUSAVI_REMOTE"
    return 1
  fi

  return 0
}

sidecar_url::ludusavi() {
  # USAGE: sidecar_url::ludusavi
  # Returns the URL of the currently configured remotes sidecar file
  echo "${LUDUSAVI_REMOTE}${LUDUSAVI_REMOTE_ROOT}/${LUDUSAVI_SIDECAR_NAME}"
}

rclone::ludusavi() {
  # USAGE: rclone:ludusavi <args>
  # Launches rclone with online-enabled arguments, for use with online operations

  local component_path="$(get_own_component_path)"

  "$component_path/bin/rclone" \
    --config "$LUDUSAVI_RCLONE_CONFIG_FILE" \
    --timeout "$LUDUSAVI_RCLONE_TIMEOUT" \
    --contimeout "$LUDUSAVI_RCLONE_CONNECTION_TIMEOUT" \
    --retries 1 \
    --low-level-retries 1 \
    "$@"
}

rclone_cfg::ludusavi() {
  # USAGE: rclone_cfg::ludusavi
  # Launches rclone without online-enabled arguments, for making local config changes

  local component_path="$(get_own_component_path)"
  "$component_path/bin/rclone" --config "$LUDUSAVI_RCLONE_CONFIG_FILE" "$@" < /dev/null
}

generate_install_id::ludusavi() {
  # USAGE: generate_install_id::ludusavi
  # Generates a UUID for this specific install of RetroDECK, so that different syncing devices can be differentiated

  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
    return 0
  fi

  if command -v uuidgen > /dev/null 2>&1; then
    uuidgen
    return 0
  fi

  log e "no source of UUIDs available"
  return 1
}

install_id::ludusavi() {
  # USAGE: install_id::ludusavi
  # Returns the stored install id, creating one if it does not exist
  
  local install_id

  install_id="$(get_component_option "ludusavi" "install_id")"
  if [[ -n "$install_id" ]]; then
    echo "$install_id"
    return 0
  fi

  install_id="$(generate_install_id::ludusavi)" || return 1

  set_component_option "ludusavi" "install_id" "$install_id" || return 1

  echo "$install_id"
  return 0
}

provider_field::ludusavi() {
  # USAGE: provider_field::ludusavi "$provider_id" "label|type|kind"
  # Prints one field of a provider's catalog entry. Returns 1 for an unknown id.
  
  local provider_id="$1"
  local field="$2"

  local entry
  for entry in "${LUDUSAVI_PROVIDERS[@]}"; do
    local id label type kind
    IFS='|' read -r id label type kind <<< "$entry"
    if [[ "$id" == "$provider_id" ]]; then
      case "$field" in
        label) echo "$label" ;;
        type) echo "$type" ;;
        kind) echo "$kind" ;;
        *) return 1 ;;
      esac
      return 0
    fi
  done

  return 1
}

# ------------------
# Ludusavi sidecar handlers
# ------------------

sidecar_read::ludusavi() {
  # USAGE: sidecar_read::ludusavi
  # Checks the remote sidecar file for syntax and returns contents if there are no issues

  local url
  url="$(sidecar_url::ludusavi)"

  local contents
  local rclone_status

  contents="$(rclone::ludusavi cat "$url" 2>/dev/null)"
  rclone_status=$?

  if [[ "$rclone_status" -ne 0 ]]; then
    # rclone does not reliably distinguish "not found" from "unreachable" by exit code, so probe remote to tell them apart
    if rclone::ludusavi lsf "${LUDUSAVI_REMOTE}" --max-depth 1 > /dev/null 2>&1; then
      log d "no sidecar at $url"
      return "$LUDUSAVI_READ_MISSING"
    fi
    log w "remote unreachable while reading sidecar"
    return "$LUDUSAVI_READ_UNREACHABLE"
  fi

  if [[ -z "$contents" ]]; then
    log w "sidecar is empty"
    return "$LUDUSAVI_READ_MALFORMED"
  fi

  if ! jq -e . > /dev/null 2>&1 <<< "$contents"; then
    log w "sidecar is not valid JSON"
    return "$LUDUSAVI_READ_MALFORMED"
  fi

  # Validate sidecar file 
  if ! jq -e '
        has("schema") and has("retrodeck_version")
        and has("install_id") and has("updated_at") and has("state")
      ' > /dev/null 2>&1 <<< "$contents"; then
    log w "sidecar is missing required fields"
    return "$LUDUSAVI_READ_MALFORMED"
  fi

  echo "$contents"
  return "$LUDUSAVI_READ_OK"
}

sidecar_write::ludusavi() {
  # USAGE: sidecar_write::ludusavi "$install_id" "<uploading|ok>"
  #
  # "uploading" is written before the transfer starts, "ok" is written after it completes
  # This way an interrupted sync is marked accurately

  local install_id="$1"
  local state="$2"

  if [[ "$state" != "uploading" && "$state" != "ok" ]]; then
    log e "invalid sidecar state: $state"
    return 1
  fi

  local updated_at
  updated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local payload
  payload="$(jq -n \
    --argjson schema "$LUDUSAVI_SIDECAR_SCHEMA" \
    --arg retrodeck_version "$version" \
    --arg install_id "$install_id" \
    --arg updated_at "$updated_at" \
    --arg state "$state" \
    '{
      schema: $schema,
      retrodeck_version: $retrodeck_version,
      install_id: $install_id,
      updated_at: $updated_at,
      state: $state
    }')"

  local url
  url="$(sidecar_url:ludusavi)"

  if ! rclone::ludusavi rcat "$url" <<< "$payload"; then
    log e "failed to write sidecar to $url"
    return 1
  fi

  # Save the install ID and time so the next launch can tell if anything has written to the remote since
  echo "${install_id}/${updated_at}"
  return 0
}

sidecar_marker::ludusavi() {
  # USAGE: sidecar_marker::ludusavi "$payload"
  # Prints the sync markers from the sidecar contents

  jq -r '"\(.install_id)/\(.updated_at)"' <<< "$1"
}

# ------------------
# Ludusavi cloud validation
# ------------------

evaluate_gate::ludusavi() {
  # USAGE: evaluate_gate::ludusavi "$last_synced_marker"
  # Validates the contents of the remote sidecar file, compares them to the local last synced marker and determines if a sync is needed

  local local_version="$1"
  local last_synced_marker="$2"

  local contents
  local read_status

  contents="$(sidecar_read::ludusavi)"
  read_status=$?

  case "$read_status" in
    "$LUDUSAVI_READ_UNREACHABLE")
      return "$LUDUSAVI_GATE_UNREACHABLE"
      ;;
    "$LUDUSAVI_READ_MISSING")
      # Missing on an empty remote is a first run. Missing on a populated
      # remote means something wrote data we cannot account for.
      if remote_is_empty::ludusavi; then
        return "$LUDUSAVI_GATE_FIRST_UPLOAD"
      fi
      log w "remote holds data but has no sidecar; refusing to sync"
      return "$LUDUSAVI_GATE_UNSAFE"
      ;;
    "$LUDUSAVI_READ_MALFORMED")
      return "$LUDUSAVI_GATE_UNSAFE"
      ;;
  esac

  local remote_state
  remote_state="$(jq -r '.state' <<< "$contents")"

  if [[ "$remote_state" != "ok" ]]; then
    log w "remote sidecar state is '$remote_state'; a previous upload did not finish"
    return "$LUDUSAVI_GATE_UNSAFE"
  fi

  local remote_schema
  remote_schema="$(jq -r '.schema' <<< "$contents")"

  if [[ "$remote_schema" -gt "$LUDUSAVI_SIDECAR_SCHEMA" ]]; then
    log w "remote sidecar schema $remote_schema is newer than supported"
    return "$LUDUSAVI_GATE_UNSAFE"
  fi

  local remote_version
  remote_version="$(jq -r '.retrodeck_version' <<< "$contents")"

  compare_versions "$remote_version" "$local_version"
  local comparison=$?

  case "$comparison" in
    "$RD_VERSION_NEWER")
      log w "cloud backup is from RetroDECK $remote_version, local is $local_version"
      return "$LUDUSAVI_GATE_BLOCKED"
      ;;
    "$RD_VERSION_INCOMPARABLE")
      log w "cloud backup version $remote_version cannot be ordered against local $local_version"
      return "$LUDUSAVI_GATE_UNSAFE"
      ;;
    "$RD_VERSION_UNPARSEABLE")
      log w "could not parse version pair: '$remote_version' / '$local_version'"
      return "$LUDUSAVI_GATE_UNSAFE"
      ;;
  esac

  # Check sidecar sync stamp for changes
  local remote_marker
  remote_marker="$(sidecar_marker::ludusavi "$contents")"
  echo "$remote_marker"

  if [[ -n "$last_synced_marker" && "$remote_marker" == "$last_synced_marker" ]]; then
    return "$LUDUSAVI_GATE_NOTHING_NEW"
  fi

  return "$LUDUSAVI_GATE_SYNC"
}

# ------------------
# Ludusavi API
# ------------------

_exec::ludusavi() {
  # USAGE: _exec::ludusavi "$args"
  # Exec Ludusavi without stdin, avoiding unintentional pipe inheritence from above hanging the whole process
  # Needs underscore prefix to avoid Bash interpretation of exec

  exec_input::ludusavi "$@" < /dev/null
}

exec_input::ludusavi() {
  # USAGE: exec_input::ludusavi "$args" <<< "$input"
  # As _exec, but passes the caller's stdin through
  # Only for Ludusavi API use, which reads its request from stdin

  local -a global_args=(--try-manifest-update)
  local component_path="$(get_own_component_path)"

  if [[ -n "$LUDUSAVI_CONFIG_DIR" ]]; then
    global_args+=(--config "$LUDUSAVI_CONFIG_DIR")
  fi

  "$component_path/bin/ludusavi" "${global_args[@]}" "$@"
}

cloud_args::ludusavi() {
  # USAGE: cloud_args::ludusavi
  # Prints the --local/--cloud pair for the cloud commands

  printf '%s\n' --local "$LUDUSAVI_BACKUP_PATH" --cloud "${LUDUSAVI_REMOTE_ROOT}/ludusavi"
}

backup::ludusavi() {
  # USAGE: backup::ludusavi
  # Backs up into the backup directory and returns the API JSON output
  # Cloud sync is explicitly disabled here, the upload is a separate step so the sidecar can be marked "uploading" between the two

  local -a args=(backup --force --api --no-cloud-sync --path "$LUDUSAVI_BACKUP_PATH")

  local output
  output="$(_exec::ludusavi "${args[@]}" 2>/dev/null)"
  local ludusavi_status=$?

  if [[ "$ludusavi_status" -ne 0 ]] || [[ -z "$output" ]]; then
    log e "backup failed for $LUDUSAVI_BACKUP_PATH"
    return 1
  fi

  if ! jq -e . > /dev/null 2>&1 <<< "$output"; then
    log e "backup produced unparseable output for $LUDUSAVI_BACKUP_PATH"
    return 1
  fi

  echo "$output"
  return 0
}

changed_count::ludusavi() {
  # USAGE: changed_count::ludusavi "$backup_json"
  # Returns how many differences there in the backup from the provided backup results
  # Zero means there are no new changes worth uploading

  local backup_json="$1"

  jq -r '
    (.overall.changedGames.new // 0) + (.overall.changedGames.different // 0)
  ' <<< "$backup_json" 2>/dev/null
}

changed_games::ludusavi() {
  # USAGE: changed_games::ludusavi "$backup_json"
  # Returns the Ludusavi entries which have changed since the last backup

  local backup_json="$1"

  jq -r '
    .games
    | to_entries[]
    | select(.value.decision == "Processed")
    | select(.value.change == "New" or .value.change == "Different")
    | .key
  ' <<< "$backup_json" 2>/dev/null
}

ludusavi::stamp_backups() {
  # USAGE: ludusavi::stamp_backups "$version" "$backup_json"
  # Writes "RetroDECK <version>" as the comment on each changed entries latest backup

  local version="$1"
  local backup_json="$2"

  local -a games
  mapfile -t games < <(changed_games::ludusavi "$backup_json")

  if [[ "${#games[@]}" -eq 0 ]]; then
    return 0
  fi

  local request
  request="$(jq -n \
    --arg path "$LUDUSAVI_BACKUP_PATH" \
    --arg comment "RetroDECK ${version}" \
    '{
      config: {backupPath: $path},
      requests: [$ARGS.positional[] | {editBackup: {game: ., comment: $comment}}]
    }' \
    --args "${games[@]}")"

  local response
  if ! response="$(exec_input::ludusavi api <<< "$request" 2>/dev/null)"; then
    log w "could not stamp ${#games[@]} backup(s) with RetroDECK $version"
    return 0
  fi

  # Parse API output for failure logs, since failures still exit 0
  local failed
  failed="$(jq -r '[.responses[]? | select(has("error"))] | length' <<< "$response" 2>/dev/null)"
  : "${failed:=0}"

  if [[ "$failed" -gt 0 ]]; then
    log w "$failed of ${#games[@]} backup(s) could not be stamped with RetroDECK $version"
  else
    log d "stamped ${#games[@]} backup(s) with RetroDECK $version"
  fi
  return 0
}
