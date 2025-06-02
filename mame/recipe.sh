#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_id "org.mamedev.MAME"

# Custom Commands

# TODO: We need cheats, check main manifest

finalize
