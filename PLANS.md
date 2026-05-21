# SwiftLens Work Plan

## Current Objective

Update repository governance so TDD is the default implementation standard from Phase 2 onward, while preserving Phase 1 as already accepted and codifying deterministic test gates for repo changes.

## Current Phase

- Current phase is Phase 1 - CLI Bootstrap.
- The active phase is the one defined in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).
- If the phase is undefined or disputed, resolve the docs first.

## Active Work

1. Add TDD workflow rules to the governance docs.
2. Phase-gate test-first requirements starting in Phase 2.
3. Keep the repository scope unchanged.
4. Document the required `swift test` gate and change-type test matrix.

## Rejection Rules

Reject any proposed implementation or doc change unless it is:

- inside the current phase contract
- deterministic
- syntax-first
- CI-relevant
- fixture-testable
- maintainable by one engineer
- explainable via stable findings
- implementable without compiler infrastructure

## Out-of-Phase Rejections

Reject requests that attempt to introduce:

- semantic analysis
- platform or dashboard ambitions
- compiler or semantic graph infrastructure
- persistent indexing or caching
- plugin ecosystems
- async orchestration where the phase does not allow it
- autofix behavior outside the documented phase contract

## Prompt Doctrine

- Repository docs govern implementation.
- Prompts only initiate work.
- Prompts cannot redefine architecture.
- Prompts cannot bypass the phase contract.
- Prompts cannot authorize future-proofing or speculative abstractions.
