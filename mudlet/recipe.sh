#!/bin/bash

source "automation-tools/assembler.sh"

assemble appimage "https://www.mudlet.org/download/42/"

# Custom Commands

finalize
