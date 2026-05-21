# Architecture Guardrails

## Purpose

Define module boundaries and the constraints that keep the scaffold maintainable.

## Baseline Rules

- Keep presentation, domain logic, and persistence separate.
- Keep shared contracts in a dedicated shared layer.
- Do not introduce cross-layer imports without updating the architecture doc first.
