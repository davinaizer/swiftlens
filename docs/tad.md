# SwiftLens Technical Architecture Document

## Document Control

- Product: SwiftLens
- Version: v1
- Status: Draft
- Source inputs:
  - [SwiftLens-project-definition-pack.md](./SwiftLens-project-definition-pack.md)
  - [SwiftLens-project-action-plan.md](./SwiftLens-project-action-plan.md)

## 1. Architecture Objective

Define the technical shape of SwiftLens so the CLI, config model, discovery pipeline, syntax parsing layer, rule engine, and reporters stay deterministic and testable.

The design priority is correctness and traceability, not extensibility at the cost of ambiguity.

## 1.1 Architectural Constraints

- SwiftSyntax AST inspection is the primary analysis layer
- the rule engine operates on syntax-derived structures only
- analysis remains single-process and deterministic
- rule evaluation avoids compiler infrastructure dependencies
- findings are advisory governance signals, not semantic guarantees

## 1.2 Phase-Aware Architecture Constraints

- Early phases prefer direct orchestration over layered indirection.
- Avoid premature abstractions.
- Avoid protocol hierarchies unless they are operationally necessary.
- Defer sophistication until repetition justifies it in fixtures or real repositories.
- Introduce shared state or shared metadata only when the current phase explicitly needs it.

## 2. System Overview

Pipeline:

```text
CLI Entry
→ Command Defaults
→ ConfigResolution
→ Config Loader
→ Project Discovery
→ SwiftSyntax Traversal
→ Direct Rule Evaluation
→ Reporter
→ Exit Policy
```

## 3. Architectural Principles

1. Prefer deterministic syntax signals over fuzzy heuristics.
2. Keep rule packs independently enableable.
3. Treat config as executable policy, not documentation.
4. Emit findings with stable IDs, precise ranges, and explicit fix patterns.
5. Avoid auto-fix behavior in V1.
6. Keep machine output compact and stable across runs.
7. Prefer shallow declared relationships over inferred architecture.
8. Add abstractions only when repetition proves they reduce operational risk.

## 4. Technology Choices

| Layer | Choice | Rationale |
| --- | --- | --- |
| Implementation language | Swift | Native SwiftSyntax integration and same-language analysis |
| Parsing | SwiftSyntax | AST parsing and traversal |
| Config parsing | Yams or equivalent | YAML config loading |
| Config resolution | Deterministic cwd-only lookup | Local execution ergonomics without hierarchy logic |
| Project discovery | filesystem inspection plus optional `swift package describe` and `xcodebuild` metadata | Lightweight discovery limited to local metadata |
| Output | JSON, YAML, Markdown, compact terminal | Supports CI, humans, and AI agents |

## 5. Package Structure

Target package shape:

```text
swiftlens/
├── Package.swift
├── Sources/
│   └── SwiftLensCLI/
├── Tests/
│   └── SwiftLensTests/
├── docs/
├── examples/
└── scripts/
```

### 5.1 Logical Modules

| Module | Responsibility |
| --- | --- |
| `SwiftLensCLI` | Argument parsing, command routing, exit code |
| `ConfigResolution` | Resolve the effective config path from explicit input or cwd-only lookup |
| `ProjectDiscovery` | Detect package, project, workspace, and source roots |
| `ConfigLoader` | Load `.swiftlens.yml` and validate policy |
| `SyntaxRecords` | Deferred shared syntax metadata store, introduced only when repeated rule needs justify it |
| `RuleEngine` | Execute configured rules |
| `RulesSwiftUICore` | Generic SwiftUI rules |
| `RulesAISlop` | Heuristic overengineering rules |
| `RulesArchitecture` | Boundary and ownership rules |
| `RulesAlfred` | Alfred governance pack |
| `Reporter` | JSON, YAML, Markdown, compact outputs |

## 6. CLI Contract

Commands:

- `swiftlens scan`
- `swiftlens validate-config`
- `swiftlens version`
- `swiftlens help`

Flags:

- `--config`
- `--format`
- `--path`
- `--verbose`

CLI scope:

