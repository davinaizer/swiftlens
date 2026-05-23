# SwiftLens Product Requirements Document

## Document Control

- Product: SwiftLens
- Version: v1
- Status: Draft
- Source inputs:
  - [SwiftLens-project-definition-pack.md](./SwiftLens-project-definition-pack.md)
  - [SwiftLens-project-action-plan.md](./SwiftLens-project-action-plan.md)

## 1. Product Summary

SwiftLens is a standalone deterministic Swift CLI that audits SwiftUI codebases for architectural drift and project-governance violations before review or CI.

It is CLI-first, CI-compatible, and optimized for machine-readable output.

## 1.1 Product Exclusions

SwiftLens V1 is not:

- a SaaS product
- a hosted control plane
- a web dashboard dependency
- a real-time architecture visualization tool
- an AI-assisted remediation system
- a conversational workflow system
- an auto-generated fixes system
- a plugin platform
- a generalized static analyzer
- a compiler toolchain replacement

## 2. Problem Statement

Modern SwiftUI teams can generate code faster than they can preserve architecture.

The failure mode is usually not a compiler error. It is:

- navigation bypassing the owning router
- duplicated state ownership
- overengineered wrappers and single-use abstractions
- hardcoded user-facing strings
- preview and mock data leaking into production paths
- architecture drift that is hard to review manually

SwiftLens exists to make these violations explicit, deterministic, and machine-actionable.

## 3. Product Thesis

SwiftLens provides the missing enforcement layer between code changes and merge:

1. Code changes are written.
2. SwiftLens audits syntax-derived structure and governance.
3. The tool emits compact findings with stable rule IDs and precise file/range metadata.
4. Developers, reviewers, and agents fix only the relevant surfaces.
5. CI blocks regressions when a hard rule is violated.

## 4. Goals

### 4.1 V1 Goals

- Detect SwiftUI architectural drift.
- Detect overengineering and boilerplate patterns using deterministic heuristics.
- Enforce project-specific governance through configurable policy packs.
- Produce compact machine-readable reports for CI and AI agents.
- Produce human-readable Markdown reports on demand.
- Provide deterministic local execution ergonomics for single-repo CLI use.
- Prefer deterministic heuristics over deep inference.
- Built-in packs only in V1.

### 4.2 Business Goals

- Reduce review time spent on avoidable architectural regressions.
- Reduce token waste for AI agents that otherwise need broad repo exploration.
- Make project governance executable instead of advisory.

## 5. Non-Goals

- Replace SwiftLint.
- Replace SwiftFormat.
- Replace Periphery.
- Replace the compiler or Xcode static analysis.
- Provide semantic correctness guarantees.
- Reconstruct full architecture truth.
- Auto-fix architecture in V1.
- Generate code.
- Parse governance prose automatically with NLP.
- Provide a GUI or dashboard.
- Provide runtime instrumentation.
- Provide IDE integration.
- Provide workspace discovery as a local configuration mechanism.
- Provide distributed governance.

## 6. Incremental Delivery Philosophy

- Milestones must be constrained and phase-gated.
- Growth must be deterministic and justified by actual repository behavior.
- Simplicity wins over extensibility when both satisfy the current phase.
- Speculative abstractions are rejected.
- Future usefulness is not sufficient justification for a new abstraction or capability.
- New scope must be earned by the current phase contract, not by anticipated future use.

## 7. Governance Doctrine

Features that require semantic reconstruction, inferred architectural truth, runtime understanding, or persistent graph infrastructure are out of scope for SwiftLens V1 and should be rejected by default.

## 8. Precision Philosophy

SwiftLens intentionally prefers transparent heuristics over opaque semantic analysis.

False precision is more dangerous than incomplete detection.

## 9. Target Users

| User | Need |
| --- | --- |
| Indie SwiftUI developers | Prevent architectural drift |
| iOS teams | Enforce feature boundaries and navigation ownership |
| AI-heavy teams | Reduce review fatigue from boilerplate and overengineering |
| Alfred team | Enforce AppRouter, state ownership, localization, icon, and preview invariants |

## 10. Primary Use Cases

| Use Case | Description |
| --- | --- |
| Local preflight | A developer runs SwiftLens before committing |
| CI enforcement | Pull requests fail on hard governance errors |
| AI coding guardrail | An agent receives exact rule violations instead of broad repo context |
| Architecture review | A reviewer receives a compact report of structural risks |
| Alfred validation | Alfred-specific policy pack validates the model on a real codebase |

## 11. Success Criteria

SwiftLens v1 is successful if:

- it finds real architectural violations in Alfred and comparable SwiftUI projects
- it reports findings with deterministic structure and stable rule IDs
- it blocks hard violations in CI with deterministic exit codes
- it reduces manual review effort by surfacing targeted, actionable issues

## 12. User Stories

### 12.1 Developer

As a SwiftUI developer, I want SwiftLens to tell me when code violates the architecture so I can fix the issue before review.

Acceptance criteria:

- the command exits non-zero on `error` violations
- each finding identifies file, range, rule, reason, and fix pattern
- output is readable without opening the full project manually

### 12.2 AI Agent

As an AI coding agent, I want compact JSON or YAML findings so I can fix only the relevant files and avoid wasting tokens on broad exploration.

Acceptance criteria:

- JSON and YAML output are deterministic
- every finding has a stable rule ID
- every finding includes precise file and range metadata

### 12.3 Reviewer

As a reviewer, I want a Markdown summary of architecture risks so I can focus review effort on meaningful issues.

Acceptance criteria:

- Markdown groups findings by severity and rule pack
- reports include project summary counts
- reports avoid essay-style commentary unless explicitly requested

### 12.4 Project Maintainer

