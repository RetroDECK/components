#!/bin/bash

# ==============================================================================
#  VERSION POLICY
#  ----------------
#  This file defines the resolution strategy for each component version.
#  It is the single source of truth for HOW a component's version should be
#  determined when not explicitly pinned.
#
#  This file is shared across all branches and should rarely need manual edits.
#  Concrete pinned versions are stored separately in version_pins.sh (main branch only).
#
#  The Alchemist will combine policy + pins into the
#  final *_DESIRED_VERSION variables used in recipes.
#
# POLICY VALUES
#  ----------------
#  Each variable defines which upstream version the build system will resolve
#  for a given component when no pin override is present:
#
#    "latest"   -> Newest official stable release
#    "newest"   -> Newest available build, including beta or pre-release
#    "local"    -> Build from the local repository checkout
#    "<static>" -> A specific version string (tag, hash, etc.)
#
#  Static values are used for components where automatic resolution is not
#  available or where a specific version must always be used regardless of
#  branch or pinning.
# ==============================================================================


# ------------------------------------------------------------------
#  Default Global Runtime Versions
# ------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Qt 5 Runtime - Legacy Qt Support
# ------------------------------------------------------------------------------
export QT5_RUNTIME_VERSION_POLICY="5.15-25.08"



# ==============================================================================
#  Component Desired Versions - Flathub
# ==============================================================================
#  Flathub requires the release hash for each component to lock down specific versions.
#  To find the correct release hash, check the output of the corresponding
#  component_version file. The current release hash can also be found by runinng the
#  following command:
#
#  flatpak remote-info flathub <flatpak ID>
# ==============================================================================


# ------------------------------------------------------------------------------
# Azahar - Nintendo 3DS Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.azahar_emu.Azahar
# ------------------------------------------------------------------------------
export AZAHAR_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Cemu - Wii U Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/info.cemu.Cemu
# ------------------------------------------------------------------------------
export CEMU_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Dolphin - GameCube / Wii Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.DolphinEmu.dolphin-emu
# ------------------------------------------------------------------------------
export DOLPHIN_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# GZDoom - Modern Doom Engine
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.zdoom.GZDoom
# ------------------------------------------------------------------------------
export GZDOOM_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# MAME - Multiple Arcade Machine Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.mamedev.MAME
# ------------------------------------------------------------------------------
export MAME_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# MelonDS - Nintendo DS Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/net.kuribo64.melonDS
# ------------------------------------------------------------------------------
export MELONDS_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# PPSSPP - PlayStation Portable Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/org.ppsspp.PPSSPP
# ------------------------------------------------------------------------------
export PPSSPP_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# RPCS3 - PlayStation 3 Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/net.rpcs3.RPCS3
# ------------------------------------------------------------------------------
export RPCS3_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Ruffle - Flash Player Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/rs.ruffle.Ruffle
# ------------------------------------------------------------------------------
export RUFFLE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Steam ROM Manager - Steam Artwork & ROM Importer
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/com.steamgriddb.steam-rom-manager
# ------------------------------------------------------------------------------
export STEAM_ROM_MANAGER_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Xemu - Original Xbox Emulator
# Source: Flatpak - Flathub
# Link: https://flathub.org/en/apps/app.xemu.xemu
# ------------------------------------------------------------------------------
export XEMU_VERSION_POLICY="latest"



# ==============================================================================
#  Component Policies - Web / GitHub / GitLab / AppImages
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
export OPENBOR_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# PCSX2 - PlayStation 2 Emulator
# Source: AppImage
# Link: https://github.com/PCSX2/pcsx2/releases/
# ------------------------------------------------------------------------------
export PCSX2_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# RetroArch - Multi-System Front-End
# Source: AppImage
# Link: https://buildbot.libretro.com/stable/
# ------------------------------------------------------------------------------
export RETROARCH_VERSION_POLICY="1.22.2"

# ------------------------------------------------------------------------------
# Solarus - Action RPG Engine
# Source: AppImage
# Link: https://gitlab.com/solarus-games/solarus/-/releases/
# ------------------------------------------------------------------------------
export SOLARUS_VERSION_POLICY="latest"



# ==============================================================================
#  Component Policies - Self-Built / Repo-Hosted Components
# ==============================================================================
#  Components that are self-built and hosted in the RetroDECK repository.
# ==============================================================================


# ------------------------------------------------------------------------------
# DuckStation (Legacy) - PlayStation 1 Emulator
# Source: AppImage (RetroDECK-built legacy archive)
# Link: https://github.com/RetroDECK/Duckstation/releases
# ------------------------------------------------------------------------------
export DUCKSTATION_VERSION_POLICY="preview"

# ------------------------------------------------------------------------------
# ES-DE - EmulationStation Desktop Edition
# Source: AppImage (RetroDECK-built)
# Link: https://github.com/RetroDECK/ES-DE/releases
# ------------------------------------------------------------------------------
export ES_DE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Flips - IPS Patch Utility
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/components/tree/cooker/flips/assets
# ------------------------------------------------------------------------------
export FLIPS_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# PortMaster - Multi-System Game Launcher
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/components/tree/cooker/portmaster/assets
# ------------------------------------------------------------------------------
export PORTMASTER_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# XRoar - Tano Dragon Emulator
# Source: Binary (RetroDECK-built)
# Link: https://github.com/RetroDECK/XRoar/releases
# ------------------------------------------------------------------------------
export XROAR_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# PrimeHack - Metroid Prime Fork of Dolphin
# Source: AppImage
# Link: https://github.com/RetroDECK/io.github.shiiion.primehack/releases
# NOTE: Static version - no automatic resolution available
# ------------------------------------------------------------------------------
export PRIMEHACK_VERSION_POLICY="master-230724.27"

