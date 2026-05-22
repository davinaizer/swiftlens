# Phase 5: Governance Presets & Opinionated Rule Packs

## Summary

Phase 5 turns SwiftLens from a configurable governance engine into an opinionated architecture governance toolkit.

The objective is to reduce onboarding friction by shipping built-in presets and rule packs based on common Swift/iOS architecture patterns, while preserving SwiftLens’ core constraints:

- deterministic
- syntax-first
- lightweight
- explicit
- local-only
- governance-focused

The deep research validates that SwiftLens should not ship one universal architecture default. Modern Swift codebases vary too much. Instead, SwiftLens should ship a small set of curated presets that reflect common, operationally enforceable project shapes.

The strongest initial direction is:

| Priority | Preset            | Target audience                         |
| -------- | ----------------- | --------------------------------------- |
| MVP      | `app-layers`      | single-target or lightly modular apps   |
| MVP      | `feature-modules` | scalable feature/package-oriented apps  |
| MVP      | `tca-features`    | SwiftUI/TCA reducer-first teams         |
| Future   | `clean-modules`   | strict layered/Clean Architecture teams |
| Future   | `vertical-slices` | feature/use-case slice architectures    |
| Future   | `ddd-contexts`    | domain-heavy enterprise apps            |
| Future   | `uikit-viper`     | legacy UIKit/VIPER codebases            |

Phase 5 must be implemented incrementally. Presets are product-facing defaults, so correctness, explainability, and low false-positive rates matter more than rule volume.

---

## Research Findings

### Main Finding

The dominant real-world Swift architecture is not pure Clean Architecture, VIPER, or textbook MVC.

The most common scalable pattern is a hybrid:

- feature-oriented or package-oriented modularization
- light layering inside each feature/module
- SwiftUI/MVVM-style state holders or TCA-style reducers
- shared/core/design-system/platform modules
- explicit dependency boundaries enforced socially in PR reviews

This maps well to SwiftLens because many of these rules can be enforced using:

- file paths
- import declarations
- naming conventions
- shallow syntax-tree inspection
- deterministic heuristics

### What SwiftLens Should Enforce

| Governance type             | Fit         | Reason                         |
| --------------------------- | ----------- | ------------------------------ |
| forbidden imports           | High        | syntax + path detectable       |
| feature isolation           | High        | path-boundary detectable       |
| layer direction             | High        | path + import detectable       |
| UI/framework leakage        | High        | import detectable              |
| test-only boundaries        | High        | path + import detectable       |
| public API surface checks   | Medium      | syntax detectable, more nuance |
| naming/location conventions | Medium      | useful but can be noisy        |
| dependency cycles           | Low for now | requires graph infrastructure  |
| inferred ownership          | No          | violates syntax-first scope    |
| runtime dependency behavior | No          | non-deterministic/out of scope |

### Product Finding

SwiftLens’ strongest positioning is:

> SwiftLint-level developer experience for architecture governance.

That means:

- useful defaults
- quick initialization
- clear diagnostics
- deterministic output
- easy CI adoption
- project-specific customization only when needed

---

## Problem Statement

Current SwiftLens adoption requires teams to:

1. identify stable architecture rules
2. map architecture to filesystem boundaries
3. author explicit rule configuration manually

That is operationally correct, but it is not ideal DX.

Architecture governance is more contextual than style linting, so SwiftLens should not ship universal architecture truth. Instead, it should ship curated presets that encode common project shapes and let users customize from there.

---

## Goals

### Primary Goals

- reduce onboarding friction
- provide ready-to-use governance defaults
- encode common Swift architecture patterns
- support quick project initialization
- preserve deterministic behavior
- keep presets explainable
- minimize false positives

### Non-Goals

- semantic ownership inference
- automatic architecture discovery beyond deterministic path inspection
- dependency graph reconstruction
- runtime plugin systems
- dynamic preset downloads
- remote preset registries
- generalized framework generation
- AI architecture inference

---

## Core Product Model

SwiftLens should separate four concepts:

| Concept        | Purpose                                |
| -------------- | -------------------------------------- |
| preset         | opinionated architecture template      |
| rule pack      | grouped rules for a governance concern |
| rule           | executable deterministic check         |
| project config | local customization and overrides      |

Example future config:

```yaml
version: 1
preset: feature-modules

roots:
  - Sources

rulePacks:
  - boundary-core
  - layer-separation
  - testing-boundaries
```

Presets are built into the binary and expand locally before rule evaluation.

---

## MVP Presets

### `app-layers`

For single-target or lightly modular apps using broad folders such as:

```text
App/
UI/
Domain/
Data/
Shared/
```

Default governance intent:

| Rule area        | Example                                                   |
| ---------------- | --------------------------------------------------------- |
| layer direction  | UI should not import Data directly                        |
| domain purity    | Domain should not import SwiftUI, UIKit, AppKit, CoreData |
| shared stability | Shared should not import app/features                     |
| test isolation   | production code should not import test helpers            |

