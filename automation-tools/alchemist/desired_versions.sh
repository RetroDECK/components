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
#  particular Emulator / tool to fetch.  “latest” pulls the newest
#  release, “preview” follows pre‑release builds, “local” builds from
#  the repository checkout, and explicit numbers pin a specific tag.
# ------------------------------------------------------------------



# ------------------------------------------------------------------
#  Component Desired Versions - Stable
#  --------------------------------
#  Current components that are in Stable
# ------------------------------------------------------------------

# Azhar – N3DS Emulator
# Flatpak
export AZAHAR_DESIRED_VERSION="2123.2"

# Cemu – Wii U Emulator
# Flatpak
export CEMU_DESIRED_VERSION="2.6"

# Dolphin – GameCube/Wii Emulator
export DOLPHIN_DESIRED_VERSION="2512"

# GZDoom – Modern Doom Engine
# Flatpak (The last version)
export GZDOOM_DESIRED_VERSION="latest"

# MAME – Multiple Arcade Machine Emulator
# Flatpak
export MAME_DESIRED_VERSION="0.283"

# MelonDS – Nintendo DS Emulator
# Flatpak
export MELONDS_DESIRED_VERSION="1.1"

# OpenBOR – Open Beat 'em up Engine
# AppImage
export OPENBOR_DESIRED_VERSION="v7533"
export OPENBOR_DESIRED_DLVERSION="7533"

# PCSX2 – PlayStation 2 Emulator
# AppImage
export PCSX2_DESIRED_VERSION="v2.5.404"

# PortMaster – Multi‑system game launcher and manager
# Binary
export PORTMASTER_DESIRED_VERSION="latest"

# PPSSPP – PSP Emulator
# Flatpak
export PPSSPP_DESIRED_VERSION="1.19.3"

# PrimeHack – Metroid Prime fork of Dolphin
# AppImage
export PRIMEHACK_DESIRED_VERSION="master-230724.27"

# RetroArch – Multi‑System Front‑End
# AppImage
export RETROARCH_DESIRED_VERSION="1.22.2"

# RPCS3 – PlayStation 3 Emulator
# Flatpak
export RPCS3_DESIRED_VERSION="0.0.38-1-77aa5d4b"

# Ruffle – Flash Player Emulator
# Flatpak
export RUFFLE_DESIRED_VERSION="0.2.0-nightly.2025.12.26"

# Ryujinx – Nintendo Switch Emulator
# Flatpak
export RYUBING_DESIRED_VERSION="1.3.2"

# Solarus – Action‑RPG Engine
# AppImage
export SOLARUS_DESIRED_VERSION="v2.0.2"

# Steam ROM Manager – Bulk game importer and artwork manager for Steam
# Flatpak
export STEAM_ROM_MANAGER_DESIRED_VERSION="2.5.33"

# Xemu – Original Xbox Emulator
# Flatpak
export XEMU_DESIRED_VERSION="0.8.124"



# ------------------------------------------------------------------
#  Component Desired Versions - Stable Self-built
#  --------------------------------
#  Current components that are in Stable that are built or stored on the RetroDECK Repo
# ------------------------------------------------------------------

# DuckStation (Legacy) – PlayStation  1 Emulator
# AppImage (Our own built legacy archive)
# https://github.com/RetroDECK/Duckstation/
export DUCKSTATION_DESIRED_VERSION="preview"

# ES‑DE – ES‑DE Front‑End
# AppImage (Our own built version)
# https://github.com/RetroDECK/ES-DE
export ES_DE_DESIRED_VERSION="latest"

# Flips – IPS Patcher
# Binary (Our own shipped version)
# https://github.com/RetroDECK/components/tree/cooker/flips/assets
export FLIPS_DESIRED_VERSION="v198"

# XRoar – Tano Dragon Emulator
# Binary (Our own built version)
# https://github.com/RetroDECK/XRoar
export XROAR_DESIRED_VERSION="latest"

# Vita3K – PlayStation Vita Emulator
# AppImage (Our own mirrored version)
# https://github.com/RetroDECK/Vita3K-bin
export VITA3K_DESIRED_VERSION="3847"



# ------------------------------------------------------------------
#  Component Desired Versions - Cooker
#  --------------------------------
#  New components that are in Cooker for future Major Release
# ------------------------------------------------------------------

# DOSBox‑X – Enhanced DOSBox Engine
export DOSBOX_X_DESIRED_VERSION="latest"

# Eden – Nintendo Switch Emulator
export EDEN_DESIRED_VERSION="latest"

# EKA2L1 – Symbian OS Emulator
export EKA2L1_DESIRED_VERSION="latest"

# Flycast – Dreamcast Emulator
export FLYCAST_DESIRED_VERSION="latest"

# Gargoyle – Interactive Fiction Emulator
export GARGOYLE_DESIRED_VERSION="latest"

# Hypseus – Laser Disc Arcade Emulator
export HYPSEUS_DESIRED_VERSION="latest"

# Ikeman Go – Fighting Engine
export IKEMANGO_DESIRED_VERSION="latest"

# KEGS – Apple IIGS Emulator
export KEGS_DESIRED_VERSION="1.38"

# Lindbergh – SEGA Lindbergh Emulator
export LINDBERGH_DESIRED_VERSION="latest"

# Mudlet – MUD Client
export MUDLET_DESIRED_VERSION="4.19.1"

# Raze – Duke Nukem GZDoom based Engine
export RAZE_DESIRED_VERSION="latest"

# ScummVM – Classic point‑and‑click adventure Engine
export SCUMMVM_DESIRED_VERSION="latest"

# ShadPS4 – PlayStation 4 Emulator
export SHADPS4_DESIRED_VERSION="latest"

# SimCoupe – SAM Coupé Emulator
export SIMCOUPE_DESIRED_VERSION="latest"

# SuperModel – SEGA Model 3 arcade Emulator
export SUPERMODEL_DESIRED_VERSION="latest"

# UZDoom – Modern Doom Engine
export UZDOOM_DESIRED_VERSION="latest"

# VPinball – Virtual Pinball Engine
export VPINBALL_DESIRED_VERSION="newest"

# Xenia – Xbox 360 Emulator (newest build)
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
