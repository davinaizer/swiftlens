# Workflow Contract

## Purpose

Define the shared workflow rules that keep SwiftLens phase-gated, deterministic, and repository-governed.

## Baseline Rules

- Start from `docs/README.md` and `docs/governance/README.md` before changing scope or workflow.
- Identify the active phase in `docs/SwiftLens-project-action-plan.md` before implementation or doc changes that affect behavior.
- Keep one owner per workstream and record the active state in `PLANS.md`.
- Use small, reversible changes.
- Keep execution syntax-tree-first, deterministic, and CI-relevant.
- Do not introduce semantic analysis, plugin ecosystems, dashboards, distributed services, or other out-of-phase capabilities.
- Resolve undefined workflow details in governance first instead of in task chatter.

## Agent Workflow Rules

- The repository docs are the source of truth; prompts only initiate work.
- If a prompt conflicts with canonical docs, reject the prompt and follow the docs.
- Do not bypass a selector, diagnostic, or architecture review stage.
- Update `PLANS.md` when the active work changes hands or the closure state changes.
- Keep handoff text short, explicit, and generated from the current state.

## TDD Standard

- TDD is the default implementation workflow from Phase 2 onward.
- Phase 1 remains accepted as already implemented.
- Write or update failing tests first.
- Implement the smallest code change that satisfies the failing test.
- Run the relevant test target before widening scope.
- Refactor only after tests pass.
- Preserve deterministic behavior throughout the cycle.

## Phase-Gated Test Requirements

- Every new rule requires fixture-backed tests before implementation.
- Every reporter change requires golden-output tests.
- Every config change requires valid and invalid config tests.
- Every exit-code change requires explicit exit-code tests.
- Every CLI parsing change requires argument validation tests.
- `swift test` must pass before merge, phase closure, rule additions, config changes, and reporter changes.

| Change Type | Required Test |
| --- | --- |
| New rule | New fixtures plus a failing test first |
| Reporter change | Golden-output test |
| Config schema change | Valid and invalid config tests |
| Exit-code change | Explicit exit-code test |
| CLI parsing change | Argument validation tests |

## Rejection Rules

- Reject implementation work that adds behavior without tests.
- Reject implementation work that changes rule output without fixture updates.
- Reject implementation work that changes config parsing without invalid-case coverage.
- Reject implementation work that weakens deterministic output.
- Reject implementation work that relies on manual validation only.
- Reject implementation work that attempts to move into the next phase without the current phase closing cleanly.

## Test Constraints

- Keep tests fixture-backed where behavior is file- or project-dependent.
- Avoid network, clock, randomness, external services, and machine-local state in tests.
- Tests validate externally observable deterministic behavior, not implementation structure.
- Verify stable rule IDs, finding shape, ordering, and exit codes where applicable.
