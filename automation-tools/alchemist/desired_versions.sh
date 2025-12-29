#!/bin/bash

# ------------------------------------------------------------------
#  Default Global Runtime Versions
#  ----------------
#  These define which Qt libraries the framework will link against.
# ------------------------------------------------------------------

# Qt 5 runtime (legacy)
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"



# ------------------------------------------------------------------
#  Component Specific Runtime Versions
#  --------------------------------
#  These define which Qt libraries the framework will link against.
#  If the globals above can't be used.
# ------------------------------------------------------------------



# ------------------------------------------------------------------
#  Component Source Desired Versions
#  --------------------------------
#  Each variable tells the build system which upstream version of a
#  particular emulator / tool to fetch.  “latest” pulls the newest
#  release, “preview” follows pre‑release builds, “local” builds from
#  the repository checkout, and explicit numbers pin a specific tag.
# ------------------------------------------------------------------



# ------------------------------------------------------------------
#  Component Desired Versions - Stable
#  --------------------------------
#  Current components that are in Stable
# ------------------------------------------------------------------

# Azhar – N3DS emulator
export AZAHAR_DESIRED_VERSION="2123.2"

# Cemu – Wii U emulator
export CEMU_DESIRED_VERSION="2.6"

# Dolphin – GameCube/Wii emulator
export DOLPHIN_DESIRED_VERSION="2512"

# DuckStation (Legacy) – PlayStation  1 Emulator (Our own legacy version)
export DUCKSTATION_DESIRED_VERSION="preview"

# ES‑DE – ES‑DE Front‑End (Our own built version)
export ES_DE_DESIRED_VERSION="latest"

# Flips – IPS Patcher (Our own shipped version)
export FLIPS_DESIRED_VERSION="v198"

# GZDoom – Modern Doom engine (The last version)
export GZDOOM_DESIRED_VERSION="latest"

# MAME – Multiple Arcade Machine Emulator
export MAME_DESIRED_VERSION="0.283"

# MelonDS – Nintendo DS emulator
export MELONDS_DESIRED_VERSION="1.1"

# OpenBOR – Open Beat 'em up engine
export OPENBOR_DESIRED_VERSION="7533"

# PCSX2 – PlayStation 2 emulator
export PCSX2_DESIRED_VERSION="v2.5.404"

# PortMaster – Multi‑system game launcher and manager
export PORTMASTER_DESIRED_VERSION="latest"

# PPSSPP – PSP emulator
export PPSSPP_DESIRED_VERSION="1.19.3"

# PrimeHack – Metroid Prime mod for Dolphin
export PRIMEHACK_DESIRED_VERSION="master-230724.27"

# RetroArch – Multi‑system front‑end
export RETROARCH_DESIRED_VERSION="1.22.2"

# RPCS3 – PlayStation 3 emulator
export RPCS3_DESIRED_VERSION="0.0.38-1-77aa5d4b"

# Ruffle – Flash Player emulator
export RUFFLE_DESIRED_VERSION="0.2.0-nightly.2025.12.26"

# Ryujinx – Nintendo Switch emulator
export RYUBING_DESIRED_VERSION="1.3.2"

# Solarus – Action‑RPG engine
export SOLARUS_DESIRED_VERSION="v2.0.2"

# Steam ROM Manager – Organises ROM collections for Steam
export STEAM_ROM_MANAGER_DESIRED_VERSION="2.5.33"

# Vita3K – PlayStation Vita emulator
export VITA3K_DESIRED_VERSION="3846"

# Xemu – Original Xbox emulator
export XEMU_DESIRED_VERSION="0.8.124"

# XRoar – Tano Dragon emulator (Our own built version)
export XROAR_DESIRED_VERSION="1.10"




# ------------------------------------------------------------------
#  Component Desired Versions - Cooker
#  --------------------------------
#  New components that are in Cooker for future Major Release
# ------------------------------------------------------------------

# DOSBox‑X – Enhanced DOSBox
export DOSBOX_X_DESIRED_VERSION="latest"

# Eden – Nintendo Switch emulator
export EDEN_DESIRED_VERSION="latest"

# EKA2L1 – Symbian OS emulator
export EKA2L1_DESIRED_VERSION="latest"

# Flycast – Dreamcast emulator
export FLYCAST_DESIRED_VERSION="latest"

# Gargoyle – Interactive fictionS front‑end
export GARGOYLE_DESIRED_VERSION="latest"

# Hypseus – Laser Disc Arcade emulator
export HYPSEUS_DESIRED_VERSION="latest"

# Ikeman Go – Fighting engine
export IKEMANGO_DESIRED_VERSION="latest"

# KEGS – Apple IIgs emulator
export KEGS_DESIRED_VERSION="1.38"

# Lindbergh – SEGA lindbergh emulator
export LINDBERGH_DESIRED_VERSION="latest"

# Mudlet – MUD client
export MUDLET_DESIRED_VERSION="4.19.1"

# Raze – Duke Nukem GZDoom based engine
export RAZE_DESIRED_VERSION="latest"

# ScummVM – Classic point‑and‑click adventure engine
export SCUMMVM_DESIRED_VERSION="latest"

# ShadPS4 – PlayStation 4 emulator 
export SHADPS4_DESIRED_VERSION="latest"

# SimCoupe – SAM Coupé emulator
export SIMCOUPE_DESIRED_VERSION="latest"

# SuperModel – SEGA Model 3 arcade emulator
export SUPERMODEL_DESIRED_VERSION="latest"

# UZDoom – Modern Doom engine
export UZDOOM_DESIRED_VERSION="latest"

# VPinball – Virtual pinball platform
export VPINBALL_DESIRED_VERSION="newest"

# Xenia – Xbox 360 emulator (newest build)
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
