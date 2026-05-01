# SwiftLens Technical Architecture Document

## Document Control

- Product: SwiftLens
- Version: v1
- Status: Draft
- Source inputs:
  - [SwiftLens-project-definition-pack.md](./SwiftLens-project-definition-pack.md)
  - [SwiftLens-project-action-plan.md](./SwiftLens-project-action-plan.md)

## 1. Architecture Objective

Define the technical shape of SwiftLens so the CLI, config model, discovery pipeline, syntax index, rule engine, and reporters stay deterministic and testable.

The design priority is correctness and traceability, not extensibility at the cost of ambiguity.

## 2. System Overview

Pipeline:

```text
CLI Entry
→ Project Discovery
→ Config Loader
→ SwiftSyntax Parser
→ Symbol / Structure Index
→ Rule Engine
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

## 4. Technology Choices

| Layer | Choice | Rationale |
| --- | --- | --- |
| Implementation language | Swift | Native SwiftSyntax integration and same-language analysis |
| Parsing | SwiftSyntax | AST parsing and traversal |
| Config parsing | Yams or equivalent | YAML config loading |
| Project discovery | `swift package describe`, `xcodebuild -list`, `xcodebuild -showBuildSettings` | Native discovery of package and Xcode metadata |
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
| `ProjectDiscovery` | Detect package, project, workspace, and source roots |
| `ConfigLoader` | Load `.swiftlens.yml` and validate policy |
| `SyntaxIndex` | Parse files and expose declaration and structure data |
| `RuleEngine` | Execute configured rules |
| `RulesSwiftUICore` | Generic SwiftUI rules |
| `RulesAISlop` | AI-slop detection rules |
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

- flags influence execution scope and reporter selection
- flags do not override rule severity or rule config

## 7. Config Model

`.swiftlens.yml` is the policy contract.

### 7.1 Minimum Shape

```yaml
project:
  path: .
  include: []
  exclude: []
packs:
  swiftui-core:
    enabled: true
    severityOverrides: {}
rules:
  MassiveSwiftUIView:
    enabled: true
    severity: warning
    config: {}
```

### 7.2 Project Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `project.path` | string | yes | Repo root or scan root |
| `project.include` | string array | no | Glob patterns included in scope |
| `project.exclude` | string array | no | Glob patterns excluded from scope |
| `project.name` | string | no | Human-readable project name |
| `project.sourceRoots` | string array | no | Explicit source roots for discovery |
| `project.featureRoots` | string array | no | Ownership and boundary roots |
| `project.navigationOwner` | string | no | Expected router owner |
| `project.localizationFiles` | string array | no | Localization resources for string rules |
| `project.debugPreviewPaths` | string array | no | Debug-only preview locations |

### 7.3 Pack and Rule Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `packs.<pack>.enabled` | boolean | yes | Enables or disables the pack |
| `packs.<pack>.severityOverrides` | map | no | Per-rule severity overrides |
| `rules.<rule>.enabled` | boolean | yes | Enables or disables a rule |
| `rules.<rule>.severity` | enum | no | Rule severity override |
| `rules.<rule>.config` | map | no | Rule-specific parameters |

### 7.4 Validation Rules

Validation must reject:

- missing required fields
- invalid severity values
- invalid paths
- invalid pack names
- invalid rule IDs
- unknown keys at any level
- unknown rule config keys
- malformed glob patterns if the implementation can detect them

Config failures return exit code `2`.

### 7.5 Precedence

1. Built-in rule defaults define the baseline.
2. Pack-level severity overrides apply next.
3. Rule-level severity overrides win over pack-level and built-in values.
4. Rule-level config merges over built-in config.
5. CLI flags never mutate rule semantics.

## 8. Project Discovery

Discovery must resolve the project type and source roots before parsing.

### 8.1 Discovery Rules

1. If `Package.swift` exists, treat the repository as an SPM project and use Swift Package metadata first.
2. If an `.xcodeproj` or `.xcworkspace` exists, use `xcodebuild` discovery.
3. If both exist, prefer the configured `project.path` in `.swiftlens.yml`.
4. Apply include and exclude scope filters after discovery.

### 8.2 Discovery Inputs

| Command | Purpose |
| --- | --- |
| `swift package describe` | Resolve Swift Package metadata |
| `xcodebuild -list` | Discover schemes and targets |
| `xcodebuild -showBuildSettings` | Resolve source roots and build settings |

### 8.3 Discovery Output

Discovery should produce:

- project type
- resolved root path
- source roots
- feature roots
- file candidates for parsing

## 9. Syntax and Structure Model

SwiftSyntax parsing should detect:

- `struct X: View`
- `body`
- protocols
- classes
- functions
- imports
- comments
- navigation patterns

### 9.1 Core Indexes

| Index | Responsibility |
| --- | --- |
| Declaration index | Track symbols, declaration kinds, and ranges |
| File ownership map | Associate files with feature or domain ownership |
| Feature root ownership | Record which root owns which declaration set |
| Reference index | Support future navigation and reachability checks |

### 9.2 Stored Metadata

For each source file, store:

- file path
- source ranges
- declaration metadata
- imports
- comments
- symbol relationships needed by rules

## 10. Rule Engine

### 10.1 Rule Interface

```swift
protocol SwiftLensRule {
    var id: String { get }
    var pack: String { get }
    var defaultSeverity: Severity { get }

