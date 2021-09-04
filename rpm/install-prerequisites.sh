#!/usr/bin/env bash
# Install prerequisites on rpm-based distros (Red Hat, CentOS, Fedora, Oracle, etc.)

[[ -n $(which dnf 2>/dev/null) ]] && DNF=dnf || DNF=yum
sudo $DNF install -y rpmdevtools meson libcmocka-devel cjson-devel mbedtls-devel
