#!/bin/bash

# RetroDECK API Connection Handler
# This script is executed by socat for each incoming client connection.

# Source the function libraries to load all function definitions
source /app/libexec/all_vars.sh
source /app/libexec/api_data_processing.sh
source /app/libexec/checks.sh
source /app/libexec/components.sh
source /app/libexec/framework.sh
source /app/libexec/logger.sh
source /app/libexec/other_functions.sh

# Read JSON request line from the client
if ! IFS= read -r -t "${api_timeout:-30}" request; then
  echo '{"status":"error","request_id":"unknown","message":"No request received or connection timed out"}'
  exit 1
fi

# Handle the request
api_handle_request "$request"
