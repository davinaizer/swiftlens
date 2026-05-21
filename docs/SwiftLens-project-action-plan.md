# SwiftLens Action Plan

## Phase 1 - CLI Bootstrap

- create the executable Swift package
- wire `swiftlens scan`, `validate-config`, `version`, and `help`
- add config loading
- add SwiftSyntax traversal
- add file discovery

## Phase 2 - Rule Infrastructure

- add a deterministic rule registry
- assign stable rule IDs
- implement the rule execution pipeline
- keep rule ordering explicit and reproducible

## Phase 3 - Syntax-First Governance Rules

- add syntax/path/import governance rules
- add ownership mapping heuristics
- add shallow dependency checks
- keep all checks limited to declared, lightweight relationships

## Phase 4 - Reporting and Validation

- add JSON and YAML reporters
- add CI exit codes
- add fixture-based testing
- verify deterministic output across repeated runs

## Phase 5 - Documentation Hardening

- stabilize the governance pack
- remove ambiguous language from docs
- keep OSS maintenance expectations realistic
- keep built-in packs only in V1
- reject any scope that requires compiler infrastructure or hosted-service behavior

## Scope Rejection Gate

Before implementing any feature, reject it unless it is:

- deterministic
- syntax-first
- CI-relevant
- fixture-testable
- low-maintenance
- explainable without semantic reconstruction

## Anti-Platformization Constraints

SwiftLens must not evolve into:

- a governance platform
- a plugin ecosystem
- compiler infrastructure
- a generalized architecture analysis framework
- a distributed governance service
