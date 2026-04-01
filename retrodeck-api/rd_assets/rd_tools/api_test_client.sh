#!/bin/bash

# RetroDECK API Test Client
# Interactive client for testing and validating the RetroDECK API server.
# Connects to the API server's Unix domain socket and provides two modes:
#   - Raw mode:    Send hand-crafted JSON requests
#   - Guided mode: Interactively build requests from available endpoints
#
# USAGE: retrodeck_api_test_client "$socket_path(optional)"

# ==============================
# Configuration
# ==============================

if [[ -n "$1" ]]; then
  API_SOCKET="$1"
elif [[ -n "$FLATPAK_ID" ]]; then
  API_SOCKET="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}/retrodeck-api.sock"
else
  # Host-side default: try to find the socket under the users runtime dir
  API_SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/app/net.retrodeck.retrodeck/retrodeck-api.sock"
fi

API_VERSION="1"
REQUEST_COUNTER=0

# ==============================
# Helper functions
# ==============================

print_header() {
  echo ""
  echo "=========================================="
  echo "  RetroDECK API Test Client"
  echo "=========================================="
  echo "  Socket: $API_SOCKET"
  echo "=========================================="
  echo ""
}

print_separator() {
  echo "------------------------------------------"
}

generate_request_id() {
  REQUEST_COUNTER=$((REQUEST_COUNTER + 1))
  echo "test_${$}_${REQUEST_COUNTER}"
}

check_dependencies() {
  local missing=0
  for cmd in socat jq; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
      echo "Error: Required command '$cmd' not found"
      missing=1
    fi
  done
  return "$missing"
}

check_socket() {
  if [[ ! -S "$API_SOCKET" ]]; then
    echo "Error: Socket not found at $API_SOCKET"
    echo "Is the API server running?"
    return 1
  fi
  return 0
}

# ==============================
# Communication
# ==============================

