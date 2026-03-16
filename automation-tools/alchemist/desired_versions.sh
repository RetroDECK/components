#!/bin/bash

# ==============================================================================
#  VERSION SELECTION RULES
#  ----------------
#  - MAIN    : Stable releases
#  - COOKER  : Cooker / development builds
#  - Only ONE export per component must be active
#
# VERSION MEANINGS
#  ----------------
#  Each variable defines which upstream version the build system will fetch
#  for a given component:
#
#    "latest"   → Newest official stable release
#    "preview"  → Pre-release / preview builds
#    "local"    → Build from the local repository checkout
#    "newest"   → Newest available build, including beta or pre-release
#    "<serial/numbers/letters/hash>" → Pin to a specific version
# ==============================================================================


# ------------------------------------------------------------------
#  Default Global Runtime Versions
#  ----------------
#  These define which Qt libraries the framework will link against.
# ------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Qt 5 Runtime - Legacy Qt Support
# ------------------------------------------------------------------------------

# MAIN (Stable)
export DESIRED_QT5_RUNTIME_VERSION="5.15-25.08"



# ==============================================================================
#  Component Desired Versions - Flathub
# ==============================================================================
#  Flathub requires the release hash for each component to lock down specific versions.
#  To find the correct release hash, check the output of the corresponding
#  component_version file.
#
#  For each component, document the user-friendly version (as listed on Flathub)
#  in the following format:
#  # Version: XXXX
# ==============================================================================



# ------------------------------------------------------------------------------
# Azahar - Nintendo 3DS Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.azahar_emu.Azahar
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2124.3
  export AZAHAR_DESIRED_VERSION="56e56b4c5cd4668d99512f26ef89c3c7880d5c159b1e9f21d6540db0fd4d9420"

# COOKER (Override)
# export AZAHAR_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Cemu - Wii U Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/info.cemu.Cemu
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2.6
  export CEMU_DESIRED_VERSION="4a22a30407fd3b647165c651ffa785ae0da3ef66b3b5c5249880e793bbec2d6e"

# COOKER (Override)
# export CEMU_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Dolphin - GameCube / Wii Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.DolphinEmu.dolphin-emu
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2603
  export DOLPHIN_DESIRED_VERSION="f69d7247a393ff8a8a8f5b9606b897316191fa834bff97afb897e6ca52e11a72"

# COOKER (Override)
# export DOLPHIN_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# GZDoom - Modern Doom Engine
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.zdoom.GZDoom
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 4.14.2
  export GZDOOM_DESIRED_VERSION="604ffd1743c8eeafdfdb9c5663e261014d0ca2572ceeb2f54dcef9b1881d23cf"

# COOKER (Override)
# export GZDOOM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# MAME - Multiple Arcade Machine Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.mamedev.MAME
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.286
 export MAME_DESIRED_VERSION="a5f7ddbc14ffd38bd9bc09f60c73204cf9e64dd361666f0e59b3247eb2c23395"

# COOKER (Override)
#  export MAME_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# MelonDS - Nintendo DS Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/net.kuribo64.melonDS
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 1.1
  export MELONDS_DESIRED_VERSION="9c8ac146f909e365673fdf2eb711f588c0fdf72fce11fc05c9db698a88d269ba"

# COOKER (Override)
# export MELONDS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PPSSPP - PlayStation Portable Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.ppsspp.PPSSPP
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 1.20.2
  export PPSSPP_DESIRED_VERSION="f998ae83bb6e842635b6c32e8ca3298b7e2ac247ae559f3030c280863d2b5537"

# COOKER (Override)
# PPSSPP_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# RPCS3 - PlayStation 3 Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/net.rpcs3.RPCS3
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.0.40-189
  export RPCS3_DESIRED_VERSION="f77271ddeb6dee231a4fbca1a7c6eeaf8a132638f1eda9af288322fb2894eebc"

# COOKER (Override)
# export RPCS3_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ruffle - Flash Player Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/rs.ruffle.Ruffle
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.2.0-nightly.2026.3.12
 export RUFFLE_DESIRED_VERSION="48a57600d24643d7267fe391177882376130654b588abafe1d31437f896b1488"

# COOKER (Override)
# export RUFFLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Steam ROM Manager - Steam Artwork & ROM Importer
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/com.steamgriddb.steam-rom-manager
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2.5.34
  export STEAM_ROM_MANAGER_DESIRED_VERSION="b563c9f81ecad09e9a19f5093484fc00ba08fb375b81542e8d889b15fe9f7bff"

# COOKER (Override)
# export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Xemu - Original Xbox Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/app.xemu.xemu
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.8.134
 export XEMU_DESIRED_VERSION="0739a75dec8215f73d58e19e492a6f9f6a796d1f73842d40da56e7f51a81cbad"

# COOKER (Override)
# export XEMU_DESIRED_VERSION="latest"


