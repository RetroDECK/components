#!/bin/bash

source "automation-tools/assembler.sh"

# URL is a redirect, so we need to resolve it

assemble flatpak_id net.shadps4.shadPS4

# Custom Commands

finalize
