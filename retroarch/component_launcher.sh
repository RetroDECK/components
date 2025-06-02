#!/bin/bash

COMPONENT_NAME="retroarch"
RD_MODULES="/app/retrodeck/components"

exec "$RD_MODULES/$COMPONENT_NAME/bin/retroarch" "$@"