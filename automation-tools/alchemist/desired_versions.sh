#!/bin/bash

# ------------------------------------------------------------------
#  Default Global Runtime Versions
#  ----------------
#  These define which Qt libraries the framework will link against.
# ------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Qt 5 Runtime — Legacy Qt Support
# ------------------------------------------------------------------------------

# MAIN (Stable)
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"



# ==============================================================================
#  Component Desired Versions
# ==============================================================================
#  VERSION SELECTION RULE:
#  - MAIN    : Stable releases
#  - COOKER  : Cooker / development builds
#  - Only ONE export per component must be active
#
#  VERSION MEANINGS
#  ----------------
#  Each variable defines which upstream version the build system will fetch
#  for a given component:
#
#    "latest"   → Newest official stable release
#    "preview"  → Pre-release / preview builds
#    "local"    → Build from the local repository checkout
#    "newest"   → Newest available build, including beta or pre-release
#    "<serial/number>" → Pin to a specific version
# ==============================================================================


# ------------------------------------------------------------------------------
# Azahar — Nintendo 3DS Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export AZAHAR_DESIRED_VERSION="2123.2"

# COOKER (Override)
export AZAHAR_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Cemu — Wii U Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export CEMU_DESIRED_VERSION="2.6"

# COOKER (Override)
export CEMU_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Dolphin — GameCube / Wii Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export DOLPHIN_DESIRED_VERSION="2512"

# COOKER (Override)
export DOLPHIN_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# GZDoom — Modern Doom Engine
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export GZDOOM_DESIRED_VERSION="latest"

# COOKER (Override)
export GZDOOM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# MAME — Multiple Arcade Machine Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MAME_DESIRED_VERSION="0.283"

# COOKER (Override)
export MAME_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# MelonDS — Nintendo DS Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MELONDS_DESIRED_VERSION="1.1"

# COOKER (Override)
export MELONDS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# OpenBOR — Open Beat 'em Up Engine
# Source: AppImage
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export OPENBOR_DESIRED_VERSION="v7533"

# COOKER (Override)
export OPENBOR_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PCSX2 — PlayStation 2 Emulator
# Source: AppImage
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export PCSX2_DESIRED_VERSION="v2.5.404"

# COOKER (Override)
export PCSX2_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PPSSPP — PlayStation Portable Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export PPSSPP_DESIRED_VERSION="1.19.3"

# COOKER (Override)
export PPSSPP_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PrimeHack — Metroid Prime Fork of Dolphin
# Source: AppImage
# Note: Locked versions from fork
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export PRIMEHACK_DESIRED_VERSION="master-230724.27"

# COOKER (Override)
export PRIMEHACK_DESIRED_VERSION="master-230724.27"


# ------------------------------------------------------------------------------
# RetroArch — Multi-System Front-End
# Source: AppImage
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RETROARCH_DESIRED_VERSION="1.22.2"

# COOKER (Override)
export RETROARCH_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# RPCS3 — PlayStation 3 Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RPCS3_DESIRED_VERSION="0.0.38-1-77aa5d4b"

# COOKER (Override)
export RPCS3_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ruffle — Flash Player Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RUFFLE_DESIRED_VERSION="0.2.0-nightly.2025.12.26"

# COOKER (Override)
export RUFFLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ryubing — Nintendo Switch Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RYUBING_DESIRED_VERSION="1.3.2"

# COOKER (Override)
export RYUBING_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Solarus — Action RPG Engine
# Source: AppImage
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SOLARUS_DESIRED_VERSION="v2.0.2"

# COOKER (Override)
export SOLARUS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Steam ROM Manager — Steam Artwork & ROM Importer
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export STEAM_ROM_MANAGER_DESIRED_VERSION="2.5.33"

# COOKER (Override)
export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Xemu — Original Xbox Emulator
# Source: Flatpak
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export XEMU_DESIRED_VERSION="0.8.124"

# COOKER (Override)
export XEMU_DESIRED_VERSION="latest"


# ==============================================================================
#  Component Desired Versions — Self-Built / Repo-Hosted Components
# ==============================================================================
#  Self-Built components
#
#  VERSION SELECTION RULE:
#  - MAIN    : Stable releases
#  - COOKER  : Cooker / development builds
#  - Only ONE export per component must be active
#
#  VERSION MEANINGS
#  ----------------
#  Each variable defines which upstream version the build system will fetch
#  for a given component:
#
#    "latest"   → Newest official stable release
#    "preview"  → Pre-release / preview builds
#    "local"    → Build from the local repository checkout
#    "newest"   → Newest available build, including beta or pre-release
#    "<serial/number>" → Pin to a specific version
# ==============================================================================




# ------------------------------------------------------------------------------
# DuckStation (Legacy) — PlayStation 1 Emulator
# Source: AppImage (RetroDECK-built legacy archive)
# Repo: https://github.com/RetroDECK/Duckstation
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export DUCKSTATION_DESIRED_VERSION="preview"

# COOKER (Override)
export DUCKSTATION_DESIRED_VERSION="preview"


# ------------------------------------------------------------------------------
# ES-DE — EmulationStation Desktop Edition
# Source: AppImage (RetroDECK-built)
# Repo: https://github.com/RetroDECK/ES-DE
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export ES_DE_DESIRED_VERSION="latest"

