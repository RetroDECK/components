#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_artifacts "https://github.com/RetroDECK/net.kuribo64.melonDS/releases/latest/download/RetroDECK-melonds-Artifact.tar.gz"

# Custom Commands

finalize
