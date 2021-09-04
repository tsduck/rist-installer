#!/usr/bin/env bash
# Common code for deb/build.sh and rpm/build.sh.

SCRIPT=$(basename ${BASH_SOURCE[1]})
error() { echo >&2 "$SCRIPT: $*"; exit 1; }
usage() { echo >&2 "invalid command, try \"$SCRIPT --help\""; exit 1; }

# Local directories.
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[1]}); pwd)
ROOT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
BUILD_DIR="$ROOT_DIR/build"
REPO_DIR="$BUILD_DIR/librist"
INSTALLER_DIR="$ROOT_DIR/installers"

# URL of git repository.
REPO_URL=$(grep -v -e '^ *$' -e '^ *#' "$ROOT_DIR/URL.txt" | tail -1)

# Display help text
showhelp()
{
    cat >&2 <<EOF

Build the RIST library installers.

Usage: $SCRIPT [options]

Options:

  -b
  --bare-version
      Use the "bare version" number from librist, without commit id if there
      is no tag on the current commit. By default, use a detailed version
      number (most recent version, number of commits since then and short
      commit hash).

  --clean
      Cleanup the build directory and exit.

  --help
      Display this help text.

  --no-build
      Do not rebuild RIST library and tools. Assume that they are already
      built. Only build the installers.

  --no-git
      Do not clone or update the librist repository. Assume it is already
      up to date and use the current state.

  -t name
  --tag name
     Specify the git tag or commit to build. By default, use the latest
     repo state.

EOF
    exit 1
}

# Decode command line arguments
BARE_VERSION=false
CLEANUP=false
REBUILD=true
GIT_UPDATE=true
TAG=

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--bare*)
            BARE_VERSION=true
            ;;
        --clean)
            CLEANUP=true
            ;;
        --help)
            showhelp
            ;;
        --no-build)
            REBUILD=false
            ;;
        --no-git)
            GIT_UPDATE=false
            ;;
        -t|--tag)
            [[ $# -gt 1 ]] || usage; shift
            TAG=$1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Process cleanup command.
if $CLEANUP; then
    rm -rf "$BUILD_DIR"
    exit 0
fi

# Create local build directories.
mkdir -p "$BUILD_DIR" "$INSTALLER_DIR"

# Clone repository or update it.
if $GIT_UPDATE; then
    if [[ -d "$REPO_DIR/.git" ]]; then
        echo "Updating repository ..."
        (cd "$REPO_DIR"; git checkout master && git pull origin master)
    else
        echo "Cloning $REPO_URL ..."
        git clone "$REPO_URL" "$REPO_DIR"
        [[ -d "$REPO_DIR/.git" ]] || error "failed to clone $REPO_URL"
    fi
    if [[ -n "$TAG" ]]; then
        echo "Checking out $TAG ..."
        (cd "$REPO_DIR"; git checkout "$TAG")
    fi
fi

# Get librist version
if $BARE_VERSION; then
    VERSION=$(cd "$REPO_DIR"; git describe --tags | sed -e 's/^v//' -e 's/-g.*//')
else
    VERSION=$(cd "$REPO_DIR"; git describe --tags | sed -e 's/^v//' -e 's/-g/-/')
fi
[[ -n "$VERSION" ]] || error "RIST version not found"
echo "RIST version is $VERSION"
