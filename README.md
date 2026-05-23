<p align="center">
  <picture >
    <source media="(prefers-color-scheme: dark)" srcset="docs/swiftlens-logo-horizontal-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="docs/swiftlens-logo-horizontal-light.png">
    <img alt="Fallback image description" src="docs/swiftlens-logo-horizontal-light.png">
  </picture>
</p>

**SwiftLens** detects SwiftUI architectural drift before it reaches code review or CI.

It uses deterministic syntax-tree heuristics instead of full semantic compiler analysis.

SwiftLens is designed for teams that want lightweight governance enforcement with machine-readable output.

SwiftLens currently targets Apple Silicon macOS environments.

## Why SwiftLens

Most Swift architecture tooling eventually becomes:

- semantic-heavy
- difficult to maintain
- slow to execute
- tightly coupled to compiler behavior

SwiftLens intentionally takes a narrower approach:

- syntax-tree-first heuristics
- deterministic findings
- CI-friendly JSON output
- lightweight governance enforcement
- explicit architectural boundaries

## Quick Example

```bash
swiftlens scan Sources --format json
```

```json
{
  "rule": "architecture.forbidden-import",
  "severity": "error",
  "path": "Features/Profile/ProfileView.swift",
  "reason": "Feature layer imports Infrastructure"
}
```

## Installation

### Release installer

Requirements:

- macOS
- Apple Silicon (`arm64`)
- Swift 6+

```bash
curl -fsSL https://raw.githubusercontent.com/davinaizer/swiftlens/main/scripts/install.sh | sh
```

This installs the release version defined in `Sources/SwiftLens/Version.generated.swift` by default. Set `SWIFTLENS_INSTALL_VERSION` if you need a different release.

```bash
swiftlens version
```

### Swift Package Manager fallback

```bash
git clone https://github.com/davinaizer/swiftlens.git
cd swiftlens
swift build -c release
```

## Quick Start

```bash
brew install swiftlens
```

```bash
swiftlens init
```

```bash
swiftlens preset list
```

```bash
swiftlens preset explain feature-modules
```

```bash
swiftlens pack list
```

```bash
swiftlens pack explain feature-isolation
```

```bash
swiftlens boundary list
```

```bash
swiftlens scan .
```

```bash
swiftlens scan Sources --format json
```

```bash
swiftlens baseline create
```

```bash
swiftlens scan . --baseline .swiftlens/baseline.json
```

```bash
swiftlens scan . --format json --baseline .swiftlens/baseline.json
```

```bash
swiftlens validate-config
```

## CLI

Supported commands:

```text
swiftlens
swiftlens scan
swiftlens baseline create
swiftlens validate-config
swiftlens init
swiftlens boundary list
swiftlens preset list
swiftlens preset explain <PRESET>
swiftlens pack list
swiftlens pack explain <PACK>
swiftlens rule explain <RULE-ID>
swiftlens version
swiftlens help
```

Supported flags:

```text
--config
--format
--baseline
--path
--verbose
```

## Boundary Inspection

SwiftLens can now inspect the effective boundary model without scanning source files.
The rendered sources are deterministic and use provenance labels such as `preset`, `pack: <id>`, and `explicit-config`.

Workflow:

1. Initialize or load a local config.
2. Run `swiftlens boundary list`.
3. Compare the rendered preset, ignore paths, and boundary scopes with the intended architecture.

Examples:

```bash
swiftlens init --preset feature-modules
swiftlens boundary list
swiftlens boundary list --config .swiftlens.yml
swiftlens preset explain feature-modules
```

Example output:

```text
Project Boundaries

Preset:
- feature-modules

Ignored Paths:
- .build/
- .swiftpm/
- DerivedData/

Boundaries:
- App/
  Source:
    - preset
  Allows:
    - Features/*
    - Shared/*
    - Core/*

- Features/
  Source:
    - pack: feature-isolation
  Restricted Imports:
    - Features/*

- Shared/
  Source:
    - pack: shared-boundaries
  Restricted Imports:
    - Features/*

- Core/
  Source:
    - pack: shared-boundaries
  Restricted Imports:
    - Features/*
```

This view is intentionally lightweight:

- it is local-only
- it is deterministic
- it does not infer ownership or dependency graphs
- it reflects preset defaults plus explicit config only
- preset defaults are composed from built-in rule packs internally

## Rule Packs

SwiftLens ships built-in rule packs as deterministic composition units.

- packs are local-only and static
- packs are not user-defined in `.swiftlens.yml`
- presets compose packs internally and then expand to rules
- `swiftlens pack list` and `swiftlens pack explain <PACK>` inspect the built-in pack registry

Current built-in packs:

- `feature-isolation`
- `shared-boundaries`
- `app-shell`
- `domain-ui-separation`
- `dependency-direction`

## Preset Debugging

Preset inspection is useful when onboarding or when a config override changes the expected boundary surface.

Typical flow:

```bash
swiftlens preset list
swiftlens preset explain feature-modules
swiftlens pack explain feature-isolation
swiftlens boundary list --config .swiftlens.yml
```

