#!/bin/bash

source "automation-tools/assembler.sh"

assemble flatpak_artifacts "https://github.com/RetroDECK/io.github.shiiion.primehack/releases/latest/download/RetroDECK-primehack-Artifact.tar.gz"

# Custom Commands

finalize
