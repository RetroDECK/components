#!/bin/bash

source "automation-tools/assembler.sh"

assemble gh_latest_release "ruffle-rs/ruffle/ruffle-nightly-*-linux-x86_64.tar.gz"

# Custom Commands

finalize