Why MVP:

- easiest onboarding
- low false-positive risk
- useful for existing apps
- bridges non-modular projects toward governance

### `feature-modules`

For scalable feature-oriented apps using folders or packages such as:

```text
App/
Features/Auth/
Features/Profile/
Shared/
Core/
DesignSystem/
Platform/
```

Default governance intent:

| Rule area         | Example                                                   |
| ----------------- | --------------------------------------------------------- |
| feature isolation | Features/Auth should not import Features/Profile          |
| composition root  | App may import features                                   |
| shared direction  | Shared/Core should not import Features/App                |
| platform leakage  | feature domain code should not import platform frameworks |

Why MVP:

- strongest fit for large teams
- matches modern modular Swift/iOS practice
- directly supports architecture drift prevention

### `tca-features`

For SwiftUI projects using The Composable Architecture or reducer-first feature structure.

Common shape:

```text
App/
Features/Auth/AuthFeature.swift
Features/Auth/AuthView.swift
Features/Auth/AuthClient.swift
Shared/
Dependencies/
```

Default governance intent:

| Rule area             | Example                                                        |
| --------------------- | -------------------------------------------------------------- |
| reducer isolation     | reducers should avoid UI/infrastructure imports unless allowed |
| feature boundaries    | sibling feature imports are restricted                         |
| dependency clients    | dependencies live in approved client/dependency zones          |
| view/reducer location | naming/location conventions are checked conservatively         |

Why MVP:

- distinct and common enough to justify a preset
- structure is explicit
- many useful checks are syntax/path detectable

---

## Future Presets

| Preset            | Rationale                                                | Risk                                     |
| ----------------- | -------------------------------------------------------- | ---------------------------------------- |
| `clean-modules`   | strong architecture model; maps well to import direction | many teams rename layers differently     |
| `vertical-slices` | highly enforceable path isolation                        | less standardized in Swift community     |
| `ddd-contexts`    | useful for enterprise/domain-heavy apps                  | requires mature docs and ownership model |
| `uikit-viper`     | useful for legacy UIKit teams                            | niche; naming-heavy; higher noise risk   |

Future presets should be added only after the MVP preset engine, explainability, and baseline workflows are stable.

---

## Rule Packs

### MVP Rule Packs

| Rule pack            | Purpose                               | Include in MVP      |
| -------------------- | ------------------------------------- | ------------------- |
| `boundary-core`      | path/import boundary rules            | Yes                 |
| `layer-separation`   | layer direction and framework leakage | Yes                 |
| `testing-boundaries` | test-only import rules                | Yes                 |
| `api-surface`        | public/open/package API checks        | Maybe, conservative |

### Future Rule Packs

| Rule pack             | Purpose                                 | Timing                           |
| --------------------- | --------------------------------------- | -------------------------------- |
| `naming-conventions`  | suffix/path alignment                   | Future/opt-in                    |
| `preview-and-example` | SwiftUI preview/example isolation       | Future                           |
| `legacy-migration`    | baseline and regressions-only workflows | High-value future engine feature |

---

## Configuration Model

### Short-Term Shape

Presets should be simple and static:

```yaml
version: 1
preset: feature-modules
```

Optional explicit rule enablement remains supported:

```yaml
rules:
  - architecture.forbidden-import
```

### Medium-Term Shape

Add rule packs:

```yaml
version: 1
preset: feature-modules

rulePacks:
  - boundary-core
  - layer-separation
```

### Long-Term Shape

Add zones only after the simple model is stable:

```yaml
zones:
  - id: Shared
    paths:
      - Shared/
      - Core/
      - DesignSystem/

  - id: Feature
    autoDiscover:
      roots:
        - Features
      depth: 1
```

Do not introduce this full schema in the first Phase 5 implementation.

---

## Preset Resolution Model

Preset resolution must be:

- local
- static
- deterministic
- versioned with the binary
- independent of the network

Preset expansion order:

1. load project config
2. resolve built-in preset
3. resolve built-in rule packs
4. merge local overrides
5. validate final config
6. execute rules in stable order

No:

- remote fetching
- package registries
- runtime downloads
- plugin execution
- user-defined preset scripts

---

## Implementation Plan

Phase 5 is intentionally split into smaller implementation chunks.

### Phase 5A — Preset Registry Foundation

Deliver:

- built-in preset registry
- stable preset IDs
- validation for unknown preset names
- deterministic preset expansion
- tests for preset lookup and expansion

Initial IDs:

```text
app-layers
feature-modules
tca-features
```

Do not add advanced merging yet.

### Phase 5B — MVP Preset Definitions

Deliver:

- static definitions for the three MVP presets
- generated `rules` lists
- generated `architecture.forbiddenImports` entries where safe
- fixture-backed tests per preset

Keep defaults conservative.

### Phase 5C — Rule Pack Registry

