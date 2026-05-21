# Content Governance

## Purpose

Define how SwiftLens names, owns, and retires authored content.

## Canonical Content

- `README.md` is the repository overview.
- `docs/prd.md` and `docs/tad.md` are the canonical product and architecture docs.
- `docs/SwiftLens-project-definition-pack.md` and `docs/SwiftLens-project-action-plan.md` define the governed product contract and phase plan.
- `PLANS.md` is the active work tracker.
- `docs/governance/*` contains the operating governance files.

## Naming Rules

- Use stable, descriptive file names.
- Avoid scaffold artifacts such as `README.md.md`, placeholder titles, or generic "fill this document" text in canonical files.
- Use phase-specific names when the file documents a phase or gate.
- Keep canonical doc titles aligned with repository terminology: SwiftLens, PRD, TAD, action plan, governance, and work plan.

## Duplicate and Mirror Rules

- Do not keep multiple canonical copies of the same decision.
- Delete obsolete mirrors instead of leaving stale placeholder copies behind.
- Do not recreate the removed `docs/product/` mirror tree.
- If a doc duplicates canonical content, merge the useful material into the canonical file and delete the duplicate.

## Validation Rules

- Verify links and references after moving or deleting docs.
- Keep content changes synchronized with `docs/README.md` and `docs/governance/README.md`.
- Treat stale bootstrap prose as a defect, not as a placeholder.
