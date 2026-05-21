---
createdAt: "2026-05-01T15:20:17-0300"
lastModifiedAt: "2026-05-21T00:00:00-0300"
---

# Repository Bootstrap Guide

## Purpose

Use this guide to start a new repository from a Documentation Pack without inventing scope, rules, or work order.

## Pack Contract

- Pack title: SwiftLens Documentation Pack
- Mandatory inputs: PRD, TAD
- Optional but recommended: Project Profile, Project Definition Pack, Project Action Plan
- Recommended taxonomy: README, PRD, TAD, Project Definition Pack, Project Action Plan, PLANS, docs/README, docs/governance/README, docs/governance/WORKFLOW_CONTRACT, project_bootstrap_guide

## Detected Repository Profile

- Repository kind: Swift Package repository
- Profile summary: Use when the repository is a standalone Swift package built around Package.swift.
- Repository Kind: swift-package
- Delivery Model: package
- Package Type: executable
- Package Name: SwiftLens
- Tool Name: SwiftLens
- Primary Language: Swift
- Repo Model: single-package

## Documentation Order

| Order | Document |
| --- | --- |
| 1 | README |
| 2 | docs/README |
| 3 | docs/governance/README |
| 4 | docs/governance/WORKFLOW_CONTRACT |
| 5 | PRD |
| 6 | TAD |
| 7 | SwiftLens-project-definition-pack |
| 8 | SwiftLens-project-action-plan |
| 9 | PLANS |
| 10 | project_bootstrap_guide |

## Suggested Deliverables

- SwiftLens package manifest and target layout
- SwiftLens CLI entrypoints and deterministic command behavior
- Syntax-tree-first config, rule, and reporter contracts
- Fixture-backed success and failure tests
- Phase-gated governance docs and work-plan alignment

## Suggested Repo Structure

| Path | Purpose |
| --- | --- |
| Package.swift | Swift Package manifest |
| Sources/SwiftLensCLI/ | CLI sources |
| Tests/SwiftLensTests/ | package tests |
| docs/ | documentation and governance |
| scripts/ | utility scripts |
| README.md | project overview and usage |
| PLANS.md | active work plan |

## Bootstrap Sequence

1. Validate the Documentation Pack before writing anything.
2. Lock product intent in `docs/prd.md`.
3. Lock system boundaries in `docs/tad.md`.
4. Align the definition pack and action plan with the governed phase contract.
5. Add governance rules before implementation starts.
6. Define any team or agent routing if the project uses delegation.
7. Keep `PLANS.md` current when work changes hands.
8. Start implementation only after the guide, governance, and validation rules exist.

## Suggested Workflow

1. Lock product intent in `docs/prd.md`.
2. Lock architecture boundaries in `docs/tad.md`.
3. Keep the work syntax-tree-first, deterministic, and CI-relevant.
4. Keep phase transitions in `docs/SwiftLens-project-action-plan.md`.
5. Update `PLANS.md` when work changes hands.
6. Validate with `swift test` and any package-specific CLI checks.

## Governance Baseline

- Keep a single source of truth per decision.
- Put scope rules in `docs/prd.md` or the project rules doc, not in task chatter.
- Put architecture boundaries in `docs/tad.md` or architecture governance, not in implementation notes.
- Put content, data, or domain rules in the relevant source-of-truth doc or governance file.
- Put workflow, planning, and validation rules in governance docs before coding.
- Record exceptions explicitly, with a removal plan and expiry if applicable.
- Keep the shared workflow contract in `docs/governance/WORKFLOW_CONTRACT.md`.

## Work Organization

- Use one entry point for ambiguous requests.
- Route each request to exactly one owner or workstream.
- Keep planning in architecture and implementation in the owning workstream.
- Keep validation in a dedicated validation phase or quality gate.
- Keep handoff artifacts short, explicit, and generated from the current state.
- Keep workflow rules in the shared contract instead of repeating them across docs.

## Validation Gate

- Do not begin implementation if `docs/prd.md` or `docs/tad.md` is missing.
- Do not bypass governance, architecture, or domain rules silently.
- Validate the first implementation slice before expanding scope.
- Update the active task or handoff artifact whenever work changes hands.

## Script Usage

```bash
python3 scripts/bootstrap_project_guide.py --pack path/to/documentation-pack.md --output docs/project_bootstrap_guide.md
python3 scripts/bootstrap_project_guide.py --pack path/to/documentation-pack.md --output docs/project_bootstrap_guide.md --check
python3 scripts/bootstrap_project_guide.py --pack path/to/documentation-pack.md --output docs/project_bootstrap_guide.md --scaffold --scaffold-root /path/to/new-repo
python3 scripts/bootstrap_project_guide.py init --directory /path/to/new-repo
```
