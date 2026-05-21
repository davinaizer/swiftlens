# SwiftLens Work Plan

## Current Objective

Align the bootstrap-generated documentation with the canonical SwiftLens governance pack so the repository itself is the implementation authority.

## Current Phase

- Current phase must be identified before any implementation work starts.
- The active phase is the one defined in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).
- If the phase is undefined or disputed, resolve the docs first.

## Active Work

1. Replace generic bootstrap wording in the repository entrypoints and workflow docs.
2. Keep the phase contract repository-governed, deterministic, and syntax-tree-first.
3. Preserve the documented rejection rules for semantic analysis, plugin/platform drift, and other out-of-phase scope.

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
