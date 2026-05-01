---
title: SwiftLens Project Definition Pack
status: draft
createdAt: 2026-04-27T00:00:00-03:00
lastModifiedAt: 2026-04-27T00:00:00-03:00
---

# SwiftLens Project Definition Pack

## 1. Product Concept

SwiftLens is a standalone SwiftUI architecture auditor for detecting architectural drift, AI-generated code slop, and project-governance violations before they reach review or CI.

It is not a SwiftLint replacement, formatter, Periphery clone, or AI code generator.

## 2. Product Thesis

Copilot and AI agents can generate code quickly, but they do not reliably preserve project architecture.

SwiftLens provides the missing enforcement layer:

```text
AI writes code
→ SwiftLens audits structure
→ developer reviews targeted findings
→ CI blocks architectural regressions
```

## 3. Positioning

| Tool Category  | SwiftLens Position                                     |
| -------------- | ------------------------------------------------------ |
| SwiftLint      | Style and convention enforcement                       |
| SwiftFormat    | Formatting                                             |
| Periphery      | Unused code detection                                  |
| Xcode Analyzer | Compiler/static bug diagnostics                        |
| SwiftLens      | SwiftUI architecture, governance, and AI-slop auditing |

## 4. Target Users

| User                     | Need                                                                           |
| ------------------------ | ------------------------------------------------------------------------------ |
| Indie SwiftUI developers | Prevent messy AI-generated architecture                                        |
| iOS teams                | Enforce feature boundaries and navigation ownership                            |
| AI-heavy teams           | Reduce code-review fatigue from boilerplate and overengineering                |
| Alfred team              | Enforce AppRouter, state ownership, localization, icon, and preview invariants |

## 5. V1 Goals

1. Detect SwiftUI architectural drift.
2. Detect AI-generated overengineering and boilerplate patterns.
3. Enforce project-specific governance through configurable policy packs.
4. Output compact machine-readable reports for CI and AI agents.
5. Provide human-readable Markdown reports on demand.

## 6. V1 Non-Goals

| Non-Goal                            | Reason                                                     |
| ----------------------------------- | ---------------------------------------------------------- |
| Replace SwiftLint                   | Style linting is already solved                            |
| Replace Periphery                   | Dead-code analysis is not the core product                 |
| Auto-fix architecture               | Too risky for V1                                           |
| Generate code                       | SwiftLens is an auditor, not a coding agent                |
| Parse governance docs automatically | This becomes fragile NLP instead of deterministic analysis |
| Provide GUI or dashboard            | CLI-first is simpler and more automatable                  |

## 7. Product Name

**SwiftLens**

Rationale:

- works outside Alfred
- communicates visibility and diagnosis
- avoids naming the tool as a linter
- supports future OSS positioning

Alternative internal name: **Alfred Lens** for Alfred-specific governance pack only.

---

# SwiftLens PRD v1

## 1. Objective

Build a standalone CLI tool that analyzes SwiftUI projects for architectural drift, AI-generated code slop, and configurable governance violations.

## 2. Primary Use Cases

| Use Case            | Description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| Local preflight     | Developer runs SwiftLens before committing                         |
| AI coding guardrail | Agent receives exact rule violations instead of broad repo context |
| CI enforcement      | Pull requests fail on hard governance errors                       |
| Architecture review | Reviewer receives compact report of structural risks               |
| Alfred validation   | Alfred-specific policy pack proves the model in a real codebase    |

## 3. V1 User Stories

### 3.1 Developer

As a SwiftUI developer, I want SwiftLens to tell me when AI-generated code violates the architecture so I can fix the issue before review.

Acceptance criteria:

- command exits non-zero on `error` violations
- report identifies file, range, rule, reason, and fix pattern
- output is readable without opening the full project manually

### 3.2 AI Agent

As an AI coding agent, I want compact JSON/YAML findings so I can fix only the relevant files and avoid wasting tokens on broad exploration.

Acceptance criteria:

- JSON/YAML output is deterministic
- every finding has a stable rule ID
- each finding includes precise file/range metadata

### 3.3 Reviewer

As a reviewer, I want a Markdown summary of architecture risks so I can focus review effort on meaningful issues.

Acceptance criteria:

- Markdown report groups findings by severity and rule pack
- report includes project summary counts
- report avoids essay-style commentary unless explicitly requested

### 3.4 Project Maintainer

As a maintainer, I want to map human governance rules into executable config without hardcoding them into the tool.

Acceptance criteria:

