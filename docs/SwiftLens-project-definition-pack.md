---
title: SwiftLens Project Definition Pack
status: draft
createdAt: 2026-04-27T00:00:00-03:00
lastModifiedAt: 2026-04-27T00:00:00-03:00
---

# SwiftLens Project Definition Pack

## 1. Product Concept

SwiftLens is a deterministic SwiftUI governance CLI for detecting architectural drift and project-governance violations before they reach review or CI.

SwiftLens is syntax-tree-first, machine-readable, and designed for CI execution.

## 2. Product Thesis

SwiftLens provides a missing enforcement layer between code changes and merge:

```text
code changes are written
→ SwiftLens inspects syntax and lightweight project metadata
→ deterministic governance findings are emitted
→ developers review targeted findings
→ CI blocks architectural regressions
```

## 3. V1 Scope Boundaries

SwiftLens V1:

- uses SwiftSyntax AST traversal only
- operates primarily on syntax trees, imports, paths, declarations, and lightweight project metadata
- uses deterministic heuristics
- produces advisory governance findings
- does not attempt semantic correctness
- does not attempt full architectural truth reconstruction

### Acceptable Heuristics

The following heuristics are acceptable in V1:

- naming conventions
- import inspection
- file path conventions
- configured ownership mappings
- route declaration discovery
- lightweight module boundary checks

### Explicitly Deferred

The following are explicitly deferred and not part of V1:

- plugin SDK
- dynamic rule loading
- IDE integration
- dashboard UI
- distributed governance systems
- persistent indexing
- build-system integration beyond CLI execution
- semantic architecture reconstruction

## 4. Forbidden Architectural Directions

SwiftLens must not move toward:

- type resolution
- symbol binding
- interprocedural analysis
- dataflow analysis
- ownership inference
- compiler-like semantic graphs
- inferred dependency topology
- transitive dependency governance
- runtime instrumentation
- source rewriting
- architecture auto-fix systems

## 5. Feature Admission Criteria

A feature is rejected unless it is:

- deterministic
- syntax-first
- CI-relevant
- fixture-testable
- maintainable by one engineer
- explainable via stable findings
- implementable without compiler infrastructure

## 6. Governance Philosophy

SwiftLens reports governance signals, not architectural truth.

A finding indicates:

- a deterministic heuristic match
- a potential governance concern
- an explainable rule outcome

A finding does NOT imply:

- semantic certainty
- runtime correctness
- architectural invalidity

## 7. Positioning

| Tool Category | SwiftLens Position |
| --- | --- |
| SwiftLint | Style and convention enforcement |
| SwiftFormat | Formatting |
| Periphery | Unused code detection |
| Xcode Analyzer | Compiler/static bug diagnostics |
| SwiftLens | SwiftUI governance findings from syntax-tree analysis |

## 8. Target Users

| User | Need |
| --- | --- |
| Indie SwiftUI developers | Prevent architectural drift |
| iOS teams | Enforce feature boundaries and navigation ownership |
| AI-heavy teams | Reduce code-review fatigue from boilerplate and overengineering |
| Alfred team | Enforce AppRouter, state ownership, localization, icon, and preview invariants |

## 9. V1 Goals

1. Detect SwiftUI architectural drift.
2. Detect overengineering and boilerplate patterns using deterministic heuristics.
3. Enforce project-specific governance through configurable policy packs.
4. Output compact machine-readable reports for CI and AI agents.
5. Provide human-readable Markdown reports on demand.

## 10. V1 Non-Goals

| Non-Goal | Reason |
| --- | --- |
| Replace SwiftLint | Style linting is already solved |
| Replace Periphery | Dead-code analysis is not the core product |
| Semantic correctness guarantees | SwiftLens does not attempt semantic truth reconstruction |
| Auto-fix architecture | Too risky for V1 |
| Generate code | SwiftLens is an auditor, not a coding agent |
| Parse governance docs automatically | This becomes fragile NLP instead of deterministic analysis |
| Provide GUI or dashboard | CLI-first is simpler and more automatable |
| Act as a plugin platform | V1 stays a single CLI executable |
| Provide hosted or SaaS services | V1 is local and CI-driven |
| Built-in packs only in V1 | External pack surfaces are deferred |

## 11. Product Name

**SwiftLens**

Rationale:

- works outside Alfred
- communicates visibility and diagnosis
- avoids naming the tool as a linter
- supports OSS-realistic positioning