As a maintainer, I want to map governance rules into executable config without hardcoding them into the tool.

Acceptance criteria:

- `.swiftlens.yml` defines project policy
- governance docs remain the human source of truth
- SwiftLens does not infer rules from prose in V1

## 13. Product Scope

### 13.1 Required Rule Packs

| Pack | Purpose | V1 Status |
| --- | --- | --- |
| `swiftui-core` | Generic SwiftUI architecture rules | Required |
| `ai-slop` | Overengineering, boilerplate, comment-noise, and defensive-code rules | Required |
| `architecture` | Feature boundaries, ownership, dependency direction | Required |
| `alfred` | Alfred-specific governance rules | Required for Alfred validation |

V1 uses built-in packs only; external pack surfaces are deferred.

### 13.2 Mandatory V1 Rules

#### SwiftUI Core

| Rule | Default Severity | Description |
| --- | --- | --- |
| `MassiveSwiftUIView` | warning | Flags SwiftUI views exceeding configured size or complexity thresholds |
| `NestedBodyComplexity` | warning | Flags overly complex `body` trees |
| `StateOwnershipDrift` | warning | Flags suspicious local state ownership in child views |
| `ViewModelBusinessLogicLeak` | warning | Flags business logic embedded in SwiftUI views |

#### AI Slop

| Rule | Default Severity | Description |
| --- | --- | --- |
| `SingleUseProtocol` | advisory | Flags protocols with one implementation and no clear seam need |
| `PassThroughWrapper` | advisory | Flags functions or types that only forward calls without behavior |
| `EmptyAbstraction` | warning | Flags Manager, Provider, or Service shells with no meaningful logic |
| `CommentRestatesCode` | advisory | Flags comments that describe syntax rather than intent |
| `RedundantDefensiveGuard` | advisory | Flags defensive checks against impossible or already-enforced states |

#### Architecture

| Rule | Default Severity | Description |
| --- | --- | --- |
| `CrossFeatureImport` | warning | Flags feature-to-feature imports outside allowed boundaries |
| `OrphanRoute` | warning | Flags route declarations with no reachable navigation path |
| `FeatureBoundaryViolation` | error | Flags ownership leakage across configured roots |
| `DuplicateOwnership` | error | Flags multiple owners for the same state domain when configured |

#### Alfred

| Rule | Default Severity | Description |
| --- | --- | --- |
| `AppRouterOnly` | error | Navigation must flow through `AppRouter` |
| `SingleSourceOfTruth` | error | Prevent duplicated ownership of Home, Idea, or Recommendation state |
| `NoHardcodedUserStrings` | error | User-facing strings must use localization |
| `AlfredIconsOnly` | error | Production icons must go through `AlfredIcons` |
| `DebugOnlyPreviewData` | error | Preview and mock data must remain debug-only |
| `CallbackChildViews` | warning | Child views should expose callbacks instead of owning routing |
| `SendableDTOs` | warning | Touched DTOs should conform to `Sendable` where applicable |

### 13.3 Configurable Scope

- project root or scan root
- include and exclude glob patterns
- enabled and disabled packs
- per-rule enablement
- per-rule severity overrides
- per-rule configuration parameters

### 13.4 Local Developer DX

SwiftLens supports a narrow local-only execution path for deterministic day-to-day use.

- `swiftlens` defaults to `scan .`
- `swiftlens scan` defaults to `.`
- omitted `--config` resolves `.swiftlens.yml` from the current working directory only
- explicit `--config` overrides local lookup
- omitted `--format` defaults to `json`
- missing config exits with code `2`

This is local deterministic DX only. It does not authorize parent-directory traversal, nested configs, config inheritance, remote configs, global user configs, environment-aware config resolution, workspace discovery, IDE integration, SwiftPM plugins, Xcode plugins, or autofix/autocorrect.

## 14. Output Modes

| Mode | Purpose |
| --- | --- |
| `json` | CI and AI-agent consumption |
| `yaml` | Structured output for AI agents and humans |
| `markdown` | PR and review summaries |
| `compact` | Minimal terminal summary |

## 15. Exit-Code Contract

| Condition | Exit Code |
| --- | --- |
| Success | 0 |
| Advisory only | 0 |
| Error violations | 1 |
| Config issue | 2 |
| Internal failure | 3 |

## 16. Configuration Contract

`.swiftlens.yml` is the executable policy source. Governance prose is not parsed in V1.

Required validation:

- missing fields
- invalid severity values
- invalid paths
- invalid rule config
- unknown keys
- invalid pack names
- invalid rule IDs

Precedence:

1. Explicit project config has highest precedence.
2. Later pack defaults override earlier pack defaults.
3. Earlier pack defaults override preset-owned fallback defaults, if any.
4. Preset-owned fallback defaults override built-in rule defaults.
5. Built-in rule defaults establish the lowest base severity and config.
6. `rules.<rule>.severity` and `rules.<rule>.config` remain deterministic override inputs within the explicit project config layer.
7. CLI flags affect execution scope and reporter selection only.

## 17. Release Criteria

SwiftLens v1 is releasable when:

- the executable CLI ships as a Swift package
- the required rule packs are implemented or explicitly deferred with documented rationale
- the reporter outputs are stable
- exit codes match the contract
- the tool has been validated on Alfred or an equivalent real SwiftUI codebase

## 18. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| False positives | Low trust, noisy CI | Start with deterministic syntax signals and validate on real code |
| Weak architecture inference | Missed violations | Use project-specific config and declaration records |
| Scope creep | Delayed release | Freeze V1 scope and reject auto-fix / NLP / GUI work |
| Overfitting to Alfred | Poor generalization | Keep generic packs separate from Alfred-specific policy |
