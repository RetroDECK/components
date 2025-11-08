#!/bin/bash

# Defaults for runtime desired versions
export DESIRED_QT6_RUNTIME_VERSION="6.10"
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"

# Defaults for component source desired versions
export AZAHAR_DESIRED_VERSION="latest"
export CEMU_DESIRED_VERSION="latest"
export DOLPHIN_DESIRED_VERSION="latest"
export DOSBOX_X_DESIRED_VERSION="latest"
export DUCKSTATION_DESIRED_VERSION="preview"
export EDEN_DESIRED_VERSION="latest"
export EKA2L1_DESIRED_VERSION="latest"
export ES_DE_DESIRED_VERSION="latest"
export FLIPS_DESIRED_VERSION="local"
export FLYCAST_DESIRED_VERSION="latest"
export GARGOYLE_DESIRED_VERSION="latest"
export GZDOOM_DESIRED_VERSION="latest"
export HYPSEUS_DESIRED_VERSION="latest"
export KEGS_DESIRED_VERSION="1.38"
export LINDBURGH_DESIRED_VERSION="latest"
export MAME_DESIRED_VERSION="latest"
export MELONDS_DESIRED_VERSION="latest"
export MUDLET_DESIRED_VERSION="4.19.1"
export OPENBOR_DESIRED_VERSION="latest"
export PCSX2_DESIRED_VERSION="latest"
export PPSSPP_DESIRED_VERSION="latest"
export PRIMEHACK_DESIRED_VERSION="latest"
export RAZE_DESIRED_VERSION="latest"
export RETROARCH_DESIRED_VERSION="latest"
export RPCS3_DESIRED_VERSION="latest"
export RUFFLE_DESIRED_VERSION="latest"
export RYUBING_DESIRED_VERSION="latest"
export SCUMMVM_DESIRED_VERSION="latest"
export SHADPS4_DESIRED_VERSION="latest"
export SIMCOUPE_DESIRED_VERSION="latest"
export SOLARUS_DESIRED_VERSION="2.0.1"
export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"
export SUPERMODEL_DESIRED_VERSION="latest"
export VITA3K_DESIRED_VERSION="latest"
export VPINBALL_DESIRED_VERSION="newest"
export XEMU_DESIRED_VERSION="latest"
export XENIA_DESIRED_VERSION="newest"
export XROAR_DESIRED_VERSION="latest"

# Framework component desired versions
if [[ "${GITHUB_REF_NAME:-}" != "main" ]]; then
    export FRAMEWORK_DESIRED_VERSION="cooker-latest on $(date +%Y-%m-%d)"
else
    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"
fi
