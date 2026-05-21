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
- an IDE integration

## Repository-Governed Development Model

- Repository docs govern implementation.
- Prompts only initiate work.
- Prompts cannot redefine architecture.
- Prompts cannot bypass the phase contract.
- Phase transitions are documented in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).
- Current phase identification is required before implementation.
- Out-of-phase requests are rejected, not reprioritized.

## Testing Doctrine

- TDD is the default implementation standard from Phase 2 onward.
- Phase 1 remains accepted as already implemented.
- Write or update failing tests first.
- Implement the smallest code change.
- Run the relevant test target.
- Refactor only after tests pass.
- Preserve deterministic behavior.
- Tests validate externally observable deterministic behavior, not implementation structure.
- New rules require fixtures before implementation.
- Reporter changes require golden-output tests.
- Config changes require valid and invalid config tests.
- Exit-code changes require explicit exit-code tests.
- Tests must remain fixture-backed for file- or project-dependent behavior.
- Tests must avoid network, clock, randomness, external services, and machine-local state.
- Tests must verify stable rule IDs, finding shape, ordering, and exit codes where applicable.
- `swift test` must pass before merge, phase closure, rule additions, config changes, and reporter changes.

| Change Type | Required Test |
| --- | --- |
| New rule | New fixtures plus a failing test first |
| Reporter change | Golden-output test |
| Config schema change | Valid and invalid config tests |
| Exit-code change | Explicit exit-code test |
| CLI parsing change | Argument validation tests |

## Phased Implementation Philosophy

- Start with the smallest deterministic surface.
- Prefer direct orchestration in early phases.
- Add abstractions only when repetition proves they are operationally necessary.
- Defer sophistication until the repo demonstrates repeated need.
- Reject speculative future-proofing.
- Reject premature extensibility.

## Complexity Escalation Policy

- If a concept appears once, keep it concrete.
- If a concept appears repeatedly across fixtures or modules, consider a small abstraction.
- Do not introduce protocol hierarchies unless they remove operational duplication or enforce a real invariant.
- Do not add generalized frameworks to solve a phase-local problem.

## Non-Goals

- semantic correctness guarantees
- full architecture reconstruction
- code generation
- auto-remediation
- deep dependency intelligence
- enterprise workflow orchestration
- runtime instrumentation
- platformization

## What It Does

- Detects SwiftUI architectural drift
- Flags governance drift using deterministic heuristics
- Enforces project-specific governance through configurable rule packs
- Produces deterministic machine-readable output for CI and AI agents
- Emits Markdown summaries for reviewers when requested

## V1 Rule Packs

SwiftLens V1 treats these packs as required:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

V1 is complete only when all required packs are implemented and validated.
V1 uses built-in packs only; external pack surfaces are deferred.

## V1 Command Contract

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

Phase 1 only implements the `json` reporter. Other formats remain deferred until the phase contract explicitly admits them.

## Local Developer DX

SwiftLens includes a narrow local-only execution path for deterministic day-to-day use.

Examples:

```bash
swiftlens
swiftlens scan
swiftlens scan --config .swiftlens.yml --format json
swiftlens validate-config --config .swiftlens.yml
```

Behavior:

- `swiftlens` defaults to `scan .`
- `swiftlens scan` defaults to `.`
- omitted `--config` resolves `.swiftlens.yml` from the current working directory only
- explicit `--config` overrides local lookup
- omitted `--format` defaults to `json`
- missing config exits with code `2`

This is local deterministic DX, not IDE integration, platform integration, workspace discovery, or autofix.

## Phase 1 Usage

```bash
swiftlens scan --config .swiftlens.yml --format json
swiftlens validate-config --config .swiftlens.yml
swiftlens version
swiftlens help
```

`scan` returns exit code `1` when `ForbiddenImportRule` emits a violation, `2` for configuration or usage errors, and `3` for internal failures.

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

## Reporter Contract

Each violation should include:

- stable rule ID
- pack name
- severity
- confidence
- file path
- source range
- reason
- `fixPattern`

## Planned Repository Layout

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

## Phase Summary

The authoritative phase contract lives in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).

- Phase 1 establishes the CLI bootstrap, SwiftSyntax parsing, one deterministic rule, JSON output, exit codes, and fixture tests.
- Later phases add only the capabilities explicitly allowed by the repository phase contract.
- Prompts cannot skip ahead to semantic, platform, compiler, or plugin ambitions.

## Current Status

Phase 2 rule infrastructure is implemented, Phase 3A local developer DX is the current admitted phase, and Phase 4 remains blocked until explicit phase-transition authorization is granted.
