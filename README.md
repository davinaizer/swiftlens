# SwiftLens

SwiftLens is a deterministic SwiftUI governance CLI for detecting architectural drift before changes reach review or CI.

It is syntax-tree-first, CI-compatible, and designed for machine-readable findings.

SwiftLens intentionally stops short of compiler-grade architectural analysis.

## What SwiftLens Is

- a deterministic SwiftUI governance CLI
- a syntax-tree-first analysis tool
- a governance drift detector
- a CI-compatible machine-readable reporter

## What SwiftLens Is Not

- an AI coding assistant
- a Copilot competitor
- a generalized Swift linter
- a semantic compiler tool
- a plugin platform
- a SaaS governance product
- an architecture visualization platform

## Governance Doctrine

Features that require semantic reconstruction, inferred architectural truth, runtime understanding, or persistent graph infrastructure are out of scope for SwiftLens V1 and should be rejected by default.

## Design Philosophy

- deterministic over intelligent
- heuristics over semantic reconstruction
- maintainability over completeness
- explicit constraints over extensibility
- OSS realism over enterprise ambition

## Non-Goals

- semantic correctness guarantees
- full architecture reconstruction
- code generation
- auto-remediation
- deep dependency intelligence
- enterprise workflow orchestration
- runtime instrumentation

## What it does

- Detects SwiftUI architectural drift
- Flags governance drift using deterministic heuristics
- Enforces project-specific governance through configurable rule packs
- Produces deterministic machine-readable output for CI and AI agents
- Emits Markdown summaries for reviewers when requested

## V1 rule packs

SwiftLens V1 treats these packs as required:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

V1 is complete only when all required packs are implemented and validated.
V1 uses built-in packs only; external pack surfaces are deferred.

## V1 command contract

Expected CLI surface:

```text
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

Expected output formats:

- `json`
- `yaml`
- `markdown`
- `compact`

## Configuration

SwiftLens reads `.swiftlens.yml`.

Minimum schema shape:

```yaml
project:
packs:
rules:
```

Documented config behavior:

- built-in rule defaults provide the base severity and config
- `packs.<pack>.severityOverrides` overrides built-in severity for rules in that pack
- `rules.<rule>.severity` overrides both built-in severity and pack-level overrides
- `rules.<rule>.config` merges over built-in rule config
- unknown keys fail validation
- CLI flags affect scope and reporter selection only
- findings are advisory deterministic signals, not semantic guarantees
- rules should prefer low-complexity heuristics over deep inference
- route discovery is limited to declared or static routes only
- ownership mapping is explicit-config only

## Reporter contract

Each violation should include:

- stable rule ID
- pack name
- severity
- confidence
- file path
- source range
- reason
- `fixPattern`

## Planned repository layout

```text
swiftlens/
├── Package.swift
├── Sources/
│   └── SwiftLensCLI/
├── Tests/
│   └── SwiftLensTests/
├── docs/
├── examples/
├── scripts/
└── README.md
```

## Roadmap

Phase 1:

- CLI bootstrap
- config loading
- SwiftSyntax traversal
- file discovery

Phase 2:

- deterministic rule registry
- stable rule IDs
- rule execution pipeline

Phase 3:

- syntax/path/import governance rules
- ownership mapping heuristics
- shallow dependency checks

Phase 4:

- JSON/YAML reporters
- CI exit codes
- fixture-based testing

Phase 5:

- documentation hardening
- governance pack stabilization
- OSS maintenance readiness

## Current status

The project is still in the planning and bootstrap stage. The docs define the V1 contract, but the CLI implementation is not complete yet.
