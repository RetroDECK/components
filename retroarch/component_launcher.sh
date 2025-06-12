#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="retroarch"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $COMPONENT_NAME"

exec "$COMPONENT_FOLDER/bin/retroarch" "$@"
