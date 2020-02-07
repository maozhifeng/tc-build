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
	--projects "clang;lld;polly" \
	--targets "ARM;AArch64;X86" \
	--update \
	--incremental \
	--build-stage1-only \
	--install-stage1-only \
	--install-folder "installTmp" \
	--additional-build-arguments "CLANG_REPOSITORY_STRING=GitHub.COM/WLoot"

# Build binutils
msg "Building binutils..."
ccacheBin=$(which ccache)
test $(which gcc) && export CC="${ccacheBin} gcc"
test $(which g++) && export CXX="${ccacheBin} g++"
./build-binutils.py \
	--targets arm aarch64 x86_64 \
	--install-folder "installTmp"

msg "Setting library load paths for portability and"
msg "Stripping remaining products..."
IFS=$'\n'
for f in $(find installTmp -type f -exec file {} \;); do
	if [ -n "$(echo $f | grep 'ELF .* interpreter')" ]; then
		i=$(echo $f | awk '{print $1}'); i=${i: : -1}
		# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
		if [ -d $(dirname $i)/../lib/ldscripts ]; then
			patchelf --set-rpath '$ORIGIN/../../lib:$ORIGIN/../lib' "$i"
		else
			if [ "$(patchelf --print-rpath $i)" != "\$ORIGIN/../../lib:\$ORIGIN/../lib" ]; then
				patchelf --set-rpath '$ORIGIN/../lib' "$i"
			fi
		fi
		# Strip remaining products
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			strip --strip-unneeded "$i"
		fi
	elif [ -n "$(echo $f | grep 'ELF .* relocatable')" ]; then
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			i=$(echo $f | awk '{print $1}');
			strip --strip-unneeded "${i: : -1}"
		fi
	else
		if [ -n "$(echo $f | grep 'not stripped')" ]; then
			i=$(echo $f | awk '{print $1}');
			strip --strip-all "${i: : -1}"
		fi
	fi
done

rm -rf ./install
mv installTmp/ install/
