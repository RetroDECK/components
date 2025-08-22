#!/bin/bash

source "automation-tools/assembler.sh"

# URL is a redirect, so we need to resolve it

assemble flatpak_id org.scummvm.ScummVM

# Custom Commands

finalize