send_request() {
  # Sends a single-line JSON request to the API socket and outputs the response
  # USAGE: send_request "$json_line"

  local json_line="$1"

  if ! check_socket; then
    return 1
  fi

  local response
  response=$(echo "$json_line" | socat - UNIX-CONNECT:"$API_SOCKET" 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo "Error: No response received (connection may have timed out)"
    return 1
  fi

  echo "$response"
}

pretty_print_response() {
  # USAGE: pretty_print_response "$json_response"
  
  local response="$1"

  if jq empty <<< "$response" 2>/dev/null; then
    echo ""
    echo "Response:"
    print_separator
    jq '.' <<< "$response"
    print_separator
  else
    echo ""
    echo "Raw response (not valid JSON):"
    print_separator
    echo "$response"
    print_separator
  fi
}

# ==============================
# Raw mode
# ==============================

raw_mode() {
  echo ""
  echo "Raw Mode - Enter a single-line JSON request or 'back' to return to menu"
  echo "Example: {\"version\":\"1\",\"action\":\"check_status\",\"request_id\":\"test1\"}"
  echo ""

  while true; do
    echo -n "request> "
    local input
    read -r input

    if [[ "$input" == "back" || "$input" == "quit" || "$input" == "exit" ]]; then
      return
    fi

    if [[ -z "$input" ]]; then
      continue
    fi

    # Validate JSON before sending
    if ! jq empty <<< "$input" 2>/dev/null; then
      echo "Error: Invalid JSON. Please enter a valid single-line JSON object."
      continue
    fi

    # Compact the JSON to ensure single-line
    local compact
    compact=$(jq -c '.' <<< "$input")

    echo "Sending: $compact"
    local response
    response=$(send_request "$compact")
    pretty_print_response "$response"
    echo ""
  done
}

# ==============================
# Guided mode
# ==============================

guided_mode() {
  echo ""
  echo "Guided Mode - Fetching available endpoints from server..."
  echo ""

  # Query the server for available endpoints
  local list_request
  list_request=$(jq -c -n \
    --arg version "$API_VERSION" \
    --arg request_id "$(generate_request_id)" \
    '{version: $version, action: "list_endpoints", request_id: $request_id}')

  local list_response
  list_response=$(send_request "$list_request")

  if [[ -z "$list_response" ]]; then
    echo "Could not connect to server"
    return
  fi

  local status
  status=$(jq -r '.status' <<< "$list_response" 2>/dev/null)

  if [[ "$status" != "success" ]]; then
    echo "Error fetching endpoints:"
    pretty_print_response "$list_response"
    return
  fi

  local result
  result=$(jq '.result' <<< "$list_response")

  # Present endpoint selection menu
  while true; do
    echo ""
    echo "Available endpoints:"
    print_separator

    # List built-in actions
    echo ""
    echo "  Built-in actions:"
    local -a builtin_keys=()
    while IFS= read -r key; do
      builtin_keys+=("$key")
    done < <(jq -r '.built_in | keys[]' <<< "$result" 2>/dev/null)

    local index=1
    for key in "${builtin_keys[@]}"; do
      local desc
      desc=$(jq -r --arg key "$key" '.built_in[$key].description' <<< "$result")
      printf "    %2d) %-30s  %s\n" "$index" "$key" "$desc"
      index=$((index + 1))
    done

    # List manifest endpoints
    echo ""
    echo "  Manifest endpoints:"
    local -a endpoint_keys=()
    while IFS= read -r key; do
      endpoint_keys+=("$key")
    done < <(jq -r '.endpoints | keys[]' <<< "$result" 2>/dev/null)

    for key in "${endpoint_keys[@]}"; do
      local desc
      desc=$(jq -r --arg key "$key" '.endpoints[$key].description' <<< "$result")
      printf "    %2d) %-30s  %s\n" "$index" "$key" "$desc"
      index=$((index + 1))
    done

    echo ""
    echo "     0) Back to main menu"
    echo ""
    echo -n "Select endpoint: "
    local selection
    read -r selection

    if [[ "$selection" == "0" || "$selection" == "back" || "$selection" == "quit" ]]; then
      return
    fi

    # Validate selection is a number
    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
      echo "Invalid selection"
      continue
    fi

    local total_builtins=${#builtin_keys[@]}
    local total_endpoints=${#endpoint_keys[@]}
    local total=$((total_builtins + total_endpoints))

    if [[ "$selection" -lt 1 || "$selection" -gt "$total" ]]; then
      echo "Selection out of range"
      continue
    fi

    # Determine which endpoint was selected
    local selected_key=""
    local is_builtin=false
    local endpoint_meta=""

    if [[ "$selection" -le "$total_builtins" ]]; then
      selected_key="${builtin_keys[$((selection - 1))]}"
      is_builtin=true
      endpoint_meta=$(jq --arg key "$selected_key" '.built_in[$key]' <<< "$result")
    else
      local ep_index=$((selection - total_builtins - 1))
      selected_key="${endpoint_keys[$ep_index]}"
      is_builtin=false
      endpoint_meta=$(jq --arg key "$selected_key" '.endpoints[$key]' <<< "$result")
    fi

    echo ""
    print_separator
    echo "Selected: $selected_key"
    echo "Description: $(jq -r '.description' <<< "$endpoint_meta")"
    print_separator

    # Build the request
    local request_id
    request_id=$(generate_request_id)

    if [[ "$is_builtin" == true ]]; then
      # Built-in actions use the key directly as the action, no request or data needed
      local request_json
      request_json=$(jq -c -n \
        --arg version "$API_VERSION" \
        --arg action "$selected_key" \
        --arg request_id "$request_id" \
        '{version: $version, action: $action, request_id: $request_id}')

      echo ""
      echo "Request: $request_json"
      echo -n "Send? [Y/n]: "
      local confirm
      read -r confirm
      if [[ "$confirm" =~ ^[Nn] ]]; then
        continue
      fi

      local response
      response=$(send_request "$request_json")
      pretty_print_response "$response"
    else
      # Manifest endpoint: parse action::request from the key
      local action request
      action="${selected_key%%::*}"
      request="${selected_key#*::}"

      # Collect field values
      local data_json="{}"
      local has_fields=false

      # Required fields
      local -a req_fields=()
      while IFS= read -r field; do
        [[ -z "$field" ]] && continue
        req_fields+=("$field")
      done < <(jq -r '.required_fields // [] | .[]' <<< "$endpoint_meta")

      if [[ ${#req_fields[@]} -gt 0 ]]; then
        has_fields=true
        echo ""
        echo "Required fields:"
        for field in "${req_fields[@]}"; do
          echo -n "  $field: "
          local value
          read -r value
          data_json=$(jq -c --arg key "$field" --arg val "$value" '. + {($key): $val}' <<< "$data_json")
        done
      fi

      # Optional fields
      local -a opt_fields=()
      while IFS= read -r field; do
        [[ -z "$field" ]] && continue
        opt_fields+=("$field")
      done < <(jq -r '.optional_fields // [] | .[]' <<< "$endpoint_meta")

      if [[ ${#opt_fields[@]} -gt 0 ]]; then
        has_fields=true
        echo ""
        echo "Optional fields (press Enter to skip):"
        for field in "${opt_fields[@]}"; do
          echo -n "  $field: "
          local value
          read -r value
          if [[ -n "$value" ]]; then
            data_json=$(jq -c --arg key "$field" --arg val "$value" '. + {($key): $val}' <<< "$data_json")
          fi
        done
      fi

      # Build request JSON
      local request_json
      if [[ "$has_fields" == true ]]; then
        request_json=$(jq -c -n \
          --arg version "$API_VERSION" \
          --arg action "$action" \
          --arg request "$request" \
          --arg request_id "$request_id" \
          --argjson data "$data_json" \
          '{version: $version, action: $action, request: $request, request_id: $request_id, data: $data}')
      else
        request_json=$(jq -c -n \
          --arg version "$API_VERSION" \
          --arg action "$action" \
          --arg request "$request" \
          --arg request_id "$request_id" \
          '{version: $version, action: $action, request: $request, request_id: $request_id}')
      fi

      echo ""
      echo "Request:"
      jq '.' <<< "$request_json"
      echo ""
      echo -n "Send? [Y/n]: "
      local confirm
      read -r confirm
      if [[ "$confirm" =~ ^[Nn] ]]; then
        continue
      fi

      # Send as compact single-line JSON
      local compact_request
      compact_request=$(jq -c '.' <<< "$request_json")
      local response
      response=$(send_request "$compact_request")
      pretty_print_response "$response"
    fi
  done
}

# ==============================
# Quick test
# ==============================

quick_test() {
  # Run a basic connectivity test
  echo ""
  echo "Running quick connectivity test..."
  print_separator

  # Test 1: check_status
  echo -n "  check_status: "
  local request
  request=$(jq -c -n \
    --arg version "$API_VERSION" \
    --arg request_id "$(generate_request_id)" \
    '{version: $version, action: "check_status", request_id: $request_id}')

  local response
  response=$(send_request "$request")
  local status
  status=$(jq -r '.status' <<< "$response" 2>/dev/null)

  if [[ "$status" == "success" ]]; then
    echo "PASS"
  else
    echo "FAIL"
    echo "  Response: $response"
  fi

  # Test 2: list_endpoints
  echo -n "  list_endpoints: "
  request=$(jq -c -n \
    --arg version "$API_VERSION" \
    --arg request_id "$(generate_request_id)" \
    '{version: $version, action: "list_endpoints", request_id: $request_id}')

  response=$(send_request "$request")
  status=$(jq -r '.status' <<< "$response" 2>/dev/null)
  local endpoint_count
  endpoint_count=$(jq '.result.endpoints | length' <<< "$response" 2>/dev/null)

  if [[ "$status" == "success" ]]; then
    echo "PASS ($endpoint_count endpoints registered)"
  else
    echo "FAIL"
    echo "  Response: $response"
  fi

  # Test 3: Invalid request (no request_id)
  echo -n "  missing request_id: "
  response=$(send_request '{"version":"1","action":"check_status"}')
  local message
  message=$(jq -r '.message' <<< "$response" 2>/dev/null)

  if [[ "$message" == *"request_id"* ]]; then
    echo "PASS (correctly rejected)"
  else
    echo "FAIL"
    echo "  Response: $response"
  fi

  # Test 4: Unknown endpoint
  echo -n "  unknown endpoint: "
  request=$(jq -c -n \
    --arg version "$API_VERSION" \
    --arg request_id "$(generate_request_id)" \
    '{version: $version, action: "get", request: "nonexistent_thing", request_id: $request_id}')

  response=$(send_request "$request")
  status=$(jq -r '.status' <<< "$response" 2>/dev/null)

  if [[ "$status" == "error" ]]; then
    echo "PASS (correctly rejected)"
  else
    echo "FAIL"
    echo "  Response: $response"
  fi

  # Test 5: Invalid JSON
  echo -n "  invalid JSON: "
  response=$(send_request 'this is not json')
  status=$(jq -r '.status' <<< "$response" 2>/dev/null)

  if [[ "$status" == "error" ]]; then
    echo "PASS (correctly rejected)"
  else
    echo "FAIL"
    echo "  Response: $response"
  fi

  print_separator
  echo "Quick test complete"
  echo ""
}

# ==============================
# Main menu
# ==============================

main_menu() {
  print_header

  if ! check_dependencies; then
    exit 1
  fi

  if ! check_socket; then
    echo ""
    echo "You can specify a custom socket path as the first argument:"
    echo "  $0 /path/to/retrodeck-api.sock"
    echo ""
    exit 1
  fi

  while true; do
    echo "Main Menu:"
    echo "  1) Raw mode      - Send hand-crafted JSON requests"
    echo "  2) Guided mode   - Build requests interactively"
    echo "  3) Quick test    - Run basic connectivity tests"
    echo "  4) Change socket - Connect to a different socket"
    echo "  0) Quit"
    echo ""
    echo -n "Select: "
    local choice
    read -r choice

    case "$choice" in
      1) raw_mode ;;
      2) guided_mode ;;
      3) quick_test ;;
      4)
        echo -n "New socket path: "
        read -r API_SOCKET
        if check_socket; then
          echo "Connected to $API_SOCKET"
        fi
        ;;
      0|quit|exit) echo "Goodbye."; exit 0 ;;
      *) echo "Invalid selection" ;;
    esac
    echo ""
  done
}

main_menu
