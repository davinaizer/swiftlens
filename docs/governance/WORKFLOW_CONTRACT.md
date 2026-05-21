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

## Usage

- Read this document alongside `WORKFLOW_RULES.md`.
- Treat `WORKFLOW_RULES.md` as the operational companion and this file as the shared contract.