# ==============================================================================
#  Component Desired Versions - Web / GitHub / GitLab / AppImages
# ==============================================================================
#  Components sourced from GitHub, GitLab, or other web pages,
#  provided as loose binaries or AppImages.
#
#  Versions should be explicitly defined to ensure reproducible builds.
# ==============================================================================


# ------------------------------------------------------------------------------
# OpenBOR - Open Beat 'em Up Engine
# Source: AppImage
# Link: https://github.com/DCurrent/openbor/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export OPENBOR_DESIRED_VERSION="v7533"

# COOKER (Override)
# export OPENBOR_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PCSX2 - PlayStation 2 Emulator
# Source: AppImage
# Link: https://github.com/PCSX2/pcsx2/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export PCSX2_DESIRED_VERSION="v2.6.3"

# COOKER (Override)
# export PCSX2_DESIRED_VERSION="newest"


# ------------------------------------------------------------------------------
# RetroArch - Multi-System Front-End
# Source: AppImage
# Link: https://buildbot.libretro.com/stable/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export RETROARCH_DESIRED_VERSION="1.22.2"

# COOKER (Override)
# export RETROARCH_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Solarus - Action RPG Engine
# Source: AppImage
# Link: https://gitlab.com/solarus-games/solarus/-/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export SOLARUS_DESIRED_VERSION="v2.0.3"

# COOKER (Override)
# export SOLARUS_DESIRED_VERSION="latest"



# ==============================================================================
#  Component Desired Versions - Self-Built / Repo-Hosted Components
# ==============================================================================
#  Components that are self-built and hosted in the RetroDECK repository.
#
#
#  Specify and the desired version for each component below.
# ==============================================================================


# ------------------------------------------------------------------------------
# DuckStation (Legacy) - PlayStation 1 Emulator
# Source: AppImage (RetroDECK-built legacy archive)
# Link: https://github.com/RetroDECK/Duckstation/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export DUCKSTATION_DESIRED_VERSION="preview"

# COOKER (Override)
# export DUCKSTATION_DESIRED_VERSION="preview"


# ------------------------------------------------------------------------------
# ES-DE - EmulationStation Desktop Edition
# Source: AppImage (RetroDECK-built)
# Link: https://github.com/RetroDECK/ES-DE/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 3.4.0
  export ES_DE_DESIRED_VERSION="latest"

# COOKER (Override)
#  export ES_DE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Flips - IPS Patch Utility
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/components/tree/cooker/flips/assets
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 198
  export FLIPS_DESIRED_VERSION="latest"

# COOKER (Override)
# export FLIPS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# PortMaster - Multi-System Game Launcher
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/components/tree/cooker/portmaster/assets
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export PORTMASTER_DESIRED_VERSION="latest"

# COOKER (Override)
# export PORTMASTER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# XRoar - Tano Dragon Emulator
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/XRoar/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 1.10
  export XROAR_DESIRED_VERSION="latest"

# COOKER (Override)
# export XROAR_DESIRED_VERSION="latest"



# ------------------------------------------------------------------------------
# PrimeHack - Metroid Prime Fork of Dolphin
# Source: AppImage
# Link: https://github.com/RetroDECK/io.github.shiiion.primehack/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export PRIMEHACK_DESIRED_VERSION="master-230724.27"

# COOKER (Override)
# export PRIMEHACK_DESIRED_VERSION="master-230724.27"



# ------------------------------------------------------------------------------
# Vita3K - PlayStation Vita Emulator
# Source: AppImage (RetroDECK-mirrored)
# Link: https://github.com/RetroDECK/Vita3K-bin/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export VITA3K_DESIRED_VERSION="3936"

# COOKER (Override)
# export VITA3K_DESIRED_VERSION="latest"




# ==============================================================================
#  Component Desired Versions - Future
# ==============================================================================
#  New components being developed in the Cooker branch for an upcoming major release.
#  These components are planned for future inclusion and are not yet part of the
#  current stable version.
# ==============================================================================

# ------------------------------------------------------------------------------
# Adventure Game Studio
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export AGS_DESIRED_VERSION="newest"

# COOKER (Override)
  export AGS_DESIRED_VERSION="newest"


# ------------------------------------------------------------------------------
# Commander X16 8-bit Computer
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export COMMANDER_X16_DESIRED_VERSION="latest"

# COOKER (Override)
  export COMMANDER_X16_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# DOSBox-X - Enhanced DOSBox Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export DOSBOX_X_DESIRED_VERSION="latest"

# COOKER (Override)
  export DOSBOX_X_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ECWOLF - Wolfenstein 3D Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export ECWOLF_DESIRED_VERSION="latest"

# COOKER (Override)
  export ECWOLF_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# EKA2L1 - Symbian OS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EKA2L1_DESIRED_VERSION="latest"

# COOKER (Override)
  export EKA2L1_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# FS-UAE - Amiga Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export FS_UAE_DESIRED_VERSION=""

# COOKER (Override)
  export FS_UAE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Flycast - Dreamcast Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export FLYCAST_DESIRED_VERSION="latest"