# COOKER (Override)
export ES_DE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Flips — IPS Patch Utility
# Source: Binary (RetroDECK-built)
# Repo: https://github.com/RetroDECK/components/tree/cooker/flips/assets
# ------------------------------------------------------------------------------
# MAIN (Stable)
export FLIPS_DESIRED_VERSION="v198"

# COOKER (Override)
# export FLIPS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PortMaster — Multi-System Game Launcher
# Source: Binary (RetroDECK-built)
# Repo: https://github.com/RetroDECK/components/tree/cooker/portmaster/assets
# ------------------------------------------------------------------------------
# MAIN (Stable)
export PORTMASTER_DESIRED_VERSION="latest"

# COOKER (Override)
# export PORTMASTER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# XRoar — Tano Dragon Emulator
# Source: Binary (RetroDECK-built)
# Repo: https://github.com/RetroDECK/XRoar
# ------------------------------------------------------------------------------
# MAIN (Stable)
export XROAR_DESIRED_VERSION="latest"

# COOKER (Override)
# export XROAR_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Vita3K — PlayStation Vita Emulator
# Source: AppImage (RetroDECK-mirrored)
# Repo: https://github.com/RetroDECK/Vita3K-bin
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export VITA3K_DESIRED_VERSION="3847"

# COOKER (Override)
export VITA3K_DESIRED_VERSION="latest"




# ==============================================================================
#  Component Desired Versions — Future
# ==============================================================================
#  New components in Cooker for a future Major Release
#
#  VERSION SELECTION RULE:
#  - MAIN    : Stable releases
#  - COOKER  : Cooker / development builds
#  - Only ONE export per component must be active
#
#  VERSION MEANINGS
#  ----------------
#  Each variable defines which upstream version the build system will fetch
#  for a given component:
#
#    "latest"   → Newest official stable release
#    "preview"  → Pre-release / preview builds
#    "local"    → Build from the local repository checkout
#    "newest"   → Newest available build, including beta or pre-release
#    "<serial/number>" → Pin to a specific version
# ==============================================================================


# ------------------------------------------------------------------------------
# DOSBox-X — Enhanced DOSBox Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export DOSBOX_X_DESIRED_VERSION=""

# COOKER (Override)
export DOSBOX_X_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Eden — Nintendo Switch Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EDEN_DESIRED_VERSION=""

# COOKER (Override)
export EDEN_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# EKA2L1 — Symbian OS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EKA2L1_DESIRED_VERSION=""

# COOKER (Override)
export EKA2L1_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Flycast — Dreamcast Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export FLYCAST_DESIRED_VERSION=""

# COOKER (Override)
export FLYCAST_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Gargoyle — Interactive Fiction Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export GARGOYLE_DESIRED_VERSION=""

# COOKER (Override)
export GARGOYLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Hypseus — Laser Disc Arcade Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export HYPSEUS_DESIRED_VERSION=""

# COOKER (Override)
export HYPSEUS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ikeman Go — Fighting Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export IKEMANGO_DESIRED_VERSION=""

# COOKER (Override)
export IKEMANGO_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# KEGS — Apple IIGS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export KEGS_DESIRED_VERSION="1.38"

# COOKER (Override)
export KEGS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Lindbergh — SEGA Lindbergh Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export LINDBERGH_DESIRED_VERSION=""

# COOKER (Override)
export LINDBERGH_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Mudlet — MUD Client
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MUDLET_DESIRED_VERSION="4.19.1"

# COOKER (Override)
export MUDLET_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Raze — Duke Nukem Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RAZE_DESIRED_VERSION=""

# COOKER (Override)
export RAZE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ScummVM — Point-and-Click Adventure Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SCUMMVM_DESIRED_VERSION=""

# COOKER (Override)
export SCUMMVM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ShadPS4 — PlayStation 4 Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SHADPS4_DESIRED_VERSION=""

# COOKER (Override)
export SHADPS4_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SimCoupe — SAM Coupé Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SIMCOUPE_DESIRED_VERSION=""

# COOKER (Override)
export SIMCOUPE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SuperModel — SEGA Model 3 Arcade Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SUPERMODEL_DESIRED_VERSION=""

# COOKER (Override)
export SUPERMODEL_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# UZDoom — Modern Doom Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export UZDOOM_DESIRED_VERSION=""

# COOKER (Override)
export UZDOOM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# VPinball — Virtual Pinball Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export VPINBALL_DESIRED_VERSION=""

# COOKER (Override)
export VPINBALL_DESIRED_VERSION="newest"


# ------------------------------------------------------------------------------
# Xenia — Xbox 360 Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export XENIA_DESIRED_VERSION=""

# COOKER (Override)
export XENIA_DESIRED_VERSION="newest"




# ------------------------------------------------------------------
#  Framework Component Desired Version
#  -----------------------------------
#  Determines which framework branch to pull based on the Git ref.
# ------------------------------------------------------------------

if [[ "${GITHUB_REF_NAME:-}" != "main" ]]; then
    # Non‑main branches use the “cooker‑latest” build tag
    export FRAMEWORK_DESIRED_VERSION="cooker-latest on $(date +%Y-%m-%d)"
else
    # Main branch uses the “main‑latest” build tag
    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"
fi
