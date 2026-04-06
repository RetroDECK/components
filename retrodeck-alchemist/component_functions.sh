#!/bin/bash

_cli_run::retrodeck-alchemist() {
  local component_path="$(get_own_component_path)"

  source "$component_path/rd_tools/alchemist/alchemist.sh"
}