# COOKER (Override)
  export FLYCAST_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Gargoyle - Interactive Fiction Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export GARGOYLE_DESIRED_VERSION=""

# COOKER (Override)
  export GARGOYLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Hypseus - Laser Disc Arcade Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export HYPSEUS_DESIRED_VERSION=""

# COOKER (Override)
  export HYPSEUS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ironwail - Quake Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export IRONWAIL_DESIRED_VERSION="latest"

# COOKER (Override)
  export IRONWAIL_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Ikeman Go - Fighting Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export IKEMANGO_DESIRED_VERSION="latest"

# COOKER (Override)
  export IKEMANGO_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# KEGS - Apple IIGS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export KEGS_DESIRED_VERSION="1.38"

# COOKER (Override)
  export KEGS_DESIRED_VERSION="1.38"


# ------------------------------------------------------------------------------
# Lindbergh - SEGA Lindbergh Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export LINDBERGH_DESIRED_VERSION="latest"

# COOKER (Override)
  export LINDBERGH_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Mednafen - Multi Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MEDNAFEN_DESIRED_VERSION="latest"

# COOKER (Override)
  export MEDNAFEN_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Mudlet - MUD Client
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MUDLET_DESIRED_VERSION="latest"

# COOKER (Override)
  export MUDLET_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Open Surge Engine - 2D Game Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export OPENSURGE_DESIRED_VERSION="latest"

# COOKER (Override)
  export OPENSURGE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Orictron - Oric-1/Atmos/Telestrat/Pravetz 8D emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export ORICUTRON_DESIRED_VERSION="20260123"

# COOKER (Override)
  export ORICUTRON_DESIRED_VERSION="20260123"

# ------------------------------------------------------------------------------
# Raze - Duke Nukem Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RAZE_DESIRED_VERSION="latest"

# COOKER (Override)
  export RAZE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ScummVM - Point-and-Click Adventure Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SCUMMVM_DESIRED_VERSION="latest"

# COOKER (Override)
  export SCUMMVM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SDL2TRS - TRS-80 Model I/III/4/4P Emulator 
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SDL2TRS_DESIRED_VERSION="latest"

# COOKER (Override)
  export SDL2TRS_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# ShadPS4 - PlayStation 4 Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SHADPS4_DESIRED_VERSION="latest"

# COOKER (Override)
  export SHADPS4_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SimCoupe - SAM Coupé Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SIMCOUPE_DESIRED_VERSION="latest"

# COOKER (Override)
  export SIMCOUPE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SuperModel - SEGA Model 3 Arcade Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SUPERMODEL_DESIRED_VERSION="latest"

# COOKER (Override)
  export SUPERMODEL_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Tsugaru - FM TOWNS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SUPERMODEL_DESIRED_VERSION="newest"

# COOKER (Override)
  export TSUGARU_DESIRED_VERSION="newest"

# ------------------------------------------------------------------------------
# UZDoom - Modern Doom Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export UZDOOM_DESIRED_VERSION="latest"

# COOKER (Override)
  export UZDOOM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# VPinball - Virtual Pinball Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export VPINBALL_DESIRED_VERSION="newest"

# COOKER (Override)
  export VPINBALL_DESIRED_VERSION="newest"


# ------------------------------------------------------------------------------
# Xenia Edge - Xbox 360 Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export XENIA_EDGE_DESIRED_VERSION="newest"

# COOKER (Override)
  export XENIA_EDGE_DESIRED_VERSION="newest"

# ------------------------------------------------------------------------------
# ZEsarUX - ZX Second-Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export ZESARUX_DESIRED_VERSION="latest"

# COOKER (Override)
  export ZESARUX_DESIRED_VERSION="latest"


# ------------------------------------------------------------------
#  Framework Component Desired Version
#  -----------------------------------
#  Determines which framework branch to pull based on the Git ref.
# ------------------------------------------------------------------

if [[ "${GITHUB_REF_NAME:-}" != "main" ]]; then
    # Non‑main branches use the “latest-cooker” build tag
    export FRAMEWORK_DESIRED_VERSION="latest-cooker on $(date +%Y-%m-%d)"
else
    # Main branch uses the “main‑latest” build tag
    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"
fi

# ==============================================================================
#  Component Desired Versions - Removed
# ==============================================================================
#  Components that has been removed or was never included into RetroDECK 
#  due to some factor.
# ==============================================================================


# ------------------------------------------------------------------------------
# Eden - Nintendo Switch Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EDEN_DESIRED_VERSION="latest"

# COOKER (Override)
  export EDEN_DESIRED_VERSION="latest"

# ------------------------------------------------------------------------------
# Ryubing - Nintendo Switch Emulator
# Source: AppImage
# Link: https://git.ryujinx.app/ryubing/ryujinx/-/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export RYUBING_DESIRED_VERSION="latest"

# COOKER (Override)
# export RYUBING_DESIRED_VERSION="latest"
