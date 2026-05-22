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
project:
  path: .
  include: []
  exclude: []
packs:
  architecture:
    enabled: true
    severityOverrides:
rules:
  ForbiddenImportRule:
    enabled: true
    config:
      forbiddenImports:
        - UIKit
```

## 2. Supported Top-Level Keys

- `project`
- `packs`
- `rules`

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
| `rules.<rule>.enabled` | boolean | yes | Enables or disables a rule |
| `rules.<rule>.severity` | enum | no | Rule severity override |
| `rules.<rule>.config` | map | no | Rule-specific parameters |

The current built-in rule is:

- `ForbiddenImportRule`

## 6. Example

```yaml
project:
  path: .
  include: []
  exclude:
    - .build/**
    - .swiftlens-bin/**
    - dist/**
    - DerivedData/**
packs:
  architecture:
    enabled: true
    severityOverrides:
rules:
  ForbiddenImportRule:
    enabled: true
    config:
      forbiddenImports:
        - UIKit
```
