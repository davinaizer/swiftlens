#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

link_dir=${SWIFTLENS_DEV_LINK_DIR:-"$repo_root/.swiftlens-bin"}
build_config=${SWIFTLENS_DEV_LINK_CONFIG:-release}
binary_name='SwiftLens'
link_name='swiftlens'
target_path="$repo_root/.build/$build_config/$binary_name"
link_path="$link_dir/$link_name"

log() {
    printf '%s\n' "swiftlens-dev-link: $*"
}

fail() {
    printf '%s\n' "swiftlens-dev-link: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  scripts/dev-link.sh link
  scripts/dev-link.sh unlink

Environment:
  SWIFTLENS_DEV_LINK_DIR   Directory that will contain the shim (default: ./.swiftlens-bin)
  SWIFTLENS_DEV_LINK_CONFIG Build configuration to link (default: release)
EOF
}

ensure_build() {
    command -v swift >/dev/null 2>&1 || fail 'swift is required.'
    log "building $build_config target"
    (cd "$repo_root" && swift build -c "$build_config")
}

link_binary() {
    ensure_build
    [ -f "$target_path" ] || fail "built binary not found at $target_path"

    mkdir -p "$link_dir"
    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
        fail "link path already exists and is not a symlink: $link_path"
    fi

    ln -sfn "$target_path" "$link_path"
    log "linked $link_path -> $target_path"
    log "prepend $link_dir to PATH to prefer the local build"
}

unlink_binary() {
    if [ -L "$link_path" ] || [ -e "$link_path" ]; then
        rm -f "$link_path"
        log "removed $link_path"
    else
        log "no link found at $link_path"
    fi

    rmdir "$link_dir" 2>/dev/null || true
}

case "${1:-link}" in
    link)
        link_binary
        ;;
    unlink)
        unlink_binary
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        fail "unknown command: $1"
        ;;
esac
