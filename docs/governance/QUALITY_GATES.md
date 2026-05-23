# Quality Gates

## Purpose

Define the minimum checks required before merge, phase closure, or release.

## Required Gates

- `docs/prd.md` and `docs/tad.md` must remain canonical and internally consistent.
- The active phase must be explicit in `PLANS.md` before implementation begins.
- Phase 2 and later work must follow TDD by default.
- Relevant tests must fail first, then pass after the smallest code change.
- `swiftlint lint` must pass before merge, phase closure, rule additions, config changes, reporter changes, and workflow/doc changes that affect Swift source or Swift tests.
- `swift test` must pass before merge, phase closure, rule additions, config changes, and reporter changes.
- Fixture-backed tests must cover file- or project-dependent behavior.
- Phase 3A must be marked closed in `PLANS.md` before Phase 4 implementation begins.
- No placeholder or scaffold-only docs may remain in the canonical doc set.

## Release and Closure Rules

- Unresolved exceptions are blockers unless the governing doc names the exception and its removal plan.
- Reported findings, exit codes, and config validation behavior must remain deterministic across repeated runs.
- Any change to rules, precedence, or output requires the matching test updates before merge.

## Exception Rule

- If a gate cannot be met, document the blocker in `PLANS.md` and do not widen scope until the blocker is removed.