Alternative internal name: **Alfred Lens** for Alfred-specific governance pack only.

---

# SwiftLens PRD v1

## 1. Objective

Build a deterministic, CLI-first SwiftUI governance tool that analyzes projects for architectural drift and configurable governance violations.

## 2. Primary Use Cases

| Use Case | Description |
| --- | --- |
| Local preflight | Developer runs SwiftLens before committing |
| CI enforcement | Pull requests fail on hard governance errors |
| Machine consumption | Agents receive compact deterministic findings |
| Architecture review | Reviewer receives compact report of structural risks |
| Alfred validation | Alfred-specific policy pack proves the model in a real codebase |

## 3. V1 User Stories

### 3.1 Developer

As a SwiftUI developer, I want SwiftLens to tell me when code violates governance boundaries so I can fix the issue before review.

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

## 4. Precision Philosophy

SwiftLens intentionally prefers transparent heuristics over opaque semantic analysis.

False precision is more dangerous than incomplete detection.

## 5. V1 Rule Packs

| Pack | Purpose | V1 Status |
| --- | --- | --- |
| `swiftui-core` | Generic SwiftUI architecture rules | Required |
| `ai-slop` | Overengineering, boilerplate, defensive-code, and comment noise rules | Required |
| `architecture` | Feature boundaries, ownership, dependency direction | Required |
| `alfred` | Alfred-specific governance rules | Required for Alfred validation |

## 5.1 V1 Completion Criteria

V1 is complete only when all required packs are implemented and validated:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

## 6. V1 Mandatory Rules

### 6.1 SwiftUI Core Pack

| Rule | Severity Default | Description |
| --- | --- | --- |
| `MassiveSwiftUIView` | warning | Flags SwiftUI views exceeding configured size or complexity thresholds |
| `NestedBodyComplexity` | warning | Flags overly complex `body` trees |
| `StateOwnershipDrift` | warning | Flags suspicious local state ownership in child views |
| `ViewModelBusinessLogicLeak` | warning | Flags business logic embedded in SwiftUI views |

### 6.2 AI Slop Pack

| Rule | Severity Default | Description |
| --- | --- | --- |
| `SingleUseProtocol` | advisory | Flags protocols with one implementation and no clear seam need |
| `PassThroughWrapper` | advisory | Flags functions or types that only forward calls without behavior |
| `EmptyAbstraction` | warning | Flags Manager, Provider, or Service shells with no meaningful logic |
| `CommentRestatesCode` | advisory | Flags comments that describe syntax rather than intent |
| `RedundantDefensiveGuard` | advisory | Flags defensive checks against impossible or already-enforced states |

### 6.3 Architecture Pack

| Rule | Severity Default | Description |
| --- | --- | --- |
| `CrossFeatureImport` | warning | Flags feature-to-feature imports outside allowed boundaries |
| `OrphanRoute` | warning | Flags route declarations with no reachable navigation path |
| `FeatureBoundaryViolation` | error | Flags ownership leakage across configured roots |
| `DuplicateOwnership` | error | Flags multiple owners for the same state domain when configured |

### 6.4 Alfred Pack

| Rule | Severity Default | Description |
| --- | --- | --- |
| `AppRouterOnly` | error | Navigation must flow through `AppRouter` |
| `SingleSourceOfTruth` | error | Prevent duplicated ownership of Home, Idea, or Recommendation state |
| `NoHardcodedUserStrings` | error | User-facing strings must use localization |
| `AlfredIconsOnly` | error | Production icons must go through `AlfredIcons` |
| `DebugOnlyPreviewData` | error | Preview and mock data must remain debug-only |
| `CallbackChildViews` | warning | Child views should expose callbacks instead of owning routing |
| `SendableDTOs` | warning | Touched DTOs should conform to `Sendable` where applicable |

## 7. Output Modes

| Mode | Purpose |
| --- | --- |
| `json` | CI and AI-agent consumption |
| `yaml` | AI-agent and human-readable structured output |
| `markdown` | PR/review summaries |
| `compact` | Minimal terminal summary |

## 8. Example Machine Output

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

## 9. Success Metrics

| Priority | Metric |
| --- | --- |
| 1 | Prevents architecture regressions |
| 2 | Finds stale or dead architectural flows |
| 3 | Reduces PR review time |
| 4 | Reduces AI-agent token usage |

## 10. Distribution

V1 distribution:

```text
Swift Package executable
```

Later distribution is intentionally undefined until V1 is complete.
