# SwiftLens Product Requirements Document

## Document Control

- Product: SwiftLens
- Version: v1
- Status: Draft
- Source inputs:
  - [SwiftLens-project-definition-pack.md](./SwiftLens-project-definition-pack.md)
  - [SwiftLens-project-action-plan.md](./SwiftLens-project-action-plan.md)

## 1. Product Summary

SwiftLens is a standalone Swift CLI that audits SwiftUI codebases for architectural drift, AI-generated code slop, and project-governance violations before review or CI.

It is not a formatter, style linter, dead-code analyzer, code generator, or GUI dashboard.

## 2. Problem Statement

Modern SwiftUI teams, especially AI-heavy teams, can generate code faster than they can preserve architecture.

The failure mode is not usually a compiler error. It is:

- navigation bypassing the owning router
- duplicated state ownership
- overengineered wrappers and single-use abstractions
- hardcoded user-facing strings
- preview and mock data leaking into production paths
- architecture drift that is hard to review manually

SwiftLens exists to make these violations explicit, deterministic, and machine-actionable.

## 3. Product Thesis

SwiftLens provides the missing enforcement layer between code generation and merge:

1. AI or a developer writes code.
2. SwiftLens audits structure and governance.
3. The tool emits compact findings with stable rule IDs and precise file/range metadata.
4. Developers, reviewers, and agents fix only the relevant surfaces.
5. CI blocks regressions when a hard rule is violated.

## 4. Goals

### 4.1 V1 Goals

- Detect SwiftUI architectural drift.
- Detect AI-generated overengineering and boilerplate patterns.
- Enforce project-specific governance through configurable policy packs.
- Produce compact machine-readable reports for CI and AI agents.
- Produce human-readable Markdown reports on demand.

### 4.2 Business Goals

- Reduce review time spent on avoidable architectural regressions.
- Reduce token waste for AI agents that otherwise need broad repo exploration.
- Make project governance executable instead of advisory.

## 5. Non-Goals

- Replace SwiftLint.
- Replace SwiftFormat.
- Replace Periphery.
- Replace the compiler or Xcode static analysis.
- Auto-fix architecture in V1.
- Generate code.
- Parse governance prose automatically with NLP.
- Provide a GUI or dashboard.

## 6. Target Users

| User | Need |
| --- | --- |
| Indie SwiftUI developers | Prevent messy AI-generated architecture |
| iOS teams | Enforce feature boundaries and navigation ownership |
| AI-heavy teams | Reduce review fatigue from boilerplate and overengineering |
| Alfred team | Enforce AppRouter, state ownership, localization, icon, and preview invariants |

## 7. Primary Use Cases

| Use Case | Description |
| --- | --- |
| Local preflight | A developer runs SwiftLens before committing |
| AI coding guardrail | An agent receives exact rule violations instead of broad repo context |
| CI enforcement | Pull requests fail on hard governance errors |
| Architecture review | A reviewer receives a compact report of structural risks |
| Alfred validation | Alfred-specific policy pack validates the model on a real codebase |

## 8. Success Criteria

SwiftLens v1 is successful if:

- it finds real architectural violations in Alfred and comparable SwiftUI projects
- it reports findings with deterministic structure and stable rule IDs
- it blocks hard violations in CI with deterministic exit codes
- it reduces manual review effort by surfacing targeted, actionable issues

## 9. User Stories

### 9.1 Developer

As a SwiftUI developer, I want SwiftLens to tell me when AI-generated code violates the architecture so I can fix the issue before review.

Acceptance criteria:

- the command exits non-zero on `error` violations
- each finding identifies file, range, rule, reason, and fix pattern
- output is readable without opening the full project manually

### 9.2 AI Agent

As an AI coding agent, I want compact JSON or YAML findings so I can fix only the relevant files and avoid wasting tokens on broad exploration.

Acceptance criteria:

- JSON and YAML output are deterministic
- every finding has a stable rule ID
- every finding includes precise file and range metadata

### 9.3 Reviewer

As a reviewer, I want a Markdown summary of architecture risks so I can focus review effort on meaningful issues.

Acceptance criteria:

- Markdown groups findings by severity and rule pack
- reports include project summary counts
- reports avoid essay-style commentary unless explicitly requested

### 9.4 Project Maintainer

As a maintainer, I want to map governance rules into executable config without hardcoding them into the tool.

Acceptance criteria:

- `.swiftlens.yml` defines project policy
- governance docs remain the human source of truth
- SwiftLens does not infer rules from prose in V1

## 10. Product Scope

### 10.1 Required Rule Packs

| Pack | Purpose | V1 Status |
| --- | --- | --- |
| `swiftui-core` | Generic SwiftUI architecture rules | Required |
| `ai-slop` | Overengineering, boilerplate, comment-noise, and defensive-code rules | Required |
| `architecture` | Feature boundaries, ownership, dependency direction | Required |
| `alfred` | Alfred-specific governance rules | Required for Alfred validation |

### 10.2 Mandatory V1 Rules

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

### 10.3 Configurable Scope

- project root or scan root
- include and exclude glob patterns
- enabled and disabled packs
- per-rule enablement
- per-rule severity overrides
- per-rule configuration parameters

## 11. Output Modes

| Mode | Purpose |
| --- | --- |
| `json` | CI and AI-agent consumption |
| `yaml` | Structured output for AI agents and humans |
| `markdown` | PR and review summaries |
| `compact` | Minimal terminal summary |

## 12. Exit-Code Contract

| Condition | Exit Code |
| --- | --- |
| Success | 0 |
| Advisory only | 0 |
| Error violations | 1 |
| Config issue | 2 |
| Internal failure | 3 |

## 13. Configuration Contract

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

1. Built-in rule defaults establish base severity and config.
2. `packs.<pack>.severityOverrides` overrides built-in severity for rules in that pack.
3. `rules.<rule>.severity` overrides both built-in severity and pack-level severity.
4. `rules.<rule>.config` merges over built-in rule config; unknown keys fail validation.
5. CLI flags affect execution scope and reporter selection only.

## 14. Release Criteria

SwiftLens v1 is releasable when:

- the executable CLI ships as a Swift package
- the required rule packs are implemented or explicitly deferred with documented rationale
- the reporter outputs are stable
- exit codes match the contract
- the tool has been validated on Alfred or an equivalent real SwiftUI codebase

## 15. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| False positives | Low trust, noisy CI | Start with deterministic syntax signals and validate on real code |
| Weak architecture inference | Missed violations | Use project-specific config and declaration/index data |
| Scope creep | Delayed release | Freeze V1 scope and reject auto-fix / NLP / GUI work |
| Overfitting to Alfred | Poor generalization | Keep generic packs separate from Alfred-specific policy |
| Reporter bloat | Harder AI consumption | Keep machine output compact and stable |

## 16. V1 Boundary Statement

V1 is not complete until the required pack set is available:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

Implementation order may be staged, but product completeness depends on the full set.
