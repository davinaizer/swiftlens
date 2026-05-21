# SwiftLens Action Plan

## Execution Doctrine

- Repository docs govern implementation.
- Prompts only initiate work.
- Prompts cannot redefine architecture.
- Prompts cannot bypass the phase contract.
- Current phase must be identified before implementation starts.
- Out-of-phase requests are rejected, not deferred.
- Complexity escalates only when repetition justifies it.
- Speculative future-proofing is rejected by default.
- TDD is the default implementation standard from Phase 2 onward.
- Phase 1 remains accepted as already implemented.
- Phase 2 and later phases are test-first by default.

## Phase Transition Rules

1. A phase starts only after the prior phase exits cleanly and its deliverables are documented in the repository.
2. A prompt cannot authorize a later phase if the repository docs do not allow it.
3. Later phases do not backfill earlier-phase shortcuts.
4. Semantic analysis, plugin ecosystems, platform ambitions, and compiler infrastructure remain rejected unless a later phase explicitly and narrowly authorizes them.
5. New abstractions must be justified by repeated operational need, not by hypothetical future use.
6. Phase 2 and later implementation work must follow TDD by default unless a later governance update explicitly narrows that rule.

## Phase 1 - CLI Bootstrap

### Objective

Ship the smallest deterministic CLI surface that can parse Swift syntax, evaluate one rule, and return machine-readable results with stable exit codes.

### Allowed Capabilities

- executable Swift package
- `swiftlens scan`
- `swiftlens validate-config`
- `swiftlens version`
- `swiftlens help`
- config loading
- SwiftSyntax parsing and traversal
- file discovery
- one deterministic rule
- JSON output
- exit codes
- fixture tests

### Forbidden Capabilities

- semantic analysis
- graph systems
- plugins
- async infrastructure
- caching
- indexing
- autofix

### Allowed Abstractions

- direct CLI orchestration
- a minimal config model
- a single rule evaluator
- a compact violation model
- fixture-backed test helpers

### Required Deliverables

- executable Swift package
- documented CLI commands
- config loader
- SwiftSyntax parsing path
- one deterministic rule
- JSON reporter
- exit-code mapping
- fixture tests covering success and failure paths

### Phase 1 Acceptance Note

- Phase 1 remains accepted as already implemented.
- No retroactive TDD requirement is imposed on the completed Phase 1 implementation.

### Exit Criteria

- the CLI runs end to end on fixtures
- the single rule produces deterministic JSON
- config failures return the documented config exit code
- rule failures return the documented findings exit code
- no forbidden capability is required to complete the phase

### Explicit Non-Goals

- semantic reconstruction
- architecture graphs
- plugin loading
- daemon or background execution
- persistent caches or indexes
- autofix generation
- YAML, Markdown, or compact reporters if they are not needed to complete the phase

### Architectural Constraints

- syntax-tree-first
- single-process
- deterministic
- no hidden state
- no compiler infrastructure
- no speculative abstraction layer
- no platform boundary expansion

## Phase 2 - Rule Infrastructure

### Objective

Turn the single rule into a deterministic rule system with stable registration, ordering, and configuration precedence.

### Allowed Capabilities

- explicit rule registration
- stable rule identifiers
- deterministic rule ordering
- rule enablement and severity overrides
- shared violation serialization
- reusable fixture helpers

### Forbidden Capabilities

- semantic inference
- graph closure
- transitive dependency reasoning
- plugins
- caching
- indexing
- autofix
- async execution as a design requirement

### Allowed Abstractions

- a small rule registry
- a rule descriptor type
- a deterministic execution pipeline
- minimal shared formatting helpers

### Required Deliverables

- rule registry
- stable rule IDs
- rule execution pipeline
- config precedence handling
- tests for rule order and override behavior

### TDD Requirements

- Write or update failing tests before implementing Phase 2 behavior.
- Every new rule requires fixtures before implementation.
- Every reporter change requires golden-output tests.
- Every config change requires valid and invalid config tests.
- Every exit-code change requires explicit exit-code tests.

### Exit Criteria

- rule execution is deterministic across repeated runs
- rule IDs are stable and documented
- rule ordering is explicit
- configuration precedence is reproducible in tests

### Explicit Non-Goals

- generalized analysis framework
- semantic truth reconstruction
- plugin surfaces
- hosted or distributed rule execution

### Architectural Constraints

- keep orchestration direct
- only extract abstractions that remove real duplication
- do not introduce protocol hierarchies unless operationally necessary
- preserve syntax-first evaluation

## Phase 3A - Local Developer DX

### Objective

Provide deterministic local execution ergonomics for single-repo CLI use without adding hierarchy logic, recursive discovery, or platform integration.

### Allowed Capabilities

