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

Explainability lookups use the same built-in registries:

- `swiftlens preset list` and `swiftlens preset explain <preset>` read the preset registry only
- `swiftlens rule explain <rule-id>` reads the canonical rule registry only
- unknown preset or rule IDs return exit code `2`

Init UX is deterministic too:

- `swiftlens init` validates `--preset` against the built-in preset registry before writing
- `swiftlens init` rejects existing `.swiftlens.yml` files with exit code `2` unless `--force` is set
- init output is written locally with stable ordering and no hidden state

Baseline UX is deterministic too:

- `swiftlens baseline create` writes a local JSON baseline file with stable ordering
- `swiftlens scan --baseline <path>` loads the baseline explicitly from the given path
- invalid baseline files return exit code `2`
- baseline filtering suppresses exact fingerprint matches only

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
- baseline files must decode as version `1` JSON with the documented baseline shape

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
