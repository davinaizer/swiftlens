# Project Rules

## Purpose

Define the immutable repo rules that constrain scope, phase work, and document ownership.

## Canonical Sources

- `docs/prd.md` is the canonical product requirements document.
- `docs/tad.md` is the canonical technical architecture document.
- `docs/SwiftLens-project-definition-pack.md` defines the product thesis and V1 boundaries.
- `docs/SwiftLens-project-action-plan.md` defines the phase contract.
- `PLANS.md` records active work and phase-closure cleanup.

## Scope Rules

- SwiftLens is a standalone Swift package repository.
- Current work must stay inside the active phase contract.
- Phase 3A is closed.
- Phase 5G is the current authorized phase.
- Phase 3A work was limited to local developer DX and remained phase-gated.
- Phase 5G work remains constrained by the phase contract and must not expand beyond its explicitly authorized scope.
- Any request that introduces semantic analysis, plugin ecosystems, distributed services, GUI surfaces, or auto-fix behavior is out of scope unless a governing doc explicitly allows it.
- Local developer DX must remain deterministic and cwd-local.

## Document Rules

- Do not create alternate canonical product or architecture documents outside `docs/prd.md` and `docs/tad.md`.
- Do not recreate the deleted `docs/product/` mirror tree.
- Keep the canonical docs current before implementation changes that alter scope or contract.
- If a prompt conflicts with repository docs, the repository docs win.

## Change Rule

- Any new product rule, phase rule, or governance exception must be written in the governing doc before code changes begin.
