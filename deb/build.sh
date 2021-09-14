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
rm -rf "$SYSROOT"
mkdir -p "$SYSROOT/DEBIAN"
sed -e "s/{{VERSION}}/$VERSION/g" -e "s/{{ARCH}}/$ARCH/g" "$SCRIPT_DIR/librist.control" >"$SYSROOT/DEBIAN/control"

# Build RIST
meson setup --buildtype release --default-library both --prefix "$SYSROOT/usr" "$BUILD_DIR" "$REPO_DIR"
ninja install -C "$BUILD_DIR"

# Adjust file protections.
chmod 0644 $(find "$SYSROOT" -type f)
chmod 0755 $(find "$SYSROOT" -type f) "$SYSROOT"/usr/bin/rist*

# Build rist package
fakeroot dpkg --build "$SYSROOT" "$INSTALLER_DIR"
