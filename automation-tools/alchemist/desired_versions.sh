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
# Version: 2124
  export AZAHAR_DESIRED_VERSION="94b8fdd9355f408050747c20de8400339de7d5d27c2d75b9b5c093a2b4b0bba5"

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
# # Version: 2512
  export DOLPHIN_DESIRED_VERSION="4fa4752c90703c04e58e7f014be515e905c553c8a707b27ae35ffa5e41dbf6cf"

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
# Version: 0.284
  export MAME_DESIRED_VERSION="e3b6bf53f0b8a5c67c4c1dcd23d4e4c7cef24ec727890bdf749e18180cffbd3a"

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
# Version: 1.19.3
  export PPSSPP_DESIRED_VERSION="00d4ac93b5111818ad897284d70743e5d7e72af43ab1d660ee03356c88dda85e"

# COOKER (Override)
# PPSSPP_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# RPCS3 - PlayStation 3 Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/net.rpcs3.RPCS3
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.0.39-1-ef
  export RPCS3_DESIRED_VERSION="ee08049b192ac69e545eda3d4bc6b6a60e490b4e4df3417e2888d9ae80acb63c"

# COOKER (Override)
# export RPCS3_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Ruffle - Flash Player Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/rs.ruffle.Ruffle
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.2.0-nightly.2026.1.8
 export RUFFLE_DESIRED_VERSION="db881e38b0b37481ede11e56b307e0962760f1d26dedaff122e4f5c4221be1f3"

# COOKER (Override)
# export RUFFLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Steam ROM Manager - Steam Artwork & ROM Importer
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/com.steamgriddb.steam-rom-manager
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2.5.33
  export STEAM_ROM_MANAGER_DESIRED_VERSION="d0f60620a50ed0255e2657fcde6291db60afbaa56fc69ccac4c03b0733b3259c"

# COOKER (Override)
# export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Xemu - Original Xbox Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/app.xemu.xemu
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.8.130
  export XEMU_DESIRED_VERSION="987dc22f660ae8c003f2054585eb6e8506c3d1b42218b9244660208d4018eeab"

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
  export PCSX2_DESIRED_VERSION="v2.6.2"

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
# Ryubing - Nintendo Switch Emulator
# Source: AppImage
# Link: https://git.ryujinx.app/ryubing/ryujinx/-/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 1.3.3
  export RYUBING_DESIRED_VERSION="1.3.3"

# COOKER (Override)
# export RYUBING_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Solarus - Action RPG Engine
# Source: AppImage
# Link: https://gitlab.com/solarus-games/solarus/-/releases/
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export SOLARUS_DESIRED_VERSION="v2.0.2"

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
  export VITA3K_DESIRED_VERSION="3901"

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
# export AGS_DESIRED_VERSION=""

# COOKER (Override)
  export AGS_DESIRED_VERSION="newest"

# ------------------------------------------------------------------------------
# DOSBox-X - Enhanced DOSBox Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export DOSBOX_X_DESIRED_VERSION=""

# COOKER (Override)
  export DOSBOX_X_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Eden - Nintendo Switch Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EDEN_DESIRED_VERSION=""

# COOKER (Override)
  export EDEN_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# EKA2L1 - Symbian OS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export EKA2L1_DESIRED_VERSION=""

# COOKER (Override)
  export EKA2L1_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Flycast - Dreamcast Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export FLYCAST_DESIRED_VERSION=""

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
# Ikeman Go - Fighting Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export IKEMANGO_DESIRED_VERSION=""

# COOKER (Override)
  export IKEMANGO_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# KEGS - Apple IIGS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export KEGS_DESIRED_VERSION="1.38"

# COOKER (Override)
  export KEGS_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Lindbergh - SEGA Lindbergh Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export LINDBERGH_DESIRED_VERSION=""

# COOKER (Override)
  export LINDBERGH_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Mudlet - MUD Client
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export MUDLET_DESIRED_VERSION="4.19.1"

# COOKER (Override)
  export MUDLET_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Raze - Duke Nukem Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export RAZE_DESIRED_VERSION=""

# COOKER (Override)
  export RAZE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ScummVM - Point-and-Click Adventure Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SCUMMVM_DESIRED_VERSION=""

# COOKER (Override)
  export SCUMMVM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# ShadPS4 - PlayStation 4 Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SHADPS4_DESIRED_VERSION=""

# COOKER (Override)
  export SHADPS4_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SimCoupe - SAM Coupé Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SIMCOUPE_DESIRED_VERSION=""

# COOKER (Override)
  export SIMCOUPE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# SuperModel - SEGA Model 3 Arcade Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SUPERMODEL_DESIRED_VERSION=""

# COOKER (Override)
  export SUPERMODEL_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Tsugaru - FM TOWNS Emulator
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export SUPERMODEL_DESIRED_VERSION=""

# COOKER (Override)
  export TSUGARU_DESIRED_VERSION="newest"

# ------------------------------------------------------------------------------
# UZDoom - Modern Doom Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export UZDOOM_DESIRED_VERSION=""

# COOKER (Override)
  export UZDOOM_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# VPinball - Virtual Pinball Engine
# ------------------------------------------------------------------------------
# MAIN (Stable)
# export VPINBALL_DESIRED_VERSION=""

# COOKER (Override)
  export VPINBALL_DESIRED_VERSION="newest"


# ------------------------------------------------------------------------------
# Xenia - Xbox 360 Emulator
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
    # Non‑main branches use the “latest-cooker” build tag
    export FRAMEWORK_DESIRED_VERSION="latest-cooker on $(date +%Y-%m-%d)"
else
    # Main branch uses the “main‑latest” build tag
    export FRAMEWORK_DESIRED_VERSION="main-latest on $(date +%Y-%m-%d)"
fi
