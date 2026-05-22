# SwiftLens macOS release installer

## Summary

- Add a POSIX `scripts/install.sh` that installs the latest macOS release binary without sudo or source builds.
- Update `README.md` so the release installer is the primary install path, with SwiftPM build as the fallback.

## Implementation Changes

- `scripts/install.sh`
  - Use `#!/bin/sh` with fail-fast error handling and temp-dir cleanup via `trap`.
  - Detect `uname -s` and `uname -m`; support only `Darwin` plus `arm64` and `x86_64`.
  - Resolve the install target in this order: `SWIFTLENS_INSTALL_DIR` if set, then `$HOME/.local/bin` if writable or creatable, then `/usr/local/bin` if writable.
  - Download the latest release asset from GitHub using the deterministic `releases/latest/download` URL pattern.
  - Use the macOS asset names `swiftlens-macos-arm64.tar.gz` and `swiftlens-macos-x86_64.tar.gz`.
  - Download into a temporary directory, extract there, verify the archive yields a single `swiftlens` executable, then move it into place.
  - Replace only the `swiftlens` file at the target path; do not touch other files in the directory.
  - Make the installed binary executable.
  - Verify installation by running the installed binary directly with `"$install_dir/swiftlens" version` so the check cannot accidentally resolve another `swiftlens` earlier on `PATH`.
  - Print concise, deterministic status messages and a clear PATH follow-up if the chosen install dir is not already on PATH.
  - Reject unsupported OS/arch combinations with a clear error.
  - Fail hard if the release asset is missing; do not fall back to source builds.
  - Do not use sudo, do not modify shell profiles, and do not add checksum logic in this task.
- `README.md`
  - Put the installer command first in the Installation section.
  - Keep a manual SwiftPM fallback:
    - `git clone https://github.com/davinaizer/swiftlens.git`
    - `cd swiftlens`
    - `swift build -c release`
  - Add a short note that `$HOME/.local/bin` must be on `PATH` if users install there.
  - Keep the installation wording concise and OSS-facing.

## Validation

- Run `sh -n scripts/install.sh`.
- Run `CLANG_MODULE_CACHE_PATH=/private/tmp/swiftlens-cache swift test`.
- Current workspace baseline: `swift test` already passes before any changes.
- After implementation, re-run both checks and confirm the installer reaches `swiftlens version` by invoking the installed binary path directly.

## Assumptions

- GitHub Releases will publish the two tarballs above for the latest release.
- Each archive will contain a single top-level executable named `swiftlens`.
- No checksum files exist yet, so checksum verification stays out of scope.
- If release assets or release automation are not in place yet, the installer will fail with a useful message rather than trying to build from source.
