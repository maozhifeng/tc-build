#!/usr/bin/env bash

# Show all commands and exit upon failure
set -eux

export LD=ld.lld-10
export CC=clang-10
export CXX=clang++-10

# Enable compression so that we can have more objects in
ccache --set-config=compression=true

# Clear out the stats so we actually know the cache stats
ccache -z

# Update ccache symlinks
/usr/sbin/update-ccache-symlinks

# Prepend ccache into the PATH
export PATH="/usr/lib/ccache:$PATH"