Use `swiftlens preset explain <PRESET>` to inspect the built-in preset intent, `swiftlens pack explain <PACK>` to inspect the underlying composition units, then use `swiftlens boundary list` to inspect the effective boundary state after local config overrides and ignore paths are applied.

## Behavior Guarantees

| Capability          | Behavior                                   |
| ------------------- | ------------------------------------------ |
| Default scan target | `.`                                        |
| Default format      | `json`                                     |
| Config resolution   | cwd-local `.swiftlens.yml` only            |
| Config precedence   | explicit `--config` overrides local lookup |
| Exit code `0`       | success                                    |
| Exit code `1`       | rule violations                            |
| Exit code `2`       | config or usage error                      |
| Exit code `3`       | internal failure                           |

## Incremental Adoption

SwiftLens baselines support gradual rollout in existing repositories without changing the rule model.

Workflow:

1. Capture the current violation set as a local baseline.
2. Keep the baseline under version control or in the repo workspace.
3. Run scans against the baseline to report only regressions.
4. Fix new violations without being blocked by legacy debt.

Example:

```bash
swiftlens baseline create
swiftlens scan . --baseline .swiftlens/baseline.json
```

Baseline behavior is deterministic and local-only:

- baseline files are created from the current scan result
- scan filtering suppresses only exact fingerprint matches
- stale baseline entries are ignored for MVP
- baseline filtering does not waive rules or alter rule semantics

## What SwiftLens Detects

SwiftLens focuses on deterministic governance signals:

- path-boundary violations
- import/domain restrictions
- SwiftUI naming and location drift
- lightweight architectural heuristics
- built-in governance rule packs

## Configuration

SwiftLens reads `.swiftlens.yml` from the current working directory unless you pass `--config`.

Supported top-level keys:

- `project`
- `rules`
- `architecture`
- `ignore`

Supported `project` fields:

- `path`
- `include`
- `exclude`

Built-in rule packs are not user-configurable in `.swiftlens.yml`.
Inspect them with:

- `swiftlens pack list`
- `swiftlens pack explain <PACK>`

Supported `rules` forms:

- ordered enablement list, for example `rules: [architecture.forbidden-import]`
- legacy keyed rule configuration, including `ForbiddenImportRule` as a compatibility alias

Supported `architecture` fields:

- `forbiddenImports`

Supported `ignore` fields:

- `paths`

Example configuration:

```yaml
project:
  path: .
  include: []
  exclude:
    - .build/**
    - .swiftlens-bin/**
    - dist/**
    - DerivedData/**
rules:
  - architecture.forbidden-import
architecture:
  forbiddenImports:
    - from: Features/
      imports:
        - UIKit
ignore:
  paths:
    - DerivedData/
```

For the full schema and validation contract, see:

- [`docs/config-schema.md`](docs/config-schema.md)
- [`docs/config-validation.md`](docs/config-validation.md)

## Architecture Principles

SwiftLens is intentionally:

- deterministic
- syntax-tree-first
- phase-gated
- CI-compatible
- lightweight by design

## Non-Goals

SwiftLens is intentionally not:

- a semantic compiler analyzer
- a generalized Swift linter
- a plugin platform
- an IDE automation tool
- an architecture visualization system
- an AI coding assistant

## Development

Run tests:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/swiftlens-cache swift test
```

Run SwiftLint:

```bash
swiftlint lint
```

Link a local build into a repo-local shim directory so it wins on `PATH`:

```bash
./scripts/dev-link.sh link
export PATH="$PWD/.swiftlens-bin:$PATH"
swiftlens --version
```

Remove the local shim:

```bash
./scripts/dev-link.sh unlink
```

SwiftLens development is:

- governance-driven
- TDD-enforced
- phase-gated
- deterministic by contract

Additional architectural and governance documentation lives in [`docs/`](docs/).

## Maintainer Release Guide

Prerequisites:

- Swift toolchain
- `tar`
- authenticated `gh` (`gh auth login`)

1. Pick the release version, write the release version source, and tag it:

```bash
./scripts/write-release-version-source.sh vX.Y.Z
git add Sources/SwiftLens/Version.generated.swift
git commit -m "chore: prepare vX.Y.Z"
git tag vX.Y.Z
```

2. Build and validate the macOS Apple Silicon archive locally:

```bash
./scripts/package-release.sh
```

This creates:

- `dist/swiftlens-macos-arm64.tar.gz`

SwiftLens release artifacts currently target Apple Silicon macOS only.

3. Upload the archive to the GitHub release:

```bash
./scripts/upload-release.sh vX.Y.Z
```

To verify the upload flow first:

```bash
./scripts/upload-release.sh vX.Y.Z --dry-run
```

Publish the GitHub release as a normal release, not a pre-release, so the installer URL resolves correctly.

4. Installers can then fetch the asset with:

```bash
curl -fsSL https://raw.githubusercontent.com/davinaizer/swiftlens/main/scripts/install.sh | sh
```

## Repository Layout

```text
swiftlens/
├── Sources/
├── Tests/
├── docs/
├── examples/
├── scripts/
└── README.md
```

## Contributing

Contributions must preserve:

- deterministic behavior
- lightweight architecture
- syntax-tree-first analysis
- phase contract compliance

Review repository governance documents before contributing.

## License

MIT