- `.swiftlens.yml` defines project policy
- governance docs remain the human source of truth
- SwiftLens does not attempt automatic natural-language parsing of docs

## 4. V1 Rule Packs

| Pack           | Purpose                                                               | V1 Status                      |
| -------------- | --------------------------------------------------------------------- | ------------------------------ |
| `swiftui-core` | Generic SwiftUI architecture rules                                    | Required                       |
| `ai-slop`      | Overengineering, boilerplate, defensive-code, and comment noise rules | Required                       |
| `architecture` | Feature boundaries, ownership, dependency direction                   | Required                       |
| `alfred`       | Alfred-specific governance rules                                      | Required for Alfred validation |

## 4.1 V1 Completion Criteria

V1 is complete only when all required packs are implemented and validated:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

The rollout order can be staged, but the product is not V1-complete until the full required pack set is available.

## 5. V1 Mandatory Rules

### 5.1 SwiftUI Core Pack

| Rule                         | Severity Default | Description                                                         |
| ---------------------------- | ---------------- | ------------------------------------------------------------------- |
| `MassiveSwiftUIView`         | warning          | Flags SwiftUI views exceeding configured size/complexity thresholds |
| `NestedBodyComplexity`       | warning          | Flags overly complex `body` trees                                   |
| `StateOwnershipDrift`        | warning          | Flags suspicious local state ownership in child views               |
| `ViewModelBusinessLogicLeak` | warning          | Flags business logic embedded in SwiftUI views                      |

### 5.2 AI Slop Pack

| Rule                      | Severity Default | Description                                                          |
| ------------------------- | ---------------- | -------------------------------------------------------------------- |
| `SingleUseProtocol`       | advisory         | Flags protocols with one implementation and no clear seam need       |
| `PassThroughWrapper`      | advisory         | Flags functions/types that only forward calls without behavior       |
| `EmptyAbstraction`        | warning          | Flags Manager/Provider/Service shells with no meaningful logic       |
| `CommentRestatesCode`     | advisory         | Flags comments that describe syntax rather than intent               |
| `RedundantDefensiveGuard` | advisory         | Flags defensive checks against impossible or already-enforced states |

### 5.3 Architecture Pack

| Rule                       | Severity Default | Description                                                     |
| -------------------------- | ---------------- | --------------------------------------------------------------- |
| `CrossFeatureImport`       | warning          | Flags feature-to-feature imports outside allowed boundaries     |
| `OrphanRoute`              | warning          | Flags route declarations with no reachable navigation path      |
| `FeatureBoundaryViolation` | error            | Flags ownership leakage across configured roots                 |
| `DuplicateOwnership`       | error            | Flags multiple owners for the same state domain when configured |

### 5.4 Alfred Pack

| Rule                     | Severity Default | Description                                                    |
| ------------------------ | ---------------- | -------------------------------------------------------------- |
| `AppRouterOnly`          | error            | Navigation must flow through AppRouter                         |
| `SingleSourceOfTruth`    | error            | Prevent duplicated ownership of Home/Idea/Recommendation state |
| `NoHardcodedUserStrings` | error            | User-facing strings must use localization                      |
| `AlfredIconsOnly`        | error            | Production icons must go through AlfredIcons                   |
| `DebugOnlyPreviewData`   | error            | Preview/mock data must remain debug-only                       |
| `CallbackChildViews`     | warning          | Child views should expose callbacks instead of owning routing  |
| `SendableDTOs`           | warning          | Touched DTOs should conform to Sendable where applicable       |

## 6. Output Modes

| Mode       | Purpose                                       |
| ---------- | --------------------------------------------- |
| `json`     | CI and AI-agent consumption                   |
| `yaml`     | AI-agent and human-readable structured output |
| `markdown` | PR/review summaries                           |
| `compact`  | Minimal terminal summary                      |

## 7. Example Machine Output

```yaml
tool: swiftlens
status: failed
summary:
  errors: 1
  warnings: 2
  advisories: 1
violations:
  - rule: AppRouterOnly
    pack: alfred
    severity: error
    file: Alfred/Presentation/Features/Dashboard/DashboardView.swift
    range: "122:9-128:5"
    reason: Direct navigation mutation outside AppRouter-owned flow.
    fixPattern: Route through AppRouter.openIdeaRecommendations(...).
```

## 8. Success Metrics

| Priority | Metric                               |
| -------- | ------------------------------------ |
| 1        | Prevents architecture regressions    |
| 2        | Finds stale/dead architectural flows |
| 3        | Reduces PR review time               |
| 4        | Reduces AI-agent token usage         |

## 9. Distribution