- `swiftlens` defaults to `scan .`
- `swiftlens scan` defaults to `.`
- omitted `--config` resolves `.swiftlens.yml` from the current working directory only
- explicit `--config` overrides local lookup
- omitted `--format` defaults to `json`
- flags influence execution scope and reporter selection
- flags do not override rule severity or rule config
- CLI execution remains single-process and deterministic

## 7. Forbidden Technical Directions

The following are prohibited in V1:

- SourceKit dependency for core governance
- compiler plugin architecture
- semantic type graph reconstruction
- whole-program analysis
- transitive architecture inference
- persistent indexing databases
- incremental daemon infrastructure
- distributed analysis services
- Bazel-like dependency governance
- generalized static analysis ambitions

## 8. Configuration Constraints

Configuration is declarative only.

Configuration MUST NOT:

- define executable logic
- support scripting
- support embedded expressions
- support custom evaluators
- support user-defined traversal semantics
- support parent-directory traversal or recursive config search
- support nested config hierarchy logic
- support remote, global user, or environment-aware config resolution

### 8.1 Config Resolution

When `--config` is omitted, SwiftLens resolves `.swiftlens.yml` from the current working directory only.

Config resolution must:

- check only the current working directory
- remain deterministic
- avoid parent-directory traversal
- avoid recursive search
- avoid hierarchy or inheritance logic
- avoid workspace discovery
- avoid IDE-aware lookup

An explicit `--config` path always overrides local lookup.

Missing config returns exit code `2`.

## 9. Config Contracts

The full `.swiftlens.yml` schema is documented in [config-schema.md](config-schema.md).

Validation rules, precedence, and exit-code behavior are documented in [config-validation.md](config-validation.md).

The TAD intentionally stays focused on architecture and leaves the schema contract to the dedicated config docs.

## 10. Project Discovery

Discovery must resolve the project type and source roots before parsing.

### 10.1 Discovery Rules

1. If `Package.swift` exists, treat the repository as an SPM project and use Swift Package metadata first.
2. If an `.xcodeproj` or `.xcworkspace` exists, use `xcodebuild` discovery.
3. If both exist, prefer the configured `project.path` in `.swiftlens.yml`.
4. Resolve only declared or static route references; do not infer app flow.
5. Apply include and exclude scope filters after discovery.
6. Do not build a persistent or background discovery index.

### 10.2 Discovery Inputs

| Command | Purpose |
| --- | --- |
| `swift package describe` | Resolve Swift Package metadata |
| `xcodebuild -list` | Discover schemes and targets |
| `xcodebuild -showBuildSettings` | Resolve source roots and build settings |

### 10.3 Discovery Output

Discovery should produce:

- project type
- resolved root path
- source roots
- feature roots
- file candidates for parsing

## 11. Syntax and Structure Model

SwiftSyntax parsing should detect:

- `struct X: View`
- `body`
- protocols
- classes
- functions
- imports
- comments
- navigation patterns

### 10.1 Core Records

| Record | Responsibility |
| --- | --- |
| Declaration record set | Track declarations, kinds, and ranges |
| File ownership map | Associate files with feature or domain ownership |
| Feature root ownership | Record which root owns which declaration set |
| Reference record set | Support shallow declared relationship checks only |

### 10.2 Stored Metadata

For each source file, store:

- file path
- source ranges
- declaration metadata
- imports
- comments
- declared relationships needed by rules

## 12. Rule Engine

### 11.1 Rule Engine Constraints

Rules must:

- be deterministic
- use stable IDs
- produce explainable findings
- avoid hidden state
- avoid probabilistic behavior
- avoid ML or AI inference

Rules must not:

- mutate source
- auto-fix architecture
- infer semantic correctness
- depend on build execution
- require protocol hierarchies when a direct type or function call is sufficient

A rule must justify its governance value relative to implementation complexity.

### 11.2 Rule Interface

```swift
protocol SwiftLensRule {
    var id: String { get }
    var pack: String { get }
    var defaultSeverity: Severity { get }

    func evaluate(context: RuleContext) throws -> [Violation]
}
```

### 11.3 Supporting Types

