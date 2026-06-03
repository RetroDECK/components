#!/bin/bash

if [ "$CALL_SOURCE" != "WINPLAY" ]; then
    log e "This script is not meant to be called directly. Please use winplay.sh to run this script."
    exit 1
fi

game_install() {
    log w "Not implemented yet: game_install"
}