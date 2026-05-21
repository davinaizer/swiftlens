# SwiftLens

SwiftLens detects SwiftUI architectural drift before it reaches code review or CI.

It uses deterministic syntax-tree heuristics instead of compiler-grade semantic reconstruction.

SwiftLens is designed for teams that want lightweight governance enforcement with machine-readable output.

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

### Swift Package Manager

```bash
git clone https://github.com/davinaizer/swiftlens.git
cd swiftlens
swift build -c release
```

## Quick Start

```bash
swiftlens
```

```bash
swiftlens scan
```

```bash
swiftlens scan Sources --format json
```

```bash
swiftlens validate-config
```

## Current CLI Contract

Supported commands:

```text
swiftlens
swiftlens scan
swiftlens validate-config
swiftlens version
swiftlens help
```

Supported flags:

```text
--config
--format
--path
--verbose
```

## Current Behavior

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

## What SwiftLens Detects

SwiftLens focuses on deterministic governance signals:

- path-boundary violations
- import/domain restrictions
- SwiftUI naming and location drift
- lightweight architectural heuristics
- configurable governance rule packs

## Example Configuration

```yaml
project:
packs:
rules:
```

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

## Current Status

| Phase    | Status     |
| -------- | ---------- |
| Phase 1  | Complete   |
| Phase 2  | Complete   |
| Phase 3A | Complete   |
| Phase 4  | Authorized |

Current implementation includes:

- deterministic rule registry
- built-in governance rules
- fixture-backed tests
- local-first developer DX
- machine-readable reporting

## Development

Run tests:

```bash
CLANG_MODULE_CACHE_PATH=/private/tmp/swiftlens-cache swift test
```

SwiftLens development is:

- governance-driven
- TDD-enforced
- phase-gated
- deterministic by contract

Additional architectural and governance documentation lives in [`docs/`](docs/).

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