```swift
struct RuleContext {
    let project: ProjectModel
    let config: SwiftLensConfig
    let files: [SourceFile]
    let syntaxRecords: [SourceFileSyntaxRecord]
    let declarationRecords: [DeclarationRecord]?
    let referenceRecords: [ReferenceRecord]?
}
```

```swift
enum Severity: String, Codable {
    case advisory
    case warning
    case error
}
```

```swift
enum Confidence: String, Codable {
    case low
    case medium
    case high
}
```

```swift
struct Violation: Codable {
    let rule: String
    let pack: String
    let severity: Severity
    let file: String
    let range: SourceRange?
    let reason: String
    let fixPattern: String?
    let confidence: Confidence
}
```

### 11.4 Required Violation Fields

Every violation must include:

- stable rule ID
- pack name
- severity
- confidence
- file path
- source range
- reason
- fix pattern

`fixPattern` is the canonical public field name.

### 11.5 Evaluation Strategy

1. Load config.
2. Resolve project scope.
3. Parse files into syntax and structure records.
4. Build declaration and reference metadata only when the current phase requires it.
5. Execute enabled rules in a deterministic order.
6. Merge built-in defaults with pack and rule overrides.
7. Collect violations.
8. Report findings.
9. Map final severity state to exit code.

## 13. Rule-Pack Strategy

### 12.1 Phase 1 Rule Priority

Phase 1 ships exactly one deterministic rule.

### 12.2 Later Rule Expansion

After Phase 1 exits cleanly, expand the rule registry in the documented phase order:

- deterministic rule infrastructure
- syntax-first governance rules
- reporting and validation
- documentation hardening

V1 uses built-in packs only; external pack surfaces are rejected by default.

## 14. Graph Analysis Limits

SwiftLens graph analysis is deliberately shallow.

Allowed depth:

- maximum depth: 1-2 declared relationships

Allowed edges:

- imports
- configured ownership
- route declarations
- lightweight module references

Explicitly prohibited:

- inferred ownership graphs
- runtime dependency graphs
- transitive closure analysis
- cycle resolution engines
- graph optimization systems
- persistent graph infrastructure

## 15. Detection Strategy

### 14.1 SwiftUI Core

| Rule | Signal |
| --- | --- |
| `MassiveSwiftUIView` | Excessive line count, body size, or complexity |
| `NestedBodyComplexity` | Deeply nested conditional or view-tree structure |
| `StateOwnershipDrift` | Suspicious local state ownership in child views |
| `ViewModelBusinessLogicLeak` | Domain logic embedded in a SwiftUI view body or action path |

### 14.2 AI Slop

| Rule | Signal |
| --- | --- |
| `SingleUseProtocol` | One implementation, no visible seam need |
| `PassThroughWrapper` | Forward-only wrapper with no behavior |
| `EmptyAbstraction` | Manager, Provider, or Service shell with no meaningful logic |
| `CommentRestatesCode` | Comment text mirrors syntax instead of intent |
| `RedundantDefensiveGuard` | Guard or if check protects an impossible or already-enforced state |

### 14.3 Architecture

| Rule | Signal |
| --- | --- |
| `CrossFeatureImport` | Feature imports another feature outside allowed boundaries |
| `OrphanRoute` | Route exists with no reachable navigation path |
| `FeatureBoundaryViolation` | Ownership leaks across configured roots |
| `DuplicateOwnership` | More than one owner exists for the same state domain |

### 14.4 Alfred

| Rule | Signal |
| --- | --- |
| `AppRouterOnly` | Navigation mutation occurs outside `AppRouter` flow |
| `SingleSourceOfTruth` | Home, Idea, or Recommendation state is duplicated |
| `NoHardcodedUserStrings` | User-facing text bypasses localization |
| `AlfredIconsOnly` | Production icons bypass `AlfredIcons` |
| `DebugOnlyPreviewData` | Preview data is reachable outside debug-only contexts |
| `CallbackChildViews` | Child view owns routing instead of exposing callbacks |
| `SendableDTOs` | Touched DTOs lack `Sendable` where applicable |

## 16. Reporting

### 15.1 Report Formats

| Format | Priority | Purpose |
| --- | --- | --- |
| JSON | highest | CI and AI-agent consumption |
| YAML | high | Structured output with human readability |
| Markdown | high | PR and review summaries |
| Compact | high | Terminal summary |

