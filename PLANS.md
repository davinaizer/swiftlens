# SwiftLens Work Plan

## Current Objective

Phase 5C completed; Phase 5H remains the active authorized phase in the governed plan.

## Current Phase

- Current Authorized Phase: Phase 5H - Boundary Inspection UX.
- Current Implementation Status: Authorized / Pending.
- The active phase is the one defined in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).
- If the phase is undefined or disputed, resolve the docs first.

## Active Work

1. Implement deterministic boundary inspection so users can inspect effective preset and config-scoped boundaries.

## Completed Work

1. Refactor `AGENTS.md` into a compact bootstrap index that prioritizes `README.md`, `docs/README.md`, `docs/governance/README.md`, and `PLANS.md`, while leaving deeper specs behind the docs indexes.
1. Implement deterministic internal rule pack composition for preset expansion, pack explainability, and pack-aware rule resolution.
1. Implement deterministic baseline creation and regression-only scan filtering for incremental adoption.

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
