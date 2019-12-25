#!/usr/bin/env bash
# Script to build a toolchain specialized for Proton Kernel development

# Exit on error
set -e

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

# Configure LLVM build
msg "Configuring full-fledged LLVM build..."
llvm_args=(--targets "ARM;AArch64;X86")
binutils_args=(--targets arm aarch64 x86_64)

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
	--clang-vendor "LiuNian-$(date +%Y%m%d)" \
	--projects "clang;compiler-rt;lld;polly" \
	--build-type "MinSizeRel" \
	--incremental \
	--build-stage1-only \
	--install-stage1-only \
	"${llvm_args[@]}"

# Build binutils
msg "Building binutils..."
./build-binutils.py \
	"${binutils_args[@]}"

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
msg "Setting library load paths for portability..."
for bin in $(find install -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
	# Remove last character from file output (':')
	bin="${bin: : -1}"

	if ldd "$bin" | grep -q "not found"; then
		echo "Setting rpath on $bin"
		patchelf --set-rpath '$ORIGIN/../lib' "$bin"
	fi
done
