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

# on_launch::ludusavi
export LUDUSAVI_LAUNCH_PROCEED=0        # synced, or nothing to sync; carry on
export LUDUSAVI_LAUNCH_BLOCKED=1        # cloud is newer; user must update first
export LUDUSAVI_LAUNCH_CONFLICT=2       # local and cloud both moved; ask the user
export LUDUSAVI_LAUNCH_OFFLINE=3        # remote unreachable; retry next launch
export LUDUSAVI_LAUNCH_DISABLED=4       # cloud sync is off
export LUDUSAVI_LAUNCH_FAILED=5         # config, download or restore failed

# on_exit::ludusavi
export LUDUSAVI_EXIT_UPLOADED=0
export LUDUSAVI_EXIT_NO_CHANGES=1       # local backup done, nothing worth uploading
export LUDUSAVI_EXIT_LOCAL_ONLY=2       # local backup done, upload skipped by design
export LUDUSAVI_EXIT_BACKUP_FAILED=3
export LUDUSAVI_EXIT_UPLOAD_FAILED=4

# resolve_conflict::ludusavi
export LUDUSAVI_RESOLVE_OK=0
export LUDUSAVI_RESOLVE_FAILED=1
export LUDUSAVI_RESOLVE_CLOUD_UNSAFE=2  # cloud copy cannot be pulled by this build

# Choices the conflict dialog can return.
export LUDUSAVI_RESOLVE_KEEP_CLOUD="keep_cloud"
export LUDUSAVI_RESOLVE_KEEP_LOCAL="keep_local"
export LUDUSAVI_RESOLVE_DEFER="defer"
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

remote_is_empty::ludusavi() {
  # USAGE: remote_is_empty::ludusavi
  # Returns 0 when the remote root holds nothing, 1 when it holds data, 2 when the remote could not be reached at all
  # A missing directory counts as empty, as a first-run remote has no root yet

  local listing
  local rclone_status

  listing="$(rclone::ludusavi lsf "${LUDUSAVI_REMOTE}${LUDUSAVI_REMOTE_ROOT}" --max-depth 1 2>/dev/null)"
  rclone_status=$?

  if [[ "$rclone_status" -ne 0 ]]; then
    # rclone does not reliably distinguish "not found" from "unreachable" by exit code, so probe remote to tell them apart
    if rclone::ludusavi lsf "${LUDUSAVI_REMOTE}" --max-depth 1 > /dev/null 2>&1; then
      return 0
    fi
    return 2
  fi

  if [[ -z "$listing" ]]; then
    return 0
  fi

  return 1
}

store_has_backups::ludusavi() {
  # USAGE: store_has_backups::ludusavi
  # Returns 0 when the backup directory already holds at least one backup

  local found
  found="$(find "$LUDUSAVI_BACKUP_PATH" -mindepth 2 -maxdepth 2 \
    -name mapping.yaml -print -quit 2>/dev/null)"

  [[ -n "$found" ]]
}

live_saves_diverged::ludusavi() {
  # USAGE: live_saves_diverged::ludusavi
  # Returns 0 when the live saves differ from the local backup store

  local output
  output="$(_exec::ludusavi backup --preview --api --no-cloud-sync \
    --path "$LUDUSAVI_BACKUP_PATH" 2>/dev/null)"

  local changed
  changed="$(changed_count::ludusavi "$output")"

  if [[ ! "$changed" =~ ^[0-9]+$ ]]; then
    log w "could not determine whether live saves changed; assuming they did"
    return 0
  fi

  [[ "$changed" -gt 0 ]]
}

