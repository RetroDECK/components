#!/bin/bash

# Defaults for runtime desired versions
export DESIRED_QT6_RUNTIME_VERSION="6.10"
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"

# Defaults for component source desired versions
export AZAHAR_DESIRED_VERSION="2123.3"
export RUFFLE_DESIRED_VERSION="9555d8fc3d5e5b3c9e9ccea40492277fefb950368f2f2a40a16b69ad42ea3e33"
export VPINBALL_DESIRED_VERSION="10.8.1-3788-2151290"

# Framework component desired versions
if [[ "${GITHUB_REF_NAME:-}" != "main" ]]; then
    export FRAMEWORK_DESIRED_VERSION="cooker-latest on $(date +%Y-%m-%d)"
else
    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"
fi
