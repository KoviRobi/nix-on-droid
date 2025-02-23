#!@bash@/bin/bash

# This is a script to run "on-device" tests in CI, without the device.
# Takes the bootstrap aarch64 zipball, unpacks, proots into it.
# This won't catch all bugs, of course, but that's something.

# Set up envvars, prepare directories:

set -ueo pipefail

PATH=@path@

USE_FLAKE="${USE_FLAKE:-0}"
if [[ ! "$USE_FLAKE" =~ ^[01]$ ]]; then
    echo "USE_FLAKE environment variable needs to be either 0 or 1, got '$USE_FLAKE'."
    exit 1
fi

# this allows to run this script from every place in this git repo
REPO_DIR="$(git rev-parse --show-toplevel)"

INJ_DIR="$REPO_DIR/.fakedroid/inj"
ENV_DIR="$REPO_DIR/.fakedroid/env/$USE_FLAKE"

QEMU_URL="https://github.com/multiarch/qemu-user-static/releases/download/v7.1.0-2/qemu-aarch64-static"
QEMU="$INJ_DIR/qemu-aarch64"

INSTALLATION_DIR="@installationDir@"
TARGET_HOME="@homeDir@"

mkdir -p "$INJ_DIR"
mkdir -p "$ENV_DIR/"{"$INSTALLATION_DIR","$TARGET_HOME",n-o-d}

export PROOT_TMP_DIR="$ENV_DIR/$INSTALLATION_DIR/proot/tmp"
export PROOT_L2S_DIR="$ENV_DIR/$INSTALLATION_DIR/proot/l2s"
mkdir -p "$PROOT_TMP_DIR" "$PROOT_L2S_DIR"

PASSTHROUGH_VARS=(
    "PROOT_TMP_DIR=$PROOT_TMP_DIR"
    "PROOT_L2S_DIR=$PROOT_L2S_DIR"
    "TERM=$TERM"
    "HOME=$TARGET_HOME"
    "USER=$USER"
    "USE_FLAKE=$USE_FLAKE"
)

[[ -n "${CACHIX_SIGNING_KEY:-}" ]] && \
    PASSTHROUGH_VARS+=("CACHIX_SIGNING_KEY=$CACHIX_SIGNING_KEY")

PROOT_ARGS=(
    "-r" "$ENV_DIR"
    "-q" "$QEMU"
    "-w" "$TARGET_HOME"
    "-b" "$ENV_DIR/$INSTALLATION_DIR/nix:/nix"
    "-b" "$ENV_DIR/$INSTALLATION_DIR/bin:/bin"
    "-b" "$ENV_DIR/$INSTALLATION_DIR/etc:/etc"
    "-b" "$ENV_DIR/$INSTALLATION_DIR/tmp:/tmp"
    "-b" "$ENV_DIR/$INSTALLATION_DIR/usr:/usr"
    "-b" "/dev"
    "-b" "/proc"
    "-b" "/sys"
    "--link2symlink"
)


# Procure a static QEMU for user emulation and a proot with our patches:

[[ -e "$QEMU" ]] || wget "$QEMU_URL" -O "$QEMU"
chmod +x "$QEMU"

PROOT="@prootTest@/bin/proot"


# Do the first install if not installed yet:

if [[ ! -e "$ENV_DIR/$INSTALLATION_DIR/etc" ||
        -e "$ENV_DIR/$INSTALLATION_DIR/etc/UNINITIALIZED" ]]; then
    # Build a zipball:
    ZIPBALL="@bootstrapZip@/bootstrap-aarch64.zip"
    # Unpack the zipball the way the Android app does it:
    pushd "$ENV_DIR/$INSTALLATION_DIR"
        unzip "$ZIPBALL"
        chmod -R u+rw .  # unzip results in -r-xr-xr-x files and directories
        while read -r e; do
            SYM_TGT="${e%%←*}"
            SYM_SRC="${e##*←}"
            ln -sf "$SYM_TGT" "$SYM_SRC"
        done < SYMLINKS.txt
        while read -r e; do
            chmod +x "$e"
        done < EXECUTABLES.txt
        rm SYMLINKS.txt EXECUTABLES.txt
    popd
fi


# Inject Nix-on-Droid version under test into the environment.
# Uncommitted chages won't be picked up, just HEAD.
# /n-o-d/archive.tar.gz is used as a channel, /n-o-d/unpacked --- as a flake.

rm -rf "$ENV_DIR/n-o-d"
mkdir -p "$ENV_DIR/n-o-d/unpacked"
git -C "$REPO_DIR" archive --format=tar --prefix n-o-d/ HEAD \
    > "$ENV_DIR/n-o-d/archive.tar"
tar --strip-components=1 -xf \
    "$ENV_DIR/n-o-d/archive.tar" -C "$ENV_DIR/n-o-d/unpacked"
gzip "$ENV_DIR/n-o-d/archive.tar"


# The 'first boot' proot invocation:

SH="$(readlink "$ENV_DIR/$INSTALLATION_DIR/bin/sh")"

# 'first boot' execs interactive bash unconditionally;
# makes sense on device, requires us to work around it here though
env -i "${PASSTHROUGH_VARS[@]}" "$PROOT" "${PROOT_ARGS[@]}" \
    "$INSTALLATION_DIR/$SH" "${INSTALLATION_DIR}/usr/lib/login-inner" <<<'echo OK'

# this is usually done by login on 'first reboot'
[[ -e "$ENV_DIR/$INSTALLATION_DIR/usr/lib/.login-inner.new" ]] &&
    mv "$ENV_DIR/$INSTALLATION_DIR/usr/lib/.login-inner.new" \
        "$ENV_DIR/${INSTALLATION_DIR}/usr/lib/login-inner"


# Actually execute something inside that fakedroid environment:

env -i "${PASSTHROUGH_VARS[@]}" "$PROOT" "${PROOT_ARGS[@]}" \
    "$INSTALLATION_DIR/$SH" "$INSTALLATION_DIR/usr/lib/login-inner" "$@"
