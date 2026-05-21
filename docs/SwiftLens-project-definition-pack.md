---
title: SwiftLens Project Definition Pack
status: draft
createdAt: 2026-04-27T00:00:00-03:00
lastModifiedAt: 2026-05-21T00:00:00-03:00
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
- supports deterministic local execution ergonomics without hierarchy-based config discovery
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
- workspace discovery as a config-resolution mechanism
- dashboard UI
- distributed governance systems
- persistent indexing
- build-system integration beyond CLI execution
- semantic architecture reconstruction
- parent-directory traversal for config lookup
- nested config inheritance
- remote or global user config lookup
- environment-aware config resolution
- autofix or autocorrect

## 4. Repository-Governed Implementation Doctrine

- Repository docs govern implementation.
- Prompts only initiate work.
- Prompts cannot redefine architecture.
- Prompts cannot bypass the phase contract.
- The authoritative phase contract lives in [SwiftLens-project-action-plan.md](./SwiftLens-project-action-plan.md).
- If a prompt conflicts with repository docs, the docs win.

## 5. Phase Transition Rules

1. A phase begins only when the previous phase has met its exit criteria.
2. A phase does not authorize capabilities outside its allowed scope.
3. Later phases do not retroactively justify earlier-phase shortcuts.
4. Semantic analysis, plugin systems, platform ambitions, and compiler infrastructure remain rejected unless a later phase explicitly and narrowly permits them.
5. Any new abstraction must be justified by repeated operational need, not speculative future use.

## 6. Complexity Escalation Policy

- Start with direct orchestration.
- Avoid premature abstractions.
- Avoid protocol hierarchies unless they remove operational duplication or enforce a real invariant.
- Defer sophistication until repetition proves that a shared abstraction is worth the maintenance cost.
- Keep the simplest concrete implementation that satisfies the current phase.

## 7. Forbidden Architectural Directions

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

## 8. Feature Admission Criteria

A feature is rejected unless it is:

- deterministic
- syntax-first
- CI-relevant
- fixture-testable
- maintainable by one engineer
- explainable via stable findings
- implementable without compiler infrastructure

## 9. Governance Philosophy

SwiftLens reports governance signals, not architectural truth.

A finding indicates:

- a deterministic heuristic match
- a potential governance concern
- an explainable rule outcome

A finding does NOT imply:

- semantic certainty
- runtime correctness
- architectural invalidity

## 10. Positioning

| Tool Category | SwiftLens Position |
| --- | --- |
| SwiftLint | Style and convention enforcement |
| SwiftFormat | Formatting |
| Periphery | Unused code detection |
| Xcode Analyzer | Compiler/static bug diagnostics |
| SwiftLens | SwiftUI governance findings from syntax-tree analysis |

## 11. Target Users

| User | Need |
| --- | --- |
| Indie SwiftUI developers | Prevent architectural drift |
| iOS teams | Enforce feature boundaries and navigation ownership |
| AI-heavy teams | Reduce code-review fatigue from boilerplate and overengineering |
| Alfred team | Enforce AppRouter, state ownership, localization, icon, and preview invariants |

## 12. V1 Goals

1. Detect SwiftUI architectural drift.
2. Detect overengineering and boilerplate patterns using deterministic heuristics.
3. Enforce project-specific governance through configurable policy packs.
4. Output compact machine-readable reports for CI and AI agents.
5. Provide human-readable Markdown reports on demand.

## 13. V1 Non-Goals

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

## 14. Product Name

**SwiftLens**

Rationale:

- works outside Alfred
- communicates visibility and diagnosis
- avoids naming the tool as a linter
- supports OSS-realistic positioning

Alternative internal name: **Alfred Lens** for Alfred-specific governance pack only.
