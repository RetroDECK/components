#!/bin/bash

source /app/libexec/logger.sh

COMPONENT_NAME="vita3k"
COMPONENT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

LD_LIBRARY_PATH="$COMPONENT_FOLDER/lib:${LD_LIBRARY_PATH}"
PATH="$COMPONENT_FOLDER/bin:$PATH"

log i "RetroDECK is now launching $COMPONENT_NAME"
log d "Library path is: $LD_LIBRARY_PATH"

exec "$COMPONENT_FOLDER/bin/Vita3K" "$@"
