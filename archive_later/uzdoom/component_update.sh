#!/bin/bash

#########################################################################
# These actions happen conditionally based on the version being upgraded
#########################################################################

if [[ $(check_version_is_older_than "$version_being_updated" "0.10.1b") == "true" ]]; then
    if [ -d "$storage_path/uzdoom"]; then
        move "$storage_path/uzdoom" "$storage_path/doom/uzdoom"
    fi
    if [ -d "$storage_path/gzdoom"]; then
        move "$storage_path/gzdoom" "$storage_path/doom/uzdoom"
    fi
    if [ -d "$storage_path/doom/gzdoom"]; then
        move "$storage_path/doom/gzdoom" "$storage_path/doom/uzdoom"
    fi
