#!/bin/bash

# Socket location (Flatpak): $XDG_RUNTIME_DIR/app/$FLATPAK_ID/retrodeck-api.sock
# Socket location (host):    /run/user/<UID>/app/net.retrodeck.retrodeck/retrodeck-api.sock

if [[ -n "$FLATPAK_ID" ]]; then
  export api_socket_path="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}/retrodeck-api.sock"
  export api_pid_file="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}/retrodeck-api.pid"
else
  # Fallback for use outside Flatpak
  export api_socket_path="/tmp/retrodeck-api.sock"
  export api_pid_file="/tmp/retrodeck-api.pid"
fi

export api_timeout=30
export api_version_current="1"

local component_path="$(get_component_path "retrodeck-api")"
export api_connection_handler_path="${component_path}/libexec/api_connection_handler.sh"

retrodeck_api() {
  case "$1" in
    start)  api_start_server ;;
    stop)   api_stop_server ;;
    status) api_status_server ;;
    *)
      echo "Usage: retrodeck_api {start|stop|status}"
      return 1
      ;;
  esac
}

api_start_server() {
  if [[ -f "$api_pid_file" ]] && kill -0 "$(cat "$api_pid_file")" 2>/dev/null; then
    log d "API server is already running (PID: $(cat "$api_pid_file"))"
    return 1
  fi

  local socket_dir
  socket_dir=$(dirname "$api_socket_path")
  mkdir -p "$socket_dir"

  # Clean up stale socket from previous unclean shutdown
  rm -f "$api_socket_path"

  # Verify connection handler script exists
  if [[ ! -f "$api_connection_handler_path" ]]; then
    log e "API connection handler not found at: $api_connection_handler_path"
    return 1
  fi

  # Check for duplicate endpoints across manifests
  api_check_duplicate_endpoints

  api_run_server &
  local server_pid=$!
  echo "$server_pid" > "$api_pid_file"
  log d "API server started (PID: $server_pid) on socket: $api_socket_path"
}

api_stop_server() {
  if [[ -f "$api_pid_file" ]]; then
    local pid
    pid=$(cat "$api_pid_file")
    if kill "$pid" 2>/dev/null; then
      log d "Stopping API server (PID: $pid)..."
      # Kill any child handler processes in the same process group
      kill -- -"$pid" 2>/dev/null
      rm -f "$api_pid_file" "$api_socket_path"
      return 0
    else
      log d "API server not running; cleaning up residual files"
      rm -f "$api_pid_file" "$api_socket_path"
      return 1
    fi
  else
    log d "No running API server found"
    return 1
  fi
}

api_status_server() {
  if [[ -f "$api_pid_file" ]] && kill -0 "$(cat "$api_pid_file")" 2>/dev/null; then
    log d "API server is running (PID: $(cat "$api_pid_file"))"
    return 0
  else
    log d "API server is not running"
    return 1
  fi
}

api_run_server() {
  log d "API server running (PID: $$), socket: $api_socket_path"

  trap 'log d "API server shutting down..."; rm -f "$api_pid_file" "$api_socket_path"; exit 0' EXIT INT TERM
  
  socat UNIX-LISTEN:"${api_socket_path}",fork,reuseaddr,mode=660 \
    EXEC:"stdbuf -oL bash ${api_connection_handler_path}",nofork 2>/dev/null

  # If socat exits unexpectedly, clean up
  log d "socat exited unexpectedly, cleaning up"
  rm -f "$api_pid_file" "$api_socket_path"
}

api_handle_request() {
  # USAGE: api_handle_request "$json_request_line"

  local json_input="$1"

  # Validate JSON format
  if ! jq empty <<< "$json_input" 2>/dev/null; then
    api_build_response "error" "unknown" "" "Invalid JSON format"
    return
  fi

  # Extract protocol-level fields
  local action request_id api_version request request_data
  action=$(jq -r '.action // empty' <<< "$json_input")
  request_id=$(jq -r '.request_id // empty' <<< "$json_input")
  api_version=$(jq -r '.version // empty' <<< "$json_input")
  request=$(jq -r '.request // empty' <<< "$json_input")
  request_data=$(jq -r '.data // empty' <<< "$json_input")

  # Validate required protocol fields
  if [[ -z "$request_id" ]]; then
    api_build_response "error" "unknown" "" "Missing required field: request_id"
    return
  fi

  if [[ -z "$api_version" ]]; then
    api_build_response "error" "$request_id" "" "Missing required field: version"
    return
  fi

  if [[ -z "$action" ]]; then
    api_build_response "error" "$request_id" "" "Missing required field: action"
    return
  fi

  # Handle built-in server actions
  case "$action" in
    "check_status")
      api_build_response "success" "$request_id" '"ok"' ""
      return
      ;;
    "list_endpoints")
      local endpoints
      endpoints=$(api_builtin_list_endpoints)
      api_build_response "success" "$request_id" "$endpoints" ""
      return
      ;;
  esac

  if [[ -z "$request" ]]; then
    api_build_response "error" "$request_id" "" "Missing required field: request"
    return
  fi

  api_dispatch_request "$action" "$request" "$request_data" "$request_id"
}

