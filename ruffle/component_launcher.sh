#!/bin/bash

COMPONENT_NAME="ruffle"
RD_MODULES="/app/retrodeck/components"

exec "$RD_MODULES/$COMPONENT_NAME/ruffle" "$@"