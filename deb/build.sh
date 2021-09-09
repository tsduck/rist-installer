#!/usr/bin/env bash
#-----------------------------------------------------------------------------
#
#  RIST library installers
#  Copyright (c) 2021, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#-----------------------------------------------------------------------------
#
#  This script builds the RIST packages on apt-based distros
#  (Debian, Ubuntu, Rapsbian, Mint, etc.)
#
#-----------------------------------------------------------------------------

source $(dirname "$0")/../include.sh

# Get distro description.
DISTRO=$(lsb_release -si 2>/dev/null | tr A-Z a-z | sed 's/linuxmint/mint/')$(lsb_release -sr 2>/dev/null | sed 's/\..*//')
[[ -n "$DISTRO" ]] && DISTRO=".$DISTRO"

# Adjust version numbering for debian packaging.
VERSION="${VERSION}${DISTRO}"
ARCH=$(dpkg-architecture -qDEB_BUILD_ARCH)

# Temporary system root.
SYSROOT="$BUILD_DIR/tmproot"

# Build RIST
cd "$BUILD_DIR"
meson librist --default-library both
ninja

# Prepare a package.
prepare-deb() {
    local pkg=$1
    rm -rf "$SYSROOT"
    mkdir -p "$SYSROOT/DEBIAN"
    sed -e "s/{{VERSION}}/$VERSION/g" -e "s/{{ARCH}}/$ARCH/g" "$SCRIPT_DIR/$pkg.control" >"$SYSROOT/DEBIAN/control"
    install -m 755 "$SCRIPT_DIR/$pkg.postinst" "$SYSROOT/DEBIAN/postinst"
}

# Build rist package
prepare-deb rist
mkdir -p "$SYSROOT/usr/bin"
install -m 755 tools/rist2rist tools/ristreceiver tools/ristsender tools/ristsrppasswd "$SYSROOT/usr/bin"
dpkg --build "$SYSROOT" "$INSTALLER_DIR"

# Build librist package    
prepare-deb librist
mkdir -p "$SYSROOT/usr/lib"
cp -d librist.so.*[0-9] "$SYSROOT/usr/lib"
chmod 755 "$SYSROOT"/usr/lib/librist.so*
dpkg --build "$SYSROOT" "$INSTALLER_DIR"

# Build librist-dev package    
prepare-deb librist-dev
mkdir -p "$SYSROOT/usr/lib" "$SYSROOT/usr/include/librist"
cp -d librist.so librist.a "$SYSROOT/usr/lib"
install -m 644 include/*.h include/librist/*.h librist/include/librist/*.h "$SYSROOT/usr/include/librist"
dpkg --build "$SYSROOT" "$INSTALLER_DIR"
