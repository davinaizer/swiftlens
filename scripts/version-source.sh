#!/bin/sh

swiftlens_version_from_file() {
    version_file=$1
    version=$(
        sed -n 's/^    static let current = "\(.*\)"$/\1/p' "$version_file"
    )
    [ -n "$version" ] || return 1
    printf '%s\n' "$version"
}