    func evaluate(context: RuleContext) throws -> [Violation]
}
```

### 10.2 Supporting Types

```swift
struct RuleContext {
    let project: ProjectModel
    let config: SwiftLensConfig
    let files: [SourceFile]
    let syntaxIndex: SyntaxIndex
    let declarationIndex: DeclarationIndex
    let referenceIndex: ReferenceIndex?
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

### 10.3 Required Violation Fields

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

### 10.4 Evaluation Strategy

1. Load config.
2. Resolve project scope.
3. Parse files into syntax and structure indexes.
4. Build declaration and reference metadata.
5. Execute enabled rules in a deterministic order.
6. Merge built-in defaults with pack and rule overrides.
7. Collect violations.
8. Report findings.
9. Map final severity state to exit code.

## 11. Rule-Pack Strategy

### 11.1 Initial Rule Priorities

The first three rules to ship are:

- `AppRouterOnly`
- `MassiveSwiftUIView`
- `SingleUseProtocol`

Reason:

- `AppRouterOnly` has the highest Alfred value
- `MassiveSwiftUIView` is generic and easy to validate
- `SingleUseProtocol` is a low-risk AI-slop detector

### 11.2 Remaining V1 Architecture Rules

After the first three rules are trusted, implement:

- `CrossFeatureImport`
- `OrphanRoute`
- `FeatureBoundaryViolation`
- `DuplicateOwnership`

### 11.3 Remaining Required Packs

Then complete:

- `swiftui-core`
- `ai-slop`
- `alfred`

## 12. Detection Strategy

### 12.1 SwiftUI Core

| Rule | Signal |
| --- | --- |
| `MassiveSwiftUIView` | Excessive line count, body size, or complexity |
| `NestedBodyComplexity` | Deeply nested conditional or view-tree structure |
| `StateOwnershipDrift` | Suspicious local state ownership in child views |
| `ViewModelBusinessLogicLeak` | Domain logic embedded in a SwiftUI view body or action path |

### 12.2 AI Slop

| Rule | Signal |
| --- | --- |
| `SingleUseProtocol` | One implementation, no visible seam need |
| `PassThroughWrapper` | Forward-only wrapper with no behavior |
| `EmptyAbstraction` | Manager, Provider, or Service shell with no meaningful logic |
| `CommentRestatesCode` | Comment text mirrors syntax instead of intent |
| `RedundantDefensiveGuard` | Guard or if check protects an impossible or already-enforced state |

### 12.3 Architecture

| Rule | Signal |
| --- | --- |
| `CrossFeatureImport` | Feature imports another feature outside allowed boundaries |
| `OrphanRoute` | Route exists with no reachable navigation path |
| `FeatureBoundaryViolation` | Ownership leaks across configured roots |
| `DuplicateOwnership` | More than one owner exists for the same state domain |

### 12.4 Alfred

| Rule | Signal |
| --- | --- |
| `AppRouterOnly` | Navigation mutation occurs outside `AppRouter` flow |
| `SingleSourceOfTruth` | Home, Idea, or Recommendation state is duplicated |
| `NoHardcodedUserStrings` | User-facing text bypasses localization |
| `AlfredIconsOnly` | Production icons bypass `AlfredIcons` |
| `DebugOnlyPreviewData` | Preview data is reachable outside debug-only contexts |
| `CallbackChildViews` | Child view owns routing instead of exposing callbacks |
| `SendableDTOs` | Touched DTOs lack `Sendable` where applicable |

## 13. Reporting

### 13.1 Report Formats

| Format | Priority | Purpose |
| --- | --- | --- |
| JSON | highest | CI and AI-agent consumption |
| YAML | high | Structured output with human readability |
| Markdown | high | PR and review summaries |
| Compact | high | Terminal summary |

### 13.2 Output Requirements

Reports should include:

- summary counts by severity
- findings grouped by severity and pack where relevant
- stable rule IDs
- file and range metadata
- reason
- fix pattern
- confidence

Default machine output should avoid long-form commentary.

## 14. Exit Policy

| Highest Finding | Exit Code |
| --- | --- |
| none | 0 |
| advisory only | 0 |
| warning only | 0 by default, configurable if needed later |
| error | 1 |
| config error | 2 |
| internal failure | 3 |

## 15. Validation Strategy

Validation must cover:

- config schema acceptance and rejection
- project discovery on Swift Package and Xcode layouts
- parser coverage for the supported Swift constructs
- rule evaluation determinism
- reporter formatting
- exit-code mapping

### 15.1 Trust-Building Rule Validation

Rules should not be optimized before they are exercised on a real codebase.

For Alfred validation:

- fix false positives
- fix rule ambiguity
- tighten weak detections

## 16. Repository Integration

### 16.1 Alfred Wrapper

An Alfred wrapper script should call:

```bash
swiftlens scan
```

Suggested location:

```text
./tools/swiftlens.sh
```

### 16.2 CI Contract

CI should run:

```bash
swiftlens scan --config .swiftlens.yml --format json
```

This gives deterministic machine output for gating and bot consumption.

## 17. Directory and Artifact Strategy

Recommended repo-level artifacts:

- `docs/prd.md`
- `docs/tad.md`
- `docs/architecture.md`
- `docs/rule-engine.md`
- `docs/implementation-plan.md`
- `examples/`
- `scripts/`

## 18. Performance and Reliability Constraints

The tool should:

- behave deterministically across repeated runs on the same input
- avoid extra dependencies beyond SwiftSyntax and YAML parsing
- remain CLI-first
- report config errors cleanly and early
- avoid speculative inference when a structural signal is missing

## 19. Open Technical Decisions

These are intentionally deferred until implementation proves the shape:

- exact shape of `SourceRange`
- whether `ReferenceIndex` is required in V1 or deferred to later packs
- whether `Yams` or an equivalent YAML parser is chosen
- exact glob engine and its failure modes
- whether `warning` should ever become non-zero in CI via explicit configuration

## 20. V1 Completion Definition

V1 is complete only when:

- the CLI executable is available through the Swift package
- config validation is enforced
- project discovery is deterministic
- syntax and declaration indexing are in place
- the rule engine runs configured rules consistently
- the required V1 packs are implemented
- reporters and exit codes match the documented contract
- Alfred validation has confirmed the architecture model on a real repository
