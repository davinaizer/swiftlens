# SwiftLens Work Plan

## Current Objective

Harden V1 documentation so every core doc states the same constrained scope:

- deterministic
- syntax-tree-first
- CI-compatible
- stable rule IDs
- heuristics over semantic reconstruction
- maintainable by one engineer

## Active Work

1. Rewrite the five requested docs to remove ambiguous or platform-oriented language.
2. Keep governance and product boundaries aligned across README, PRD, TAD, definition pack, and action plan.
3. Verify no document introduces plugin, dashboard, daemon, semantic, or auto-fix scope.

## Rejection Rules

Reject any proposed feature unless it is:

- deterministic
- syntax-first
- CI-relevant
- fixture-testable
- maintainable by one engineer
- explainable via stable findings
- implementable without compiler infrastructure
