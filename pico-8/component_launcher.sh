#!/bin/bash

source /app/libexec/launcher_functions.sh

exec "$bios_path/pico-8/pico8" -desktop_path "$screenshots_path" "$@"
