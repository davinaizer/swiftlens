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
- invalid rule IDs
- unknown keys at any level
- unknown rule config keys
- malformed glob patterns if the implementation can detect them

Config failures return exit code `2`.

Preset resolution is deterministic:

- built-in presets are resolved locally from the binary
- unknown preset names are rejected with exit code `2`
- preset defaults are expanded through built-in rule packs before explicit project config is applied
- explicit project config overrides all preset-owned and pack-owned defaults
- normalized rule IDs are canonicalized before merge
- duplicate same-layer normalized scope identities are rejected with exit code `2`

Rule-pack resolution is deterministic too:

- built-in rule packs are resolved locally from the binary
- unknown pack names are not user-configurable and are rejected as invalid top-level config when present
- `swiftlens pack list` and `swiftlens pack explain <pack>` read the pack registry only
- pack defaults are merged in preset-declared order, later pack defaults override earlier ones, and duplicate merged scopes preserve stable ordering

Explainability lookups use the same built-in registries:

- `swiftlens preset list` and `swiftlens preset explain <preset>` read the preset registry only
- `swiftlens rule explain <rule-id>` reads the canonical rule registry only
- unknown preset or rule IDs return exit code `2`

Init UX is deterministic too:

- `swiftlens init` validates `--preset` against the built-in preset registry before writing
- `swiftlens init` rejects existing `.swiftlens.yml` files with exit code `2` unless `--force` is set
- init output is written locally with stable ordering and no hidden state

Boundary inspection is deterministic too:

- `swiftlens boundary list` resolves the same local config model as scan and init
- boundary rendering reflects the effective preset, ignore paths, and configured boundary scopes only
- rendered sources use deterministic provenance labels such as `preset`, `pack: <id>`, and `explicit-config`
- invalid configs return exit code `2` before any boundary output is rendered

Baseline UX is deterministic too:

- `swiftlens baseline create` writes a local JSON baseline file with stable ordering
- `swiftlens scan --baseline <path>` loads the baseline explicitly from the given path
- invalid baseline files return exit code `2`
- baseline filtering suppresses exact fingerprint matches only

## 2. Precedence

1. Explicit project config has highest precedence.
2. Later pack defaults override earlier pack defaults.
3. Earlier pack defaults override preset-owned fallback defaults, if any.
4. Preset-owned fallback defaults override built-in rule defaults.
5. Built-in rule defaults define the lowest baseline.
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
- duplicate rule list entries collapse deterministically after canonicalization
- `architecture.forbiddenImports` is validated deterministically and path-bound with prefix/boundary matching
- `ignore.paths` is normalized, deduplicated, and applied before parsing discovered files
- `rules.<rule>.config` must be a mapping when provided
- `rules.<rule>.severity` must be one of `advisory`, `warning`, or `error`
- baseline files must decode as version `1` JSON with the documented baseline shape
- user-authored `packs:` sections are rejected as unknown top-level keys

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
