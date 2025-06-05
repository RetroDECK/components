#!/bin/bash

source "automation-tools/assembler.sh"

assemble generic

# Custom Commands

cp -f * $component/artifacts/

finalize
