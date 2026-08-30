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
# Version: 2126.0
  export AZAHAR_DESIRED_VERSION="31a62030cd75ecb24cfa766e410ecb861ef5a517f150fed726d1eaa757e79ca0"

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
# Version: 2606a
  export DOLPHIN_DESIRED_VERSION="1b150924d3216b59a3717245955cd7f3c7649edd0fecf39ebb697a0bd24304be"

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
# Version: 0.289
 export MAME_DESIRED_VERSION="41ebdb5c266627f4d1f02ba11f8109e793d2381081b68afc48714dd48a703788"

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
# Version: 1.20.4
  export PPSSPP_DESIRED_VERSION="193bbe95656ed696c8e5a5e42831ee8017d53514e9e0e0acaa3e1235e22089d3"

# COOKER (Override)
# PPSSPP_DESIRED_VERSION="latest"





# ------------------------------------------------------------------------------
# Ruffle - Flash Player Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/rs.ruffle.Ruffle
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.5.0
 export RUFFLE_DESIRED_VERSION="acc78770a5eb822c6d70ab3eb66a7626722c3ebfaab3aa985797ee81bb79ebfa"

# COOKER (Override)
# export RUFFLE_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Steam ROM Manager - Steam Artwork & ROM Importer
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/com.steamgriddb.steam-rom-manager
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 2.5.44
  export STEAM_ROM_MANAGER_DESIRED_VERSION="c1eebb375d6ca39f4d417c4cb862a62099eb43a6fb2e3392977739770abee96f"

# COOKER (Override)
# export STEAM_ROM_MANAGER_DESIRED_VERSION="latest"


# ------------------------------------------------------------------------------
# Xemu - Original Xbox Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/app.xemu.xemu
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.8.136
 export XEMU_DESIRED_VERSION="2f8b8889edcf69fb2ba2a8691371a7bb49febeba360e9c87555379c50ba946e9"

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
# RPCS3 - PlayStation 3 Emulator
# Source: AppImage
# Link: https://github.com/RPCS3/rpcs3-binaries-linux/
# ------------------------------------------------------------------------------
# MAIN (Stable)
# Version: 0.0.42-19873
  export RPCS3_DESIRED_VERSION="latest"

# COOKER (Override)
# export RPCS3_DESIRED_VERSION="latest"


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
  export PCSX2_DESIRED_VERSION="v2.8.0"

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
  export SOLARUS_DESIRED_VERSION="v2.1.3"

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
# Link: https://github.com/Vita3K/Vita3K-builds/releases
# ------------------------------------------------------------------------------
# MAIN (Stable)
  export VITA3K_DESIRED_VERSION="4074"

# COOKER (Override)
# export VITA3K_DESIRED_VERSION="latest"


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