V1 distribution:

```text
Swift Package executable
```

Later distribution:

```text
Homebrew formula
GitHub release binary
CI templates
```

---

# Architecture Specification

## 1. System Overview

```text
CLI Entry
→ Project Discovery
→ Config Loader
→ SwiftSyntax Parser
→ Symbol/Structure Index
→ Rule Engine
→ Reporter
→ Exit Policy
```

## 2. Implementation Language

Swift.

Rationale:

- native SwiftSyntax access
- same language as target projects
- stronger SwiftUI AST understanding
- suitable for Swift Package executable distribution

## 3. Apple-Native Inputs

| Input                           | Purpose                                    |
| ------------------------------- | ------------------------------------------ |
| SwiftSyntax                     | AST parsing and rule traversal             |
| `xcodebuild -list`              | Discover schemes and targets               |
| `xcodebuild -showBuildSettings` | Resolve source roots, SDKs, build settings |
| `.xcresult` parsing             | Future build/analyze result ingestion      |
| SourceKit/index store           | Future symbol/reference intelligence       |

## 4. Core Modules

| Module              | Responsibility                                         |
| ------------------- | ------------------------------------------------------ |
| `SwiftLensCLI`      | Argument parsing, command routing, exit code           |
| `ProjectDiscovery`  | Detect package/project/workspace shape                 |
| `ConfigLoader`      | Load `.swiftlens.yml` and policy packs                 |
| `SyntaxIndex`       | Parse files and expose declaration/reference structure |
| `RuleEngine`        | Execute configured rules                               |
| `RulesSwiftUICore`  | Generic SwiftUI rules                                  |
| `RulesAISlop`       | AI-slop detection rules                                |
| `RulesArchitecture` | Boundary and ownership rules                           |
| `RulesAlfred`       | Alfred governance policy pack                          |
| `Reporter`          | JSON/YAML/Markdown/compact outputs                     |

## 5. Config Model

`.swiftlens.yml` is the executable policy contract.

Governance docs remain the human source of truth.

SwiftLens must not attempt to infer rules from prose automatically in V1.

## 6. Example Config

```yaml
project:
  name: Alfred
  sourceRoots:
    - Alfred
    - AlfredTests
  featureRoots:
    - Alfred/Presentation/Features
  navigationOwner: AppRouter
  localizationFiles:
    - Alfred/Resources/Localization/Localizable.xcstrings
  debugPreviewPaths:
    - "**/Previews/**"

packs:
  - swiftui-core
  - ai-slop
  - architecture
  - alfred

rules:
  AppRouterOnly:
    severity: error
    ownerType: AppRouter
    allowedNavigationFiles:
      - Alfred/App/Navigation/**

  MassiveSwiftUIView:
    severity: warning
    maxLines: 250
    maxBodyExpressions: 80

  SingleUseProtocol:
    severity: advisory
    allowedPatterns:
      - RepositoryProtocol
      - ServiceProtocol
```

## 7. Exit Policy

| Highest Finding  | Exit Code                  |
| ---------------- | -------------------------- |
| none             | 0                          |
| advisory only    | 0                          |
| warning only     | 0 by default, configurable |
| error            | 1                          |
| config error     | 2                          |
| internal failure | 3                          |

## 8. CI Contract

CI should run:

```bash
swiftlens scan --config .swiftlens.yml --format json
```

For Alfred repo integration, the wrapper should be:

```bash
./tools/swiftlens.sh scan
```

This preserves repo-sanctioned automation entrypoint policy.

---

# Rule Engine Design

## 1. Rule Interface

```swift
protocol SwiftLensRule {
    var id: String { get }
    var pack: String { get }
    var defaultSeverity: Severity { get }

    func evaluate(context: RuleContext) throws -> [Violation]
}
```

## 2. Rule Context

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

## 3. Violation Model

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

## 4. Severity

```swift
enum Severity: String, Codable {
    case advisory
    case warning
    case error
}
```

## 5. Confidence

```swift
enum Confidence: String, Codable {
    case low
    case medium
    case high
}
```

## 6. Rule Design Principles

1. Prefer deterministic syntax signals over fuzzy heuristics.
2. Emit low-confidence findings as advisory only.
3. Avoid auto-fixing architecture in V1.
4. Each finding must include a reason and fix pattern.
5. Rule packs must be independently enabled or disabled.

## 7. AI Slop Detection Strategy

