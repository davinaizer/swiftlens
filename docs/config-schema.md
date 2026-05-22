# SwiftLens Config Schema

## Purpose

This document is the authoritative schema reference for `.swiftlens.yml`.

Use this document to answer:

- which top-level keys are supported
- which fields are supported under each section
- which fields are required vs optional
- what a valid minimal config looks like

For validation behavior, exit codes, and precedence rules, see [config-validation.md](config-validation.md).

## 1. Minimum Shape

```yaml
version: 1
preset: feature-modules
project:
  path: .
  include: []
  exclude: []
rules:
  - architecture.forbidden-import
architecture:
  forbiddenImports:
    -
      from: Features/
      imports:
        - UIKit
ignore:
  paths: []
```

## 2. Supported Top-Level Keys

- `version`
- `preset`
- `project`
- `packs`
- `rules`
- `architecture`
- `ignore`

Unknown top-level keys are rejected by the validator.

## 3. Project Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `project.path` | string | yes | Repo root or scan root |
| `project.include` | string array | no | Glob patterns included in scope |
| `project.exclude` | string array | no | Glob patterns excluded from scope |
| `project.name` | string | no | Human-readable project name |
| `project.sourceRoots` | string array | no | Explicit source roots for discovery |
| `project.featureRoots` | string array | no | Ownership and boundary roots |
| `project.navigationOwner` | string | no | Expected router owner |
| `project.localizationFiles` | string array | no | Localization resources for string rules |
| `project.debugPreviewPaths` | string array | no | Debug-only preview locations |

The current parser supports:

- `project.path`
- `project.include`
- `project.exclude`

## 4. Pack Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `packs.<pack>.enabled` | boolean | yes | Enables or disables the pack |
| `packs.<pack>.severityOverrides` | map | no | Per-rule severity overrides |

The current built-in pack is:

- `architecture`

For an empty `severityOverrides` mapping, use block form:

```yaml
severityOverrides:
```

The current parser does not accept inline `{}` for this field.

## 5. Rule Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `rules` | string array | no | Ordered enablement list for canonical rule IDs |
| `rules.<rule>.enabled` | boolean | yes | Legacy alias path for compatibility |
| `rules.<rule>.severity` | enum | no | Legacy alias path for compatibility |
| `rules.<rule>.config` | map | no | Legacy alias path for compatibility |

The current built-in rule is:

- `architecture.forbidden-import`

The current canonical rule-family config lives under:

- `architecture.forbiddenImports`

The legacy `ForbiddenImportRule` rule-config shape remains accepted as a compatibility alias.

## 6. Example

```yaml
version: 1
preset: feature-modules
project:
  path: .
  include: []
  exclude:
    - .build/**
    - .swiftlens-bin/**
    - dist/**
    - DerivedData/**
rules:
  - architecture.forbidden-import
architecture:
  forbiddenImports:
    -
      from: Features/
      imports:
        - UIKit
ignore:
  paths:
    - DerivedData/
```