api_dispatch_request() {
  # USAGE: api_dispatch_request "$action" "$request" "$request_data" "$request_id"

  local action="$1"
  local request="$2"
  local request_data="$3"
  local request_id="$4"

  local endpoint_key="${action}::${request}"

  # Look up endpoint definition across all component manifests
  local endpoint_def
  endpoint_def=$(jq -r --arg key "$endpoint_key" '
    [.[] | .manifest.api_endpoints // {} | .[$key] // empty]
    | if length > 0 then first else empty end
  ' "$component_manifest_cache_file" 2>/dev/null)

  if [[ -z "$endpoint_def" ]]; then
    api_build_response "error" "$request_id" "" "Unknown endpoint: $endpoint_key"
    return
  fi

  # Extract endpoint metadata
  local target_function
  target_function=$(jq -r '.function' <<< "$endpoint_def")

  # Verify target function exists
  if ! declare -f "$target_function" > /dev/null 2>&1; then
    api_build_response "error" "$request_id" "" "Endpoint function not found: $target_function"
    return
  fi

  # Parse request data as JSON object
  local data_json
  if [[ -n "$request_data" && "$request_data" != "null" ]]; then
    if ! jq empty <<< "$request_data" 2>/dev/null; then
      api_build_response "error" "$request_id" "" "Invalid JSON in data field"
      return
    fi
    data_json="$request_data"
  else
    data_json="{}"
  fi

  # Validate required fields are present in data
  local missing_fields
  missing_fields=$(jq -r --argjson data "$data_json" '
    [.required_fields // [] | .[] | select(. as $f | $data | has($f) | not)]
    | if length > 0 then join(", ") else empty end
  ' <<< "$endpoint_def")

  if [[ -n "$missing_fields" ]]; then
    api_build_response "error" "$request_id" "" "Missing required data fields: $missing_fields"
    return
  fi

  local -a func_args=()

  # Extract required field values in declared order
  # Complex types (arrays, objects) are passed as JSON strings for the backend function to parse
  while IFS= read -r field_name; do
    [[ -z "$field_name" ]] && continue
    local field_value
    field_value=$(jq -r --arg f "$field_name" \
      '.[$f] | if type == "array" or type == "object" then tojson else . end' \
      <<< "$data_json")
    func_args+=("$field_value")
  done < <(jq -r '.required_fields // [] | .[]' <<< "$endpoint_def")

  # Extract optional field values in declared order (empty string if absent)
  while IFS= read -r field_name; do
    [[ -z "$field_name" ]] && continue
    local field_value
    field_value=$(jq -r --arg f "$field_name" \
      'if has($f) then .[$f] | if type == "array" or type == "object" then tojson else . end else empty end' \
      <<< "$data_json")
    func_args+=("$field_value")
  done < <(jq -r '.optional_fields // [] | .[]' <<< "$endpoint_def")

  # Set request_id for progress reporting
  _api_request_id="$request_id"

  # Set up fd for streaming progress
  exec 3>&1

  local result
  if result=$("$target_function" "${func_args[@]}"); then
    if jq empty <<< "$result" 2>/dev/null; then
      api_build_response "success" "$request_id" "$result" ""
    else
      local json_result
      json_result=$(jq -c -n --arg r "$result" '$r')
      api_build_response "success" "$request_id" "$json_result" ""
    fi
  else
    local error_msg="$result"
    if [[ -z "$error_msg" ]]; then
      error_msg="Endpoint function returned an error"
    fi
    api_build_response "error" "$request_id" "" "$error_msg"
  fi

  exec 3>&-
}

api_send_progress() {
  # USAGE: api_send_progress "$current" "$total" "$message"

  local current="$1"
  local total="$2"
  local message="$3"

  jq -c -n \
    --arg status "progress" \
    --arg request_id "$_api_request_id" \
    --argjson current "$current" \
    --argjson total "$total" \
    --arg message "$message" \
    '{status: $status, request_id: $request_id, progress: {current: $current, total: $total, message: $message}}' >&3
}

api_build_response() {
  # USAGE: api_build_response "$status" "$request_id" "[$result_json]" "[$error_message]"

  local status="$1"
  local request_id="$2"
  local result_json="$3"
  local error_message="$4"

  if [[ "$status" == "success" ]]; then
    jq -c -n \
      --arg status "$status" \
      --arg request_id "$request_id" \
      --argjson result "${result_json:-null}" \
      '{status: $status, request_id: $request_id, result: $result}'
  else
    jq -c -n \
      --arg status "$status" \
      --arg request_id "$request_id" \
      --arg message "$error_message" \
      '{status: $status, request_id: $request_id, message: $message}'
  fi
}

api_builtin_list_endpoints() {
  # USAGE: api_builtin_list_endpoints

  jq -c '{
    "built_in": {
      "check_status": {
        "description": "Check if the API server is running",
        "required_fields": [],
        "optional_fields": []
      },
      "list_endpoints": {
        "description": "List all available API endpoints",
        "required_fields": [],
        "optional_fields": []
      }
    },
    "endpoints": (
      [.[] | .manifest.api_endpoints // {} | to_entries[]]
      | group_by(.key)
      | map({
          key: first.key,
          value: (first.value + (if length > 1 then {"note": "duplicate endpoint across components, framework definition takes priority"} else {} end))
        })
      | from_entries
    )
  }' "$component_manifest_cache_file" 2>/dev/null || echo '{"built_in":{},"endpoints":{}}'
}

api_check_duplicate_endpoints() {
  # USAGE: api_check_duplicate_endpoints

  local duplicates
  duplicates=$(jq -r '
    [.[] | .manifest.component_name as $comp | (.manifest.api_endpoints // {} | keys[]) as $ep | {component: $comp, endpoint: $ep}]
    | group_by(.endpoint)
    | map(select(length > 1))
    | .[]
    | "Duplicate API endpoint \"" + (first.endpoint) + "\" found in components: " + ([.[].component] | join(", ")) + ". Framework definition takes priority."
  ' "$component_manifest_cache_file" 2>/dev/null)

  if [[ -n "$duplicates" ]]; then
    while IFS= read -r warning; do
      log w "$warning"
    done <<< "$duplicates"
  fi
}
