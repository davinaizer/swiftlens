---
createdAt: "2026-05-01T15:20:17-0300"
lastModifiedAt: "2026-05-01T15:20:17-0300"
---

# Repository Bootstrap Guide

## Purpose

Use this guide to start a new repository from a Documentation Pack without inventing scope, rules, or work order.

## Pack Contract

- Pack title: SwiftLens Documentation Pack
- Mandatory inputs: PRD, TAD
- Optional but recommended: Project Profile
- Recommended taxonomy: PRD, TAD, Package API Contract, Command and CLI Specification, Implementation Backlog, QA and Test Plan, Release and Publishing Runbook, Governance, Handoff

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
| 1 | PRD |
| 2 | TAD |
| 3 | Package API Contract |
| 4 | Command and CLI Specification |
| 5 | Implementation Backlog |
| 6 | QA and Test Plan |
| 7 | Release and Publishing Runbook |
| 8 | Governance |
| 9 | Handoff |

## Suggested Deliverables

- Swift Package manifest and target layout
- Public API surface and module boundary rules
- Executable command behavior or library export rules
- Test strategy for package targets
- Release or publishing notes when applicable

## Suggested Repo Structure

| Path | Purpose |
| --- | --- |
| Package.swift | Swift Package manifest |
| Sources/<ToolName>/ | package sources |
| Tests/<ToolName>Tests/ | package tests |
| docs/ | documentation and governance |
| scripts/ | utility scripts |
| README.md | project overview and usage |

## Bootstrap Sequence

1. Validate the Documentation Pack before writing anything.
2. Lock product intent in PRD.
3. Lock system boundaries in TAD.
4. Add the remaining source-of-truth documents in pack order.
5. Add governance rules before implementation starts.
6. Define any team or agent routing if the project uses delegation.
7. Build backlog, QA, and handoff artifacts from the authoritative docs.
8. Start implementation only after the guide, governance, and validation rules exist.

## Suggested Workflow

1. Define package boundaries before implementation.
2. Decide whether the package is a library, executable, or mixed target set.
3. Lock public API and dependency boundaries in TAD.
4. Create tests alongside the first package slice.
5. Keep scripts and docs adjacent to package-level work.
6. Validate with `swift test` and any package-specific CLI checks.

## Governance Baseline

- Keep a single source of truth per decision.
- Put scope rules in PRD or the project rules doc, not in task chatter.
- Put architecture boundaries in TAD or architecture governance, not in implementation notes.
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

- Do not begin implementation if PRD or TAD is missing.
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