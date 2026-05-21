# Architecture Guardrails

## Purpose

Define the module boundaries that keep SwiftLens deterministic, testable, and phase-safe.

## Approved Shape

- `CLI.swift` owns command parsing and process exit behavior.
- `ScanEngine.swift` owns scan orchestration.
- `ConfigLoader.swift` owns config validation and project-root resolution.
- `Parser.swift` owns SwiftSyntax parsing and import extraction.
- `RuleRegistry.swift` owns rule registration, enablement, and precedence resolution.
- `Reporter.swift` owns serialization only.
- `Tests/SwiftLensTests` may inject custom registries and fixtures, but it must not depend on production-only coupling to prove a test.

## Boundary Rules

- Dependencies flow inward from CLI and orchestration into parser, config, and rules.
- Rules may inspect parsed source records and resolved settings only.
- Rules must not call back into CLI, filesystem discovery, or reporters.
- Reporters must not perform analysis or discovery.
- Config loading must not inspect rule implementation details beyond the registry contract.
- Parsing must stay syntax-first; no semantic type resolution, build execution, or runtime inspection is permitted.

## Forbidden Couplings

- rule-to-rule dependencies
- reporter-to-parser dependencies
- config-loader-to-rule-evaluation side effects
- hidden global state shared across scans
- semantic graph reconstruction
- persistent indexing or background analysis

## Change Rule

- If a new module or coupling is necessary, document the reason in `docs/tad.md` first and add tests that prove the new boundary is deterministic.
