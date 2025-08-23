#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_id "rs.ruffle.Ruffle"

# Custom Commands

finalize
