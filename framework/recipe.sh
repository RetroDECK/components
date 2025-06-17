#!/bin/bash

# This is a dummy recipe just to make this component available to being installed with the defaulted files

source "automation-tools/assembler.sh"

assemble local "$component/rd_config_note.md"

if [[ "$GITHUB_REF_NAME" != "main" ]]; then
    branch="cooker"
else
    branch="main"
fi

echo "$branch-latest on $(date +%Y-%m-%d)" > "$component/component_version"

version="dummy"

finalize