remote_new_name::ludusavi() {
  # USAGE: remote_new_name::ludusavi
  # Generate a new remote name, so a new attempt can never overwrite the remote currently in use

  echo "retrodeck-$(date +%s)-$$-${RANDOM}"
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

  /bin/bash ${component_path}/component_launcher.sh "${global_args[@]}" "$@"
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

stamp_backups::ludusavi() {
  # USAGE: stamp_backups::ludusavi "$version" "$backup_json"
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

# ------------------------------------------------------------------------------
# Launch
# ------------------------------------------------------------------------------

pull::ludusavi() {
  # USAGE: pull::ludusavi "$remote_marker"
  # Downloads the cloud store over the local one, restores it over the live saves, and records the remote state this install has now synced with

  local remote_marker="$1"

  local -a cloud_args
  mapfile -t cloud_args < <(cloud_args::ludusavi)

  if ! _exec::ludusavi cloud download --force --api "${cloud_args[@]}" > /dev/null 2>&1; then
    log e "cloud download failed"
    return 1
  fi

  local restore_output
  restore_output="$(_exec::ludusavi restore --force --api --path "$LUDUSAVI_BACKUP_PATH" 2>/dev/null)"

  if [[ -z "$restore_output" ]]; then
    log e "restore produced no output"
    return 1
  fi

  if jq -e '.errors.someGamesFailed == true' > /dev/null 2>&1 <<< "$restore_output"; then
    log w "some games failed to restore"
  fi

  set_component_option "ludusavi" "last_synced_marker" "$remote_marker"
  set_component_option "ludusavi" "sync_blocked" "false"
  return 0
}

on_launch::ludusavi() {
  # USAGE: on_launch::ludusavi
  # Evaluates the gate and pulls the cloud backups down and restores them
  # Returns $LUDUSAVI_LAUNCH_* specialty code

  load_config::ludusavi || return "$LUDUSAVI_LAUNCH_FAILED"

  if [[ "$LUDUSAVI_CLOUD_SYNC_ENABLED" != "true" ]]; then
    return "$LUDUSAVI_LAUNCH_DISABLED"
  fi

  install_id::ludusavi > /dev/null || return "$LUDUSAVI_LAUNCH_FAILED"

  local last_synced_marker
  last_synced_marker="$(get_component_option "ludusavi" "last_synced_marker")" || last_synced_marker=""

  local pending_upload
  pending_upload="$(get_component_option "ludusavi" "pending_upload")" || pending_upload="false"

  local remote_marker
  remote_marker="$(evaluate_gate::ludusavi "$version" "$last_synced_marker")"
  local gate=$?

  case "$gate" in
    "$LUDUSAVI_GATE_UNREACHABLE")
      return "$LUDUSAVI_LAUNCH_OFFLINE"
      ;;

    "$LUDUSAVI_GATE_FIRST_UPLOAD")
      set_component_option "ludusavi" "pending_upload" "true"
      set_component_option "ludusavi" "sync_blocked" "false"
      return "$LUDUSAVI_LAUNCH_PROCEED"
      ;;

    "$LUDUSAVI_GATE_BLOCKED")
      # Mark the sync gate blocked, but continue with boot
      set_component_option "ludusavi" "sync_blocked" "true"
      return "$LUDUSAVI_LAUNCH_BLOCKED"
      ;;

    "$LUDUSAVI_GATE_UNSAFE")
      set_component_option "ludusavi" "sync_blocked" "true"
      return "$LUDUSAVI_LAUNCH_CONFLICT"
      ;;

    "$LUDUSAVI_GATE_NOTHING_NEW")
      # Nothing new on the remote since the last sync
      set_component_option "ludusavi" "sync_blocked" "false"
      return "$LUDUSAVI_LAUNCH_PROCEED"
      ;;
  esac

  # The remove has changed since last sync
  # Validate local state for changes and conflicts
  local diverged=false

  if [[ "$pending_upload" == "true" ]]; then
    # Unpushed local backups, such as a failed upload or play while blocked
    diverged=true
  elif [[ -z "$last_synced_marker" ]] && store_has_backups::ludusavi; then
    # This install has never synced but there is data in the remote
    diverged=true
  elif live_saves_diverged::ludusavi; then
    # Unaccounted local saves
    diverged=true
  fi

  if [[ "$diverged" == "true" ]]; then
    # Block cloud sync until conflict is resolved by user
    set_component_option "ludusavi" "sync_blocked" "true"
    return "$LUDUSAVI_LAUNCH_CONFLICT"
  fi

  pull::ludusavi "$remote_marker" || return "$LUDUSAVI_LAUNCH_FAILED"
  return "$LUDUSAVI_LAUNCH_PROCEED"
}

resolve_conflict::ludusavi() {
  # USAGE: resolve_conflict::ludusavi "$choice"
  # Applies the user's resolution of a conflict
  # User options are defined in LUDUSAVI_RESOLVE_KEEP_* / LUDUSAVI_RESOLVE_DEFER strings
  # Returns LUDUSAVI_RESOLVE_* specialty code

  local choice="$1"

  case "$choice" in
    "$LUDUSAVI_RESOLVE_KEEP_CLOUD")
      # Re-run the gate rather than trusting the launch result
      local remote_marker
      remote_marker="$(evaluate_gate::ludusavi "$version" "")"
      local gate=$?

      if [[ "$gate" -ne "$LUDUSAVI_GATE_SYNC" ]]; then
        log w "cloud copy cannot be pulled by this build (gate $gate)"
        return "$LUDUSAVI_RESOLVE_CLOUD_UNSAFE"
      fi

      pull::ludusavi "$remote_marker" || return "$LUDUSAVI_RESOLVE_FAILED"
      set_component_option "ludusavi" "pending_upload" "false"
      return "$LUDUSAVI_RESOLVE_OK"
      ;;

    "$LUDUSAVI_RESOLVE_KEEP_LOCAL")
      # Clear the block to upload normally at exit
      set_component_option "ludusavi" "sync_blocked" "false"
      set_component_option "ludusavi" "pending_upload" "true"
      return "$LUDUSAVI_RESOLVE_OK"
      ;;

    "$LUDUSAVI_RESOLVE_DEFER")
      # Block stays set for next launch
      return "$LUDUSAVI_RESOLVE_OK"
      ;;
  esac

  log e "unknown conflict resolution: $choice"
  return "$LUDUSAVI_RESOLVE_FAILED"
}

