# Workflow Contract

## Purpose

Define the shared workflow rules that keep SwiftLens repository-governed, phase-gated, syntax-tree-first, and deterministic.

## Baseline Rules

- Start from `docs/README.md` and `docs/governance/README.md` before changing scope or workflow.
- Keep one owner per workstream.
- Keep the active task state in `PLANS.md` or the owning handoff/backlog document when work changes hands.
- Use small, reversible changes.
- Do not begin implementation if `docs/prd.md` or `docs/tad.md` is missing or undefined.
- Keep execution syntax-tree-first, deterministic, and CI-relevant.
- Do not introduce semantic analysis, plugin ecosystems, platform/SaaS drift, or other out-of-phase capabilities.
- Resolve undefined workflow details in governance first instead of in task chatter.

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

## Rejection Rules

- Reject implementation work that adds behavior without tests.
- Reject implementation work that changes rule output without fixture updates.
- Reject implementation work that changes config parsing without invalid-case coverage.
- Reject implementation work that weakens deterministic output.
- Reject implementation work that relies on manual validation only.

## Test Constraints

- Keep tests fixture-backed where behavior is file- or project-dependent.
- Avoid network, clock, randomness, external services, and machine-local state in tests.
- Verify stable rule IDs, finding shape, ordering, and exit codes where applicable.

## Usage

- Read this document alongside `WORKFLOW_RULES.md`.
- Treat `WORKFLOW_RULES.md` as the operational companion and this file as the shared contract.
