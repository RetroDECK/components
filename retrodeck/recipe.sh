#!/bin/bash

# This is a dummy recipe just to make this component available to being installed with the defaulted files

source "automation-tools/assembler.sh"

rm -rf "$component/artifacts"
mkdir -p "$component/artifacts"

version="dummy"

finalize