| Slop Type          | Detection Signal                                            |
| ------------------ | ----------------------------------------------------------- |
| Overengineering    | Single-use protocol, one-method wrapper, unused abstraction |
| Boilerplate        | Pass-through methods, empty managers/providers/services     |
| Comment noise      | Comment text overlaps with nearby symbol names or syntax    |
| Defensive excess   | Guard/if checks against impossible non-optional state       |
| Architecture drift | Router bypass, duplicate state ownership, boundary leakage  |

## 8. Token Efficiency Strategy

SwiftLens should reduce AI-agent token usage by producing targeted findings.

Required fields for AI usefulness:

- rule ID
- file path
- source range
- reason
- fix pattern
- severity
- confidence

Avoid long-form prose in default machine output.

---

# V1 Implementation Plan

## Phase 0 — Repository Setup

Objective:

Create a standalone Swift package executable.

Deliverables:

- `Package.swift`
- CLI target
- test target
- basic command parser
- compact output mode

Acceptance criteria:

- `swift run swiftlens --help` works
- test target runs

## Phase 1 — Project Discovery + Config

Objective:

Load project files and `.swiftlens.yml`.

Deliverables:

- config schema
- YAML/JSON config loading
- source root discovery
- include/exclude glob support

Acceptance criteria:

- tool can scan configured Swift files
- malformed config exits with code `2`

## Phase 2 — SwiftSyntax Parsing

Objective:

Build a syntax index for Swift files.

Deliverables:

- file parser
- declaration index
- basic source ranges
- SwiftUI View detection

Acceptance criteria:

- detects `struct X: View`
- identifies `body` declarations
- reports file/range accurately

## Phase 3 — SwiftUI Core Pack

Objective:

Ship first generic SwiftUI rules.

Rules:

- `MassiveSwiftUIView`
- `NestedBodyComplexity`
- `StateOwnershipDrift`
- `ViewModelBusinessLogicLeak`

Acceptance criteria:

- rules configurable by threshold
- findings include fix pattern
- no hard dependency on Alfred code

## Phase 4 — AI Slop Pack

Objective:

Detect common LLM-generated code bloat.

Rules:

- `SingleUseProtocol`
- `PassThroughWrapper`
- `EmptyAbstraction`
- `CommentRestatesCode`
- `RedundantDefensiveGuard`

Acceptance criteria:

- low-confidence findings default to advisory
- no CI failure unless configured

## Phase 5 — Architecture Pack

Objective:

Detect project boundary and ownership violations.

Rules:

- `CrossFeatureImport`
- `FeatureBoundaryViolation`
- `OrphanRoute`
- `DuplicateOwnership`

Acceptance criteria:

- feature roots configurable
- ownership domains configurable
- errors fail CI

## Phase 6 — Alfred Policy Pack

Objective:

Validate SwiftLens against Alfred.

Rules:

- `AppRouterOnly`
- `SingleSourceOfTruth`
- `NoHardcodedUserStrings`
- `AlfredIconsOnly`
- `DebugOnlyPreviewData`
- `CallbackChildViews`
- `SendableDTOs`

Acceptance criteria:

- Alfred config can run locally
- findings are actionable
- output integrates with Alfred `./tools/*` wrapper

## Phase 7 — Reporting + CI

Objective:

Make SwiftLens usable in development and CI.

Deliverables:

- JSON reporter
- YAML reporter
- Markdown reporter
- compact reporter
- exit-code policy

Acceptance criteria:

- JSON/YAML output stable enough for AI agents
- Markdown useful for PR review
- CI exits non-zero on errors

## Phase 8 — OSS Readiness

Objective:

Prepare standalone public release.

Deliverables:

- README
- example configs
- rule documentation
- sample GitHub Action
- SwiftPM installation instructions

Acceptance criteria:

- usable on a non-Alfred SwiftUI sample app
- Alfred-specific rules are isolated in optional pack

---

# Open Decisions

| Decision                          | Default Recommendation                        |
| --------------------------------- | --------------------------------------------- |
| CLI argument parser library       | Start simple; add dependency only if needed   |
| YAML parsing dependency           | Use minimal stable Swift package              |
| SARIF support                     | V2, not V1                                    |
| SourceKit/index-store integration | V2 after syntax-only rules prove value        |
| Auto-fix support                  | Defer until deterministic detection is mature |

---

# Final Product Definition

SwiftLens is a SwiftUI architecture auditor for teams using AI coding tools.

Its job is to make architecture executable:

```text
Project governance
→ deterministic rules
→ compact findings
→ fewer regressions
→ less AI slop
```

The first proof case is Alfred.

The long-term product is project-agnostic SwiftUI architecture protection.
