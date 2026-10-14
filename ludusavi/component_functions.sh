#!/bin/bash

# Component paths
export LUDUSAVI_CONFIG_DIR="$XDG_CONFIG_HOME/ludusavi"
export LUDUSAVI_CONFIG_FILE="$LUDUSAVI_CONFIG_DIR/config.yaml"
export LUDUSAVI_RCLONE_CONFIG_FILE="$XDG_CONFIG_HOME/ludusavi/rclone.conf"
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