# ------------------------------------------------------------------------------
# Exit
# ------------------------------------------------------------------------------

on_exit::ludusavi() {
  # USAGE: on_exit::ludusavi
  # Backs up locally, then uploads if anything changed and the session was not blocked
  # Returns LUDUSAVI_EXIT_* specialty code

  local backup_json
  backup_json="$(backup::ludusavi)" || return "$LUDUSAVI_EXIT_BACKUP_FAILED"

  local changed
  changed="$(changed_count::ludusavi "$backup_json")"
  : "${changed:=0}"

  if [[ "$changed" -gt 0 ]]; then
    stamp_backups::ludusavi "$version" "$backup_json"
  fi

  if [[ "$LUDUSAVI_CLOUD_SYNC_ENABLED" != "true" ]]; then
    return "$LUDUSAVI_EXIT_LOCAL_ONLY"
  fi

  local sync_blocked
  sync_blocked="$(get_component_option "ludusavi" "sync_blocked")" || sync_blocked="false"

  local pending_upload
  pending_upload="$(get_component_option "ludusavi" "pending_upload")" || pending_upload="false"

  if [[ "$sync_blocked" == "true" ]]; then
    # Perform a local backup but do not sync to remote
    if [[ "$changed" -gt 0 ]]; then
      set_component_option "ludusavi" "pending_upload" "true"
    fi
    log i "cloud upload skipped: sync is blocked"
    return "$LUDUSAVI_EXIT_LOCAL_ONLY"
  fi

  if [[ "$changed" -eq 0 ]] && [[ "$pending_upload" != "true" ]]; then
    return "$LUDUSAVI_EXIT_NO_CHANGES"
  fi

  upload::ludusavi
  return $?
}

upload::ludusavi() {
  # USAGE: upload::ludusavi

  local install_id
  install_id="$(install_id::ludusavi)" || return "$LUDUSAVI_EXIT_UPLOAD_FAILED"

  # Set pending_upload before starting so it is recorded in the event of failure
  set_component_option "ludusavi" "pending_upload" "true"

  # Mark the sidecar before the transfer
  if ! sidecar_write::ludusavi "$version" "$install_id" "uploading" > /dev/null; then
    return "$LUDUSAVI_EXIT_UPLOAD_FAILED"
  fi

  local -a cloud_args
  mapfile -t cloud_args < <(cloud_args::ludusavi)

  if ! _exec::ludusavi cloud upload --force --api "${cloud_args[@]}" > /dev/null 2>&1; then
    log e "cloud upload failed"
    return "$LUDUSAVI_EXIT_UPLOAD_FAILED"
  fi

  local written_marker
  written_marker="$(sidecar_write::ludusavi "$version" "$install_id" "ok")"

  if [[ -z "$written_marker" ]]; then
    log e "upload completed but sidecar could not be finalised"
    return "$LUDUSAVI_EXIT_UPLOAD_FAILED"
  fi

  set_component_option "ludusavi" "last_synced_marker" "$written_marker"
  set_component_option "ludusavi" "pending_upload" "false"
  return "$LUDUSAVI_EXIT_UPLOADED"
}

# ------------------------------------------------------------------------------
# rclone control
# ------------------------------------------------------------------------------

remote_root::ludusavi() {
  # USAGE: remote_root::ludusavi "$provider_id" "$folder" "$share(optional)"
  # Prints the path under the remote that holds the sidecar and ludusavi/ directory
  # An SMB remote's top level is its list of shares, so the share comes first

  local provider_id="$1"
  local folder="$2"
  local share="${3:-}"

  folder="${folder#/}"
  folder="${folder%/}"

  if [[ "$provider_id" == "smb" ]]; then
    share="${share#/}"
    share="${share%/}"
    echo "${share}/${folder}"
    return 0
  fi

  echo "$folder"
}

remote_create::ludusavi() {
  # USAGE: remote_create::ludusavi "$name" "$type" "$password" "$key=value..."
  # Creates a password-based remote, passing the password to rclone securely

  local name="$1"
  local type="$2"
  local password="$3"
  shift 3

  local -a options=("$@")

  if [[ -n "$password" ]]; then
    local obscured
    if ! obscured="$("$LUDUSAVI_RCLONE_BIN" obscure - <<< "$password" 2>/dev/null)" || [[ -z "$obscured" ]]; then
      log e "could not obscure the password for $name"
      return 1
    fi
    options+=("pass=$obscured")
  fi

  # --no-obscure: the password is already obscured by rclone, don't obscure it again
  if ! rclone_cfg::ludusavi config create "$name" "$type" "${options[@]}" --no-obscure > /dev/null 2>&1; then
    log e "rclone could not create remote $name ($type)"
    return 1
  fi

  return 0
}

remote_discard::ludusavi() {
  # USAGE: remote_discard::ludusavi "$name"
  # Deletes a remote

  local name="$1"

  if [[ -z "$name" ]]; then
    return 0
  fi

  rclone_cfg::ludusavi config delete "$name" > /dev/null 2>&1
  return 0
}
