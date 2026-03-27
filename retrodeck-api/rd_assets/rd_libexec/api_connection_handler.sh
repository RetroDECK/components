#!/bin/bash

# RetroDECK API Connection Handler
# This script is executed by socat for each incoming client connection.

# Source the function libraries to load all function definitions
for file in /app/libexec/*.sh; do
  case "$(basename "$file")" in
    cleanup.sh|cli.sh|global.sh|launcher_functions.sh|run_game.sh|zenity_processing.sh) continue ;;
  esac
  log d "Sourcing $file for API session"
  source "$file"
done

# Read JSON request line from the client
if ! IFS= read -r -t "${api_timeout:-30}" request; then
  echo '{"status":"error","request_id":"unknown","message":"No request received or connection timed out"}'
  exit 1
fi

# Handle the request
api_handle_request "$request"
