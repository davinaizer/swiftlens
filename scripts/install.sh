#!/bin/sh

set -eu

repo_owner='davinaizer'
repo_name='swiftlens'
binary_name='swiftlens'

log() {
    printf '%s\n' "swiftlens-install: $*"
}

fail() {
    printf '%s\n' "swiftlens-install: $*" >&2
    exit 1
}

cleanup() {
    if [ -n "${tmpdir:-}" ] && [ -d "$tmpdir" ]; then
        rm -rf "$tmpdir"
    fi
}

trap cleanup EXIT HUP INT TERM

command -v curl >/dev/null 2>&1 || fail 'curl is required.'
command -v tar >/dev/null 2>&1 || fail 'tar is required.'
command -v mktemp >/dev/null 2>&1 || fail 'mktemp is required.'
command -v uname >/dev/null 2>&1 || fail 'uname is required.'

os_name=$(uname -s)
case "$os_name" in
    Darwin)
        ;;
    *)
        fail "unsupported operating system: $os_name"
        ;;
esac

arch_name=$(uname -m)
case "$arch_name" in
    arm64|x86_64)
        ;;
    *)
        fail "unsupported architecture: $arch_name"
        ;;
esac

release_url="https://github.com/$repo_owner/$repo_name/releases/latest/download/swiftlens-macos-$arch_name.tar.gz"

resolve_install_dir() {
    candidate=$1
    if mkdir -p "$candidate" 2>/dev/null && [ -w "$candidate" ]; then
        printf '%s\n' "$candidate"
        return 0
    fi
    return 1
}

if [ -n "${SWIFTLENS_INSTALL_DIR:-}" ]; then
    if install_dir=$(resolve_install_dir "$SWIFTLENS_INSTALL_DIR"); then
        :
    else
        fail "cannot use SWIFTLENS_INSTALL_DIR=$SWIFTLENS_INSTALL_DIR"
    fi
else
    if [ -n "${HOME:-}" ] && install_dir=$(resolve_install_dir "$HOME/.local/bin"); then
        :
    elif install_dir=$(resolve_install_dir /usr/local/bin); then
        :
    else
        fail 'no writable install directory found.'
    fi
fi

log "using install directory: $install_dir"
log "downloading release: $release_url"

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/swiftlens-install.XXXXXX")
archive_path="$tmpdir/swiftlens.tar.gz"
extract_dir="$tmpdir/extract"
mkdir -p "$extract_dir"

curl -fsSL "$release_url" -o "$archive_path"

tar -xzf "$archive_path" -C "$extract_dir"

set -- "$extract_dir"/*
if [ "$1" = "$extract_dir/*" ]; then
    fail 'release archive did not contain any files.'
fi
if [ "$#" -ne 1 ]; then
    fail 'release archive must contain exactly one top-level file.'
fi

artifact=$1
artifact_name=${artifact##*/}

if [ "$artifact_name" != "$binary_name" ]; then
    fail "expected top-level executable named $binary_name, found $artifact_name"
fi
if [ ! -f "$artifact" ]; then
    fail "release artifact is not a regular file: $artifact_name"
fi

chmod 755 "$artifact"
mv -f "$artifact" "$install_dir/$binary_name"

version_output=$("$install_dir/$binary_name" version)

log "installed binary: $install_dir/$binary_name"
log "verified version: $version_output"

case ":${PATH:-}:" in
    *":$install_dir:"*)
        ;;
    *)
        log "add $install_dir to PATH to run swiftlens without the full path."
        ;;
esac
