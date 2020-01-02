#!/usr/bin/env bash
# Script to build a toolchain specialized for Proton Kernel development

# Exit on error
set -e

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
	--clang-vendor "LiuNian-$(date +%Y%m%d)" \
	--projects "clang;compiler-rt;lld;polly" \
	--targets "ARM;AArch64;X86" \
	--incremental \
	--build-stage1-only \
	--install-stage1-only

# Build binutils
msg "Building binutils..."
export CC="ccache clang"
export CXX="ccache clang++"
./build-binutils.py \
	--targets arm aarch64 x86_64

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
msg "Setting library load paths for portability..."
for bin in $(find install -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
	# Remove last character from file output (':')
	bin="${bin: : -1}"

	patchelf --set-rpath '$ORIGIN/../lib' "$bin"
done
