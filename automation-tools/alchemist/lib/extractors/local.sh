#!/bin/bash

extractor_info() {
  echo "type:local,flatpak,git"
}

extract() {
  local source="$1"
  local dest="$2"
  local type="$3"

  log info "Source $source needs no extraction, proceeding to file gathering"
  echo "EXTRACTED_PATH=$source"
  return 0
}