### 15.2 Output Requirements

Reports should include:

- summary counts by severity
- findings grouped by severity and pack where relevant
- stable rule IDs
- file and range metadata
- reason
- fix pattern
- confidence

Default machine output should avoid long-form commentary.

## 17. Exit Policy

| Highest Finding | Exit Code |
| --- | --- |
| none | 0 |
| advisory only | 0 |
| warning only | 0 |
| error | 1 |
| config error | 2 |
| internal failure | 3 |

## 18. Validation Strategy

Validation must cover:

- config schema acceptance and rejection
- project discovery on Swift Package and Xcode layouts
- parser coverage for the supported Swift constructs
- rule evaluation determinism
- reporter formatting
- exit-code mapping

### 18.1 TDD Standard From Phase 2 Onward

- Phase 1 remains accepted as already implemented.
- From Phase 2 onward, implementation work must be test-first by default.
- Write or update failing tests before changing behavior.
- Implement the smallest code change that satisfies the test.
- Run the relevant test target before widening scope.
- Refactor only after tests pass.
- Preserve deterministic behavior throughout the workflow.

### 18.2 Test Constraints

- New rules require fixture-backed tests before implementation.
- Reporter changes require golden-output tests.
- Config changes require valid and invalid config tests.
- Exit-code changes require explicit exit-code tests.
- Tests must remain fixture-backed where behavior is file- or project-dependent.
- Tests must avoid network, clock, randomness, external services, and machine-local state.
- Tests must verify stable rule IDs, finding shape, ordering, and exit codes where applicable.

### 17.1 Trust-Building Rule Validation

Rules should not be optimized before they are exercised on a real codebase.

For Alfred validation:

- fix false positives
- fix rule ambiguity
- tighten weak detections

## 19. Repository Integration

### 18.1 Alfred Wrapper

An Alfred wrapper script should call:

```bash
swiftlens scan
```

Suggested location:

```text
./tools/swiftlens.sh
```

### 18.2 CI Contract

CI should run:

```bash
swiftlens scan --config .swiftlens.yml --format json
```

This gives deterministic machine output for gating and bot consumption.

## 20. Directory and Artifact Strategy

Recommended repo-level artifacts:

- `docs/prd.md`
- `docs/tad.md`
- `docs/architecture.md`
- `docs/rule-engine.md`
- `docs/implementation-plan.md`
- `examples/`
- `scripts/`

## 21. Performance Constraints

SwiftLens prioritizes deterministic execution predictability over maximum analytical depth.

V1 targets:

- single-process execution
- bounded memory growth
- file-local analysis where possible
- no persistent indexing
- no background caching daemons

## 22. Complexity Ceiling

SwiftLens intentionally rejects analyses whose correctness depends on:

- compiler state
- runtime state
- inferred symbol graphs
- transitive semantic reconstruction
- whole-program reasoning

If a rule requires those capabilities, the rule is out of scope for V1.

## 23. Reliability Constraints

The tool should:

- behave deterministically across repeated runs on the same input
- avoid extra dependencies beyond SwiftSyntax and YAML parsing
- remain CLI-first
- report config errors cleanly and early
- avoid speculative inference when a structural signal is missing
- avoid transitive or semantic reconstruction

## 24. Open Technical Decisions

These are intentionally deferred until implementation proves the shape:

The following items are explicitly rejected for V1:

- semantic architecture reconstruction
- inferred ownership graphs
- runtime dependency graphs
- persistent graph infrastructure
- semantic route inference
- ownership topology engines

The following implementation details remain open:

- exact shape of `SourceRange`
- whether reference records are required in V1 or deferred to later packs
- whether `Yams` or an equivalent YAML parser is chosen
- exact glob engine and its failure modes

## 25. V1 Completion Definition

V1 is complete only when:

- the CLI executable is available through the Swift package
- config validation is enforced
- project discovery is deterministic
- syntax and declaration records are in place
- the rule engine runs configured rules consistently
- the required V1 packs are implemented
- reporters and exit codes match the documented contract
- Alfred validation has confirmed the architecture model on a real repository
