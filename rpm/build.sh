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
#  This script builds the RIST packages on rpm-based distros
#  (Red Hat, CentOS, Fedora, Oracle, etc.)
#
#-----------------------------------------------------------------------------

source $(dirname "$0")/../include.sh

# RPM build environment.
RPMBUILDROOT="$HOME/rpmbuild"
[[ -d "$RPMBUILDROOT" ]] || rpmdev-setuptree

# Get distro description.
if [[ -e /etc/fedora-release ]]; then
    DISTRO=$(grep " release " /etc/fedora-release 2>/dev/null | sed -e 's/^.* release \([0-9]*\).*$/\1/')
    [[ -n "$DISTRO" ]] && DISTRO=".fc$DISTRO"
elif [[ -e /etc/redhat-release ]]; then
    DISTRO=$(grep " release " /etc/redhat-release 2>/dev/null | sed -e 's/^.* release \([0-9]*\).*$/\1/')
    [[ -n "$DISTRO" ]] && DISTRO=".el$DISTRO"
else
    DISTRO=
fi

# Adjust version numbering for RPM.
VERSION=${VERSION//-/.}
RELEASE=1
RPM_VERSION=${VERSION}-${RELEASE}${DISTRO}

# Build source tarball.
TARFILE="$BUILD_DIR/librist-$VERSION.tgz"
tar -C "$BUILD_DIR" -czf "$TARFILE" -p --owner=0 --group=0 --exclude .git --transform "s|^librist/|librist-$VERSION/|" librist
cp -f "$TARFILE" "$RPMBUILDROOT/SOURCES/"

# Build binary rpm's
rpmbuild -ba --clean -D "version $VERSION" -D "release $RELEASE" -D "distro $DISTRO" "$SCRIPT_DIR/librist.spec" || exit 1
cp -uf "$RPMBUILDROOT"/RPMS/*/librist-$RPM_VERSION.*.rpm "$INSTALLER_DIR"
cp -uf "$RPMBUILDROOT"/SRPMS/librist-$RPM_VERSION.src.rpm "$INSTALLER_DIR"
