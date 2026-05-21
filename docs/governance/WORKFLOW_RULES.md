# Workflow Rules

## Purpose

Define the operational sequence for planning, editing, validating, and handing work back to the repository.

## Operational Sequence

1. Read `docs/README.md` and `docs/governance/README.md`.
2. Confirm the active phase in `docs/SwiftLens-project-action-plan.md`.
3. Record the current objective in `PLANS.md`.
4. Make the smallest change that satisfies the current phase contract.
5. Add or update the matching tests before behavior changes land.
6. Run `swift test` for the touched behavior.
7. Update the relevant governance or canonical docs if the decision changes scope or workflow.

## Working Rules

- Keep one owner per workstream.
- Keep each change reversible and scoped to the current phase.
- Keep the active handoff current when work moves between tasks or agents.
- Keep doc edits in canonical files instead of spreading the same rule across multiple mirrors.
- Use explicit rejection when a request is outside the active phase or outside the canonical docs.

## Validation Rule

- Do not widen scope until the current change passes the required test gate and the docs still agree with the implementation.
