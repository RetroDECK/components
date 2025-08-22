#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_id org.flycast.Flycast

# Custom Commands

finalize
