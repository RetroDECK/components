#!/bin/bash

source /app/libexec/logger.sh

component_name="retroarch"
component_path="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

log i "RetroDECK is now launching $component_name"

exec "$component_path/bin/retroarch" "$@"
