# SwiftLens Config Validation

## Purpose

This document defines how SwiftLens validates `.swiftlens.yml` after parsing the schema.

Use this document to answer:

- what gets rejected
- how precedence works
- which exit codes apply to config failures
- which config rules are deterministic and enforced

For the schema itself, see [config-schema.md](config-schema.md).

## 1. Validation Rules

Validation must reject:

- missing required fields
- invalid severity values
- invalid paths
- invalid pack names
- invalid rule IDs
- unknown keys at any level
- unknown rule config keys
- malformed glob patterns if the implementation can detect them

Config failures return exit code `2`.

Preset resolution is deterministic:

- built-in presets are resolved locally from the binary
- unknown preset names are rejected with exit code `2`
- preset defaults are expanded before explicit project config is applied
- explicit project config overrides preset defaults

## 2. Precedence

1. Preset defaults define the baseline when `preset` is set.
2. Built-in rule defaults define the rule baseline.
3. Pack-level severity overrides apply next.
4. Rule-level severity overrides win over pack-level and built-in values.
5. Rule-level config merges over built-in config.
6. CLI flags never mutate rule semantics.

## 3. Current Validation Behavior

- `.swiftlens.yml` is resolved from the current working directory only unless `--config` is explicit.
- unknown top-level keys are rejected
- `version` and `preset` are accepted top-level keys
- unknown `project` keys are rejected
- unknown pack names are rejected
- unknown rule IDs are rejected
- unknown preset names are rejected
- `rules` may be either a canonical ordered list or the legacy keyed alias shape
- `architecture.forbiddenImports` is validated deterministically and path-bound with prefix/boundary matching
- `ignore.paths` is applied before parsing discovered files
- `packs.<pack>.severityOverrides` must be a mapping when provided
- `rules.<rule>.config` must be a mapping when provided
- `rules.<rule>.severity` must be one of `advisory`, `warning`, or `error`
- empty `packs.<pack>.severityOverrides` must use block form, not inline `{}` syntax

## 4. Exit Codes

| Exit code | Meaning |
| --- | --- |
| `0` | success |
| `1` | rule violations |
| `2` | config or usage error |
| `3` | internal failure |

## 5. Determinism Notes

Validation is deterministic:

- no parent-directory traversal
- no recursive config search
- no inheritance layer
- no workspace discovery
- no environment-aware config resolution
