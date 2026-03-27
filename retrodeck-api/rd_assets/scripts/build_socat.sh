#!/bin/bash

set -euo pipefail

log info "Building socat..."

cd "$EXTRACTED_PATH/socat-$SOURCE_VERSION"

./configure \
  --disable-openssl \
  --disable-readline \
  --disable-libwrap \
  --disable-socks4 \
  --disable-socks4a \
  --disable-proxy \
  --disable-tun \
  --disable-sctp

make
