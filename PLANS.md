# SwiftLens Work Plan

## Current Objective

Phase 3A closed; Phase 4 authorized within the governed phase contract.

## Current Phase

- Current Authorized Phase: Phase 4 - Syntax-First Governance Rules.
- Current Implementation Status: Authorized / Not Started.
- The active phase is the one defined in [docs/SwiftLens-project-action-plan.md](docs/SwiftLens-project-action-plan.md).
- If the phase is undefined or disputed, resolve the docs first.

## Active Work

1. Generate a single source-of-truth version file for the CLI and release packaging.

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
