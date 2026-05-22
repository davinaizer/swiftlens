#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dist_dir="$repo_root/dist"

cd "$repo_root"

fail() {
    printf '%s\n' "swiftlens-upload: $*" >&2
    exit 1
}

log() {
    printf '%s\n' "swiftlens-upload: $*"
}

usage() {
    cat >&2 <<'EOF'
Usage: scripts/upload-release.sh <tag> [--dry-run]
EOF
    exit 1
}

command -v gh >/dev/null 2>&1 || fail 'gh is required.'

gh auth status >/dev/null 2>&1 || fail 'gh is not authenticated.'

tag=
dry_run=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            dry_run=1
            ;;
        -*)
            usage
            ;;
        *)
            if [ -n "$tag" ]; then
                usage
            fi
            tag=$arg
            ;;
    esac
done

[ -n "$tag" ] || usage

arm64_archive="$dist_dir/swiftlens-macos-arm64.tar.gz"

[ -f "$arm64_archive" ] || fail "missing archive: $arm64_archive"

release_exists=0
if gh release view "$tag" >/dev/null 2>&1; then
    release_exists=1
fi

create_release() {
    if [ "$release_exists" -eq 1 ]; then
        log "release exists: $tag"
        return 0
    fi

    if [ "$dry_run" -eq 1 ]; then
        log "dry run: gh release create $tag --title $tag --generate-notes"
        return 0
    fi

    log "creating release: $tag"
    gh release create "$tag" --title "$tag" --generate-notes
}

upload_assets() {
    if [ "$dry_run" -eq 1 ]; then
        log "dry run: gh release upload $tag $arm64_archive --clobber"
        return 0
    fi

    log "uploading archive to $tag"
    gh release upload "$tag" "$arm64_archive" --clobber
}

create_release
upload_assets

log 'release upload complete'