# ------------------------------------------------------------------------------
# Vita3K - PlayStation Vita Emulator
# Source: AppImage (RetroDECK-mirrored)
# Link: https://github.com/RetroDECK/Vita3K-bin/releases
# ------------------------------------------------------------------------------
export VITA3K_VERSION_POLICY="latest"



# ==============================================================================
#  Component Policies - In Development
# ==============================================================================
#  Components being developed in the cooker branch for an upcoming release.
#  These components are planned for future inclusion and are not yet part of
#  the current stable version.
# ==============================================================================


# ------------------------------------------------------------------------------
# Adventure Game Studio
# ------------------------------------------------------------------------------
export AGS_VERSION_POLICY="newest"

# ------------------------------------------------------------------------------
# Commander X16 8-bit Computer
# ------------------------------------------------------------------------------
export COMMANDER_X16_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# DOSBox-X - Enhanced DOSBox Engine
# ------------------------------------------------------------------------------
export DOSBOX_X_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# ECWOLF - Wolfenstein 3D Engine
# ------------------------------------------------------------------------------
export ECWOLF_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# EKA2L1 - Symbian OS Emulator
# ------------------------------------------------------------------------------
export EKA2L1_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# FS-UAE - Amiga Emulator
# ------------------------------------------------------------------------------
export FS_UAE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Flycast - Dreamcast Emulator
# ------------------------------------------------------------------------------
export FLYCAST_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Gargoyle - Interactive Fiction Emulator
# ------------------------------------------------------------------------------
export GARGOYLE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Hypseus - Laser Disc Arcade Emulator
# ------------------------------------------------------------------------------
export HYPSEUS_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Ironwail - Quake Engine
# ------------------------------------------------------------------------------
export IRONWAIL_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Ikeman Go - Fighting Engine
# ------------------------------------------------------------------------------
export IKEMANGO_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# KEGS - Apple IIGS Emulator
# ------------------------------------------------------------------------------
export KEGS_VERSION_POLICY="1.38"

# ------------------------------------------------------------------------------
# Lindbergh - SEGA Lindbergh Emulator
# ------------------------------------------------------------------------------
export LINDBERGH_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Mednafen - Multi Emulator
# ------------------------------------------------------------------------------
export MEDNAFEN_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Mudlet - MUD Client
# ------------------------------------------------------------------------------
export MUDLET_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Open Surge Engine - 2D Game Engine
# ------------------------------------------------------------------------------
export OPENSURGE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Orictron - Oric-1/Atmos/Telestrat/Pravetz 8D Emulator
# ------------------------------------------------------------------------------
export ORICUTRON_VERSION_POLICY="20260123"

# ------------------------------------------------------------------------------
# Raze - Duke Nukem Engine
# ------------------------------------------------------------------------------
export RAZE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# ScummVM - Point-and-Click Adventure Engine
# ------------------------------------------------------------------------------
export SCUMMVM_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# SDL2TRS - TRS-80 Model I/III/4/4P Emulator
# ------------------------------------------------------------------------------
export SDL2TRS_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# ShadPS4 - PlayStation 4 Emulator
# ------------------------------------------------------------------------------
export SHADPS4_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# SimCoupe - SAM Coupe Emulator
# ------------------------------------------------------------------------------
export SIMCOUPE_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# SuperModel - SEGA Model 3 Arcade Emulator
# ------------------------------------------------------------------------------
export SUPERMODEL_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Tsugaru - FM TOWNS Emulator
# ------------------------------------------------------------------------------
export TSUGARU_VERSION_POLICY="newest"

# ------------------------------------------------------------------------------
# UZDoom - Modern Doom Engine
# ------------------------------------------------------------------------------
export UZDOOM_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# VPinball - Virtual Pinball Engine
# ------------------------------------------------------------------------------
export VPINBALL_VERSION_POLICY="newest"

# ------------------------------------------------------------------------------
# Xenia Edge - Xbox 360 Emulator
# ------------------------------------------------------------------------------
export XENIA_EDGE_VERSION_POLICY="newest"

# ------------------------------------------------------------------------------
# ZEsarUX - ZX Second-Emulator
# ------------------------------------------------------------------------------
export ZESARUX_VERSION_POLICY="latest"



# ==============================================================================
#  Framework Component Desired Version
# ==============================================================================
#  Determines which framework branch to pull based on the Git ref.
# ==============================================================================


export FRAMEWORK_DESIRED_VERSION="$(git rev-parse --abbrev-ref HEAD) branch on $(date +%Y-%m-%d)"



# ==============================================================================
#  Component Policies - Removed / On Hold
# ==============================================================================
#  Components that have been removed or were never included into RetroDECK
#  due to some factor.
# ==============================================================================


# ------------------------------------------------------------------------------
# Eden - Nintendo Switch Emulator
# ------------------------------------------------------------------------------
export EDEN_VERSION_POLICY="latest"

# ------------------------------------------------------------------------------
# Ryubing - Nintendo Switch Emulator
# Source: AppImage
# Link: https://git.ryujinx.app/ryubing/ryujinx/-/releases/
# ------------------------------------------------------------------------------
export RYUBING_VERSION_POLICY="latest"
