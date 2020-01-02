#!/usr/bin/env bash

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

msg "Setting library load paths for portability and"
msg "Stripping remaining products..."
IFS=$'\n' read -ra ADDR -d $'\0' <<< "$(find install -type f -exec file {} \;)"
for f in "${ADDR[@]}"; do
	# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
	if [ -n "$(echo $f | grep 'ELF .* interpreter')" ]; then
		bin=$(echo $f | awk '{print $1}')
		patchelf --set-rpath '$ORIGIN/../lib' "${bin: : -1}"
	fi

	# Strip remaining products
	if [ -n "$(echo $f | grep 'not stripped' | grep -v 'strip')" ]; then
		f=$(echo $f | awk '{print $1}')
		strip "${f: : -1}" 2>/dev/null
	fi
done
