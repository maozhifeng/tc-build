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
	--clang-vendor "LiuNian" \
	--projects "clang;compiler-rt;lld;polly" \
	--targets "AArch64;ARM" \
	--shallow-clone \
	--lto thin \
	--build-stage1-only \
	--install-stage1-only

# Remove unused products
msg "Removing unused products..."
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la

# Strip remaining products
msg "Stripping remaining products..."
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
	strip ${f: : -1}
done

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

rel_date="$(date "+%Y/%m/%e")" # ISO 8601 format
pushd llvm-project
short_commit="$(cut -c-8 <<< "$(git rev-parse HEAD)")"
popd
# Generate product name
product_desc="LiuNian clang $rel_date $short_commit"

pushd install
rm .gitignore
git init && git add . && git commit -m "$product_desc" 1>/dev/null
git push https://$GITID:$GITPWD@github.com/wloot/clang.git HEAD:master -f
popd

cache store clang-ccache ${HOME}/.ccache