- `swiftlens` defaults to `scan .`
- `swiftlens scan` defaults to `.`
- omitted `--config` resolves `.swiftlens.yml` from the current working directory only
- explicit `--config` overrides local lookup
- omitted `--format` defaults to `json`
- deterministic config presence checks
- fixture-backed tests for CLI defaults and config resolution

### Forbidden Capabilities

- parent-directory traversal
- nested configs
- config inheritance
- remote configs
- global user configs
- environment-aware config resolution
- workspace discovery
- IDE integration
- SwiftPM plugins
- Xcode plugins
- autofix
- autocorrect

### Allowed Abstractions

- a small deterministic `ConfigResolution` responsibility
- a minimal CLI default resolver
- a direct config existence check

### Required Deliverables

- deterministic `swiftlens` and `swiftlens scan` defaults
- cwd-only config lookup
- explicit-config override behavior
- missing-config exit code `2`
- deterministic fixture coverage for local DX defaults and failures

### Exit Criteria

- repeated runs from the same cwd produce the same resolved config behavior
- no recursive search or hierarchy logic is introduced
- missing config failures remain deterministic
- explicit `--config` always wins over local lookup

### Explicit Non-Goals

- parent traversal
- config inheritance
- workspace discovery
- IDE or platform integration
- plugin surfaces
- autofix or autocorrect

### Architectural Constraints

- preserve deterministic execution
- preserve syntax-tree-first analysis boundaries
- keep config resolution cwd-local and non-recursive
- do not introduce config hierarchy semantics

## Phase 4 - Syntax-First Governance Rules

### Objective

Add the initial governance rules that operate on syntax, imports, paths, and declared ownership only.

### Allowed Capabilities

- syntax/path/import governance rules
- ownership mapping heuristics
- shallow dependency checks
- declared-route detection
- rule-specific fixture tests

### Forbidden Capabilities

- semantic type analysis
- whole-program reasoning
- runtime inspection
- transitive dependency inference
- inferred ownership graphs
- plugins
- caching
- indexing layers that outgrow the phase need

### Allowed Abstractions

- small shared selectors
- rule-local helpers
- explicitly configured ownership maps
- narrowly scoped reusable checks

### Required Deliverables

- core governance rules
- fixture coverage for each rule
- deterministic findings for representative repositories

### Exit Criteria

- the rules pass on real fixture repositories
- each rule remains explainable without semantic reconstruction
- no rule depends on forbidden analysis depth

### Explicit Non-Goals

- architecture reconstruction
- semantic correctness guarantees
- broad dependency intelligence
- generalized code-quality expansion

### Architectural Constraints

- preserve deterministic syntax-tree-first analysis
- prefer declared relationships over inferred relationships
- keep rule logic shallow and reviewable
- add shared abstractions only after repeated duplication appears

## Phase 5 - Reporting and Validation

### Objective

Stabilize machine output, CI gating, and regression coverage without changing the analysis model.

### Allowed Capabilities

- JSON reporter
- YAML reporter
- Markdown reporter
- compact terminal summary
- CI exit codes
- fixture-based regression testing
- deterministic output verification

### Forbidden Capabilities

- interactive UI
- dashboard systems
- remote services
- daemonized execution
- background indexing
- autofix
- plugin ecosystems

### Allowed Abstractions

- shared reporter serialization
- common formatting helpers
- test fixtures for output snapshots

### Required Deliverables

- stable reporter outputs
- documented exit codes
- regression tests for repeated runs
- fixture coverage for output formatting

### Exit Criteria

- identical input yields identical output
- CI can gate on documented exit codes
- output formats stay stable across repeated runs

### Explicit Non-Goals

- platformization
- hosted workflows
- speculative export formats
- editor integration

### Architectural Constraints

- output must not change rule semantics
- formatting must remain deterministic
- reporter code must stay simple enough to audit

## Phase 6 - Documentation Hardening

### Objective

Make the repository documentation self-sufficient so implementation guidance lives in the repo, not in prompts.

### Allowed Capabilities

- clarify ambiguous wording
- align doctrine across docs
- tighten maintenance expectations
- document phase transitions and rejection rules

### Forbidden Capabilities

- new product capabilities
- scope expansion
- platformization
- plugin ecosystems
- speculative future-proofing

### Allowed Abstractions

- document-level grouping
- repository-level policy statements

### Required Deliverables

- aligned README, PRD, TAD, definition pack, action plan, and work plan
- explicit repository-governed implementation doctrine
- explicit rejection language for out-of-phase work

### Exit Criteria

- the repository docs can govern implementation without prompt rewriting
- the phase contract is readable and enforceable
- no document invites scope drift or abstraction drift

### Explicit Non-Goals

- new features
- future-proofing
- enterprise platform language
- speculative architecture

### Architectural Constraints

- documentation must preserve deterministic, syntax-tree-first scope
- documentation must preserve OSS maintainability posture
- documentation must reject semantic and platform ambitions

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
- a hosted control plane