Deliver:

- built-in rule pack registry
- stable rule pack IDs
- deterministic rule-pack expansion
- duplicate rule deduplication
- conflict validation

Initial packs:

```text
boundary-core
layer-separation
testing-boundaries
```

### Phase 5D — Project Overrides

Deliver:

- local config overrides for preset-generated config
- deterministic merge precedence
- tests for override behavior

Precedence:

| Source                  | Priority |
| ----------------------- | -------- |
| explicit project config | highest  |
| rule packs              | middle   |
| preset defaults         | lowest   |

### Phase 5E — Init UX

Deliver:

```bash
swiftlens init
swiftlens init --preset feature-modules
```

Requirements:

- generate `.swiftlens.yml`
- never overwrite without explicit confirmation or force flag
- keep generated config minimal
- document what preset was chosen

### Phase 5F — Explainability UX

Deliver:

```bash
swiftlens preset list
swiftlens preset explain feature-modules
swiftlens rule explain architecture.forbidden-import
```

Purpose:

- improve trust
- reduce config confusion
- make presets auditable

### Phase 5G — Baseline / Regression Workflow

Deliver later:

```bash
swiftlens baseline create
swiftlens scan --baseline .swiftlens/baseline.json
```

Purpose:

- allow adoption in existing large apps
- support report-only rollout
- prevent new violations before old ones are fixed

This is high-value but should not block the MVP preset registry.

### Phase 5H — Boundary Inspection

Deliver later:

```bash
swiftlens boundary list
```

Purpose:

- show discovered zones/features
- help users understand what SwiftLens thinks the architecture is
- inspired by Fallow’s boundary-listing UX

---

## Determinism Requirements

All preset behavior must preserve:

| Requirement              | Constraint |
| ------------------------ | ---------- |
| stable preset expansion  | mandatory  |
| stable rule ordering     | mandatory  |
| stable merge precedence  | mandatory  |
| stable config validation | mandatory  |
| stable serialization     | mandatory  |
| stable diagnostics       | mandatory  |
| local-only resolution    | mandatory  |

---

## Test Plan

### Preset Registry Tests

- known preset resolves
- unknown preset fails with exit code `2`
- preset expansion is deterministic
- preset IDs are stable

### Rule Pack Tests

- known pack resolves
- unknown pack fails with exit code `2`
- duplicate rules deduplicate deterministically
- pack expansion preserves stable order

### Preset Behavior Tests

- `app-layers` enforces basic layer rules
- `feature-modules` enforces sibling-feature isolation
- `tca-features` enforces conservative reducer/feature boundaries
- explicit config overrides preset defaults

### CLI Tests

- `swiftlens init` creates expected config
- `swiftlens preset list` output is stable
- `swiftlens preset explain` output is stable
- existing scan behavior remains unchanged

---

## Fallow-Inspired DX Ideas

Fallow is the closest inspiration reference because it treats architecture governance as a first-class product problem.

Concepts worth adapting:

| Fallow concept           | SwiftLens adaptation                  |
| ------------------------ | ------------------------------------- |
| tailored init            | `swiftlens init --preset ...`         |
| zones/boundaries         | deterministic path zones later        |
| list boundaries          | `swiftlens boundary list` later       |
| baselines                | regression-only rollout later         |
| syntactic analysis limit | preserve SwiftLens syntax-first scope |

Do not copy:

- broad unused-file/export analysis
- circular dependency graph analysis for now
- framework plugin discovery
- generalized monorepo intelligence
- runtime extensibility

SwiftLens should borrow the DX philosophy, not the full complexity envelope.

---

## Architectural Constraints

Phase 5 must not introduce:

- semantic analysis
- dependency graphs
- ownership systems
- cache/index infrastructure
- runtime plugin loading
- remote registries
- AI architecture inference
- generalized lint-engine ambitions

If a preset requires those capabilities, it is not eligible for Phase 5 MVP.

---

## Product Positioning

Phase 5 should position SwiftLens as:

> SwiftLint-level DX for architecture governance.

More specifically:

> A deterministic, Swift-native tool that helps teams enforce architecture boundaries without building compiler-grade analysis infrastructure.

This is the product gap SwiftLens can own.

---

## Reference Inspirations

Useful conceptual references:

- SwiftLint: https://github.com/realm/SwiftLint
- ESLint configuration: https://eslint.org/docs/latest/use/configure/configuration-files
- Biome linter: https://biomejs.dev/linter/
- Ruff: https://docs.astral.sh/ruff/
- Fallow: https://github.com/fallow-rs/fallow
- dependency-cruiser: https://github.com/sverweij/dependency-cruiser
- Nx module boundary rules: https://nx.dev/features/enforce-module-boundaries
- ArchUnit: https://www.archunit.org/

These are inspiration references only.

SwiftLens remains:

- Swift-focused
- syntax-first
- deterministic
- governance-focused
- non-semantic
- non-plugin-based
