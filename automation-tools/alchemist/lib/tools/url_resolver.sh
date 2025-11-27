#!/bin/bash

# Substitute {VERSION} placeholder in a URL
# Usage: substitute_version <url> <version>
# Returns: URL with {VERSION} replaced
substitute_version() {
    local url="$1"
    local version="$2"

    echo "${url//\{VERSION\}/$version}"
}

# Check if a URL contains version placeholder
# Usage: has_version_placeholder <url>
# Returns: 0 if placeholder exists, 1 otherwise
has_version_placeholder() {
    local url="$1"
    [[ "$url" == *"{VERSION}"* ]]
}
