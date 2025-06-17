#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "simonowen/simcoupe/simcoupe_*_amd64.tar.gz"

# Right now they are only on pre-release for BGFX
# gh_latest_release is instructed to fallback to the latest pre-release if no latest tag is found.

# Custom Commands

artifacts_path="$component/artifacts"

tar -xvf $component/artifacts/simcoupe_*_amd64.tar.gz -C $component/artifacts/
mv -f $component/artifacts/simcoupe_*_amd64/* $component/artifacts/
rm -f $component/artifacts/simcoupe_*_amd64.tar.gz
rmdir -f $component/artifacts/simcoupe_*_amd/

finalize
