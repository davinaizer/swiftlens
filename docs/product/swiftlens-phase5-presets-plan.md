# **Phase 5: Governance Presets & Opinionated Rule Packs**

## **Summary**

Phase 5 introduces governance presets and opinionated rule packs to dramatically improve SwiftLens onboarding and developer experience.

The goal is to let teams adopt architectural governance quickly without manually authoring every rule from scratch, while preserving SwiftLens’ core philosophy:

- deterministic
- syntax-first
- lightweight
- explicit
- governance-focused

Phase 5 positions SwiftLens closer to:

- SwiftLint rule sets
- ESLint shared configs
- Biome presets
- Ruff rule groups

while explicitly avoiding:

- semantic architecture inference
- compiler-grade analysis
- plugin ecosystems
- runtime extensibility
- generalized static-analysis platform ambitions

---

# **Problem Statement**

Current SwiftLens adoption requires teams to:

1. identify governance rules manually
2. map architecture to filesystem boundaries
3. author explicit rule configuration

While operationally correct, this creates onboarding friction.

Example:

```yaml
rules:
  - architecture.forbidden-import

architecture:
  forbiddenImports:
    - from: Features/
      imports:
        - Infrastructure
```

This scales poorly for:

- new teams
- smaller projects
- early adoption
- governance experimentation

SwiftLint succeeds partly because:

- many defaults are already accepted industry conventions
- teams customize incrementally rather than starting from zero

Architecture governance is more contextual than style linting, so SwiftLens should not ship universal architecture “truths.”

Instead, SwiftLens should provide curated governance presets.

---

# **Goals**

## **Primary Goals**

- reduce onboarding friction
- provide production-ready governance defaults
- accelerate adoption
- encode common architectural patterns
- preserve deterministic behavior
- preserve explicit configuration

## **Non-Goals**

- semantic ownership inference
- automatic architecture discovery
- dependency graph reconstruction
- runtime plugin systems
- dynamic preset downloads
- generalized framework generation

---

# **Core Design**

## **Governance Presets**

SwiftLens introduces curated preset packs:

```yaml
extends:
  - swiftlens:clean-architecture
```

A preset activates:

- rule groups
- recommended defaults
- common path-boundary mappings
- architecture conventions

while remaining fully overrideable.

---

# **Initial Preset Candidates**

| **Preset**         | **Audience**                |
| ------------------ | --------------------------- |
| clean-architecture | layered apps                |
| feature-modular    | modular SwiftUI apps        |
| mvvm               | traditional UIKit/SwiftUI   |
| tca                | The Composable Architecture |
| package-oriented   | SwiftPM-first repos         |

---

# **Example Preset**

## **Clean Architecture**

```yaml
extends:
  - swiftlens:clean-architecture
```

Internally expands into:

```yaml
rules:
  - architecture.forbidden-import

architecture:
  forbiddenImports:
    - from: Presentation/
      imports:
        - Persistence

    - from: Features/
      imports:
        - Infrastructure
```

Projects may override or extend:

```yaml
architecture:
  forbiddenImports:
    - from: Features/
      imports:
        - LegacyNetworking
```

---

# **Preset Resolution Model**

## **Deterministic Expansion**

Preset resolution must be:

- local
- static
- deterministic
- versioned with the binary

No:

- remote fetching
- package registries
- runtime downloads
- plugin execution

Preset expansion occurs before rule evaluation.

---

# **Configuration Model**

## **Proposed Shape**

```yaml
extends:
  - swiftlens:feature-modular

rules:
  - architecture.forbidden-import
```

Rules remain explicit.

Presets provide:

- defaults
- recommendations
- mappings

Projects remain authoritative.

---

# **Implementation Strategy**

## **Phase 5A — Built-In Presets**

Deliver:

- built-in preset registry
- deterministic preset expansion
- static preset definitions
- fixture-backed preset tests

No user-defined preset system yet.

---

## **Phase 5B — Preset Overrides**

Add:

- local override merging
- additive forbidden import rules
- deterministic merge precedence

---

## **Phase 5C — Preset Tooling**

Potential future tooling:

```bash
swiftlens init
swiftlens preset list
swiftlens preset explain clean-architecture
```

Still:

- local-only
- deterministic
- non-plugin-based

---

# **Determinism Requirements**

All preset behavior must preserve:

| **Requirement**         | **Constraint** |
| ----------------------- | -------------- |
| stable rule ordering    | mandatory      |
| stable merge precedence | mandatory      |
| stable serialization    | mandatory      |
| stable diagnostics      | mandatory      |
| local-only resolution   | mandatory      |

---

# **Test Plan**

## **Preset Expansion**

- preset resolves deterministically
- preset ordering remains stable
- duplicate rules deduplicate deterministically
- override precedence is stable

## **Governance Behavior**

- preset-generated rules execute normally
- explicit config overrides preset defaults
- invalid preset names fail with exit code `2`

## **CLI Validation**

- deterministic JSON output preserved
- CLI behavior unchanged
- existing rule registry behavior preserved

---

# **Architectural Constraints**

Phase 5 must not introduce:

- semantic analysis
- dependency graphs
- ownership systems
- cache/index infrastructure
- runtime plugin loading
- remote registries
- AI architecture inference
- generalized lint-engine ambitions

---

# **Product Positioning**

Phase 5 evolves SwiftLens from:

“a configurable governance engine”

toward:

“an opinionated architecture governance toolkit.”

without compromising:

- determinism
- explicitness
- lightweight execution
- operational clarity

---

# **Reference Inspirations**

Useful conceptual references:

- SwiftLint![Attachment.tiff](file:///Attachment.tiff)
- ESLint Shared Configs![Attachment.tiff](file:///Attachment.tiff)
- Biome Rule Groups![Attachment.tiff](file:///Attachment.tiff)
- Ruff Rule Architecture![Attachment.tiff](file:///Attachment.tiff)

These are inspiration references only.

SwiftLens explicitly remains:

- syntax-first
- deterministic
- governance-focused
- non-semantic
- non-plugin-based
