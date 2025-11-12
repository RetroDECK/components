#!/bin/bash

# ------------------------------------------------------------------
#  Default Global Runtime Versions
#  ----------------
#  These define which Qt libraries the framework will link against.
# ------------------------------------------------------------------

# Qt 6 runtime
export DESIRED_QT6_RUNTIME_VERSION="6.10"

# Qt 5 runtime (legacy)
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"


# ------------------------------------------------------------------
#  Component Source Desired Versions
#  --------------------------------
#  Each variable tells the build system which upstream version of a
#  particular emulator / tool to fetch.  “latest” pulls the newest
#  release, “preview” follows pre‑release builds, “local” builds from
#  the repository checkout, and explicit numbers pin a specific tag.
# ------------------------------------------------------------------

# ------------------------------------------------------------------
#  Component Specific Runtime Versions
#  --------------------------------
#  These define which Qt libraries the framework will link against.
#  If the globals above can't be used.
# ------------------------------------------------------------------

# Azhar – N3DS emulator
export AZAHAR_DESIRED_VERSION="latest"
export AZAHAR_DESIRED_QT6_RUNTIME_VERSION="6.9"

# Cemu – Wii U emulator
export CEMU_DESIRED_VERSION="latest"

# Dolphin – GameCube/Wii emulator
export DOLPHIN_DESIRED_VERSION="latest"

# DOSBox‑X – Enhanced DOSBox
export DOSBOX_X_DESIRED_VERSION="latest"

# DuckStation (Legacy) – PlayStation 1 emulator 
export DUCKSTATION_DESIRED_VERSION="preview"

# Eden – Nintendo Switch emulator
export EDEN_DESIRED_VERSION="latest"

# EKA2L1 – Symbian OS emulator
export EKA2L1_DESIRED_VERSION="latest"

# ES‑DE – ES‑DE front‑end
export ES_DE_DESIRED_VERSION="latest"

# Flips – IPS Patcher
export FLIPS_DESIRED_VERSION="local"

# Flycast – Dreamcast emulator
export FLYCAST_DESIRED_VERSION="latest"

# Gargoyle – Interactive fictionS front‑end
export GARGOYLE_DESIRED_VERSION="latest"

# GZDoom – Modern Doom engine
export GZDOOM_DESIRED_VERSION="latest"

# Hypseus – Laser Disc Arcade emulator
export HYPSEUS_DESIRED_VERSION="latest"

# KEGS – Apple IIgs emulator
export KEGS_DESIRED_VERSION="1.38"

# Lindbergh – SEGA lindbergh emulator
export LINDBERGH_DESIRED_VERSION="latest"

# MAME – Multiple Arcade Machine Emulator
export MAME_DESIRED_VERSION="latest"

# MelonDS – Nintendo DS emulator
export MELONDS_DESIRED_VERSION="latest"

# Mudlet – MUD client
export MUDLET_DESIRED_VERSION="4.19.1"

# OpenBOR – Open Beat 'em up engine
export OPENBOR_DESIRED_VERSION="latest"

# PCSX2 – PlayStation 2 emulator
export PCSX2_DESIRED_VERSION="latest"

# PortMaster – Multi‑system game launcher and manager
export PORTMASTER_DESIRED_VERSION="latest"

# PPSSPP – PSP emulator
export PPSSPP_DESIRED_VERSION="latest"

# PrimeHack – Metroid Prime mod for Dolphin
export PRIMEHACK_DESIRED_VERSION="latest"

# Raze – Duke Nukem GZDoom based engine
export RAZE_DESIRED_VERSION="latest"

# RetroArch – Multi‑system front‑end
export RETROARCH_DESIRED_VERSION="latest"
export RETROARCH_DESIRED_QT6_RUNTIME_VERSION="6.8"

# RPCS3 – PlayStation 3 emulator
export RPCS3_DESIRED_VERSION="latest"

# Ruffle – Flash Player emulator
export RUFFLE_DESIRED_VERSION="latest"

# Ryujinx – Nintendo Switch emulator
export RYUBING_DESIRED_VERSION="latest"

# ScummVM – Classic point‑and‑click adventure engine
export SCUMMVM_DESIRED_VERSION="latest"

# ShadPS4 – PlayStation 4 emulator 
export SHADPS4_DESIRED_VERSION="latest"

# SimCoupe – SAM Coupé emulator
export SIMCOUPE_DESIRED_VERSION="latest"

# Solarus – Action‑RPG engine 
export SOLARUS_DESIRED_VERSION="2.0.1"

# Steam ROM Manager – Organises ROM collections for Steam
export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"

# SuperModel – SEGA Model 3 arcade emulator
export SUPERMODEL_DESIRED_VERSION="latest"

# Vita3K – PlayStation Vita emulator
export VITA3K_DESIRED_VERSION="latest"

# VPinball – Virtual pinball platform
export VPINBALL_DESIRED_VERSION="newest"

# Xemu – Original Xbox emulator
export XEMU_DESIRED_VERSION="latest"

# Xenia – Xbox 360 emulator (newest build)
export XENIA_DESIRED_VERSION="newest"

# XRoar – Tano Dragon emulator
export XROAR_DESIRED_VERSION="latest"


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