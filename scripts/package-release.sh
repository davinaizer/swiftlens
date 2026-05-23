#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dist_dir="$repo_root/dist"
arm64_archive="$dist_dir/swiftlens-macos-arm64.tar.gz"
version_file="$repo_root/Sources/SwiftLens/Version.generated.swift"
. "$repo_root/scripts/version-source.sh"

cleanup() {
    if [ -n "${tmpdirs:-}" ]; then
        for dir in $tmpdirs; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"
            fi
        done
    fi
}

trap cleanup EXIT HUP INT TERM

fail() {
    printf '%s\n' "swiftlens-package: $*" >&2
    exit 1
}

log() {
    printf '%s\n' "swiftlens-package: $*"
}

command -v swift >/dev/null 2>&1 || fail 'swift is required.'
command -v tar >/dev/null 2>&1 || fail 'tar is required.'
command -v mktemp >/dev/null 2>&1 || fail 'mktemp is required.'

release_version=$(git -C "$repo_root" describe --tags --exact-match 2>/dev/null || true)
[ -n "$release_version" ] || fail 'release packaging requires an exact git tag.'

generated_version=$(swiftlens_version_from_file "$version_file") || fail "missing generated version in $version_file"
[ "$generated_version" = "$release_version" ] || fail "version file ($generated_version) does not match git tag ($release_version)"

mkdir -p "$dist_dir"
rm -f "$dist_dir"/swiftlens-macos-*.tar.gz

log "packing release version: $release_version"
log 'running swift test'
CLANG_MODULE_CACHE_PATH=/private/tmp/swiftlens-cache swift test --package-path "$repo_root"

package_archive() {
    arch=$1
    triple=$2
    archive_path=$3

    log "building release binary for $arch"
    CLANG_MODULE_CACHE_PATH=/private/tmp/swiftlens-cache swift build --package-path "$repo_root" -c release --triple "$triple"

    bin_path="$repo_root/.build/${triple%%macosx*}macosx/release"
    binary_path=
    for candidate in "$bin_path/SwiftLens" "$bin_path/swiftlens"; do
        if [ -f "$candidate" ]; then
            binary_path=$candidate
            break
        fi
    done

    [ -n "$binary_path" ] || fail "missing release binary in $bin_path"

    staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/swiftlens-package.XXXXXX")
    tmpdirs="${tmpdirs:-} $staging_dir"
    cp "$binary_path" "$staging_dir/swiftlens"
    chmod 755 "$staging_dir/swiftlens"

    tar -czf "$archive_path" -C "$staging_dir" swiftlens

    contents=$(tar -tzf "$archive_path")
    if [ "$contents" != "swiftlens" ]; then
        printf '%s\n' "swiftlens-package: unexpected archive contents for $archive_path" >&2
        printf '%s\n' "$contents" >&2
        exit 1
    fi

    log "wrote $archive_path"
}

package_archive arm64 arm64-apple-macosx14.0 "$arm64_archive"

log 'release archive ready in dist/'
