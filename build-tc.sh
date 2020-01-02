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
IFS=$'\n'
for f in $(find install -type f -exec file {} \;); do
	if [ -n "$(echo $f | grep 'ELF .* LSB executable')" ]; then
		i=$(echo $f | awk '{print $1}')
		# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
		patchelf --set-rpath '$ORIGIN/../lib' "${i: : -1}"
		# Strip remaining products
		if [ -n "$(echo $f | grep 'not stripped' | grep -v 'bin/strip')" ]; then
			strip --strip-unneeded "${i: : -1}"
		fi
	elif [ -n "$(echo $f | grep 'ELF .* LSB shared object')" ]; then
		i=$(echo $f | awk '{print $1}')
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			strip --strip-all "${i: : -1}"
		fi
	fi
done
