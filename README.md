# SwiftLens

SwiftLens is a standalone Swift package CLI for auditing SwiftUI architecture, governance rules, and AI-generated code slop before changes reach review or CI.

It is not a formatter, SwiftLint replacement, Periphery clone, or code generator.

## What it does

- Detects SwiftUI architectural drift
- Flags AI-slop patterns such as overengineering, boilerplate, and redundant defensive code
- Enforces project-specific governance through configurable rule packs
- Produces deterministic machine-readable output for CI and AI agents
- Emits Markdown summaries for reviewers when requested

## V1 rule packs

SwiftLens V1 treats these packs as required:

- `swiftui-core`
- `ai-slop`
- `architecture`
- `alfred`

V1 is complete only when all required packs are implemented and validated.

## V1 command contract

Expected CLI surface:

```text
swiftlens scan
swiftlens validate-config
swiftlens version
swiftlens help
```

Supported flags:

```text
--config
--format
--path
--verbose
```

Expected output formats:

- `json`
- `yaml`
- `markdown`
- `compact`

## Configuration

SwiftLens reads `.swiftlens.yml`.

Minimum schema shape:

```yaml
project:
packs:
rules:
```

Documented config behavior:

- built-in rule defaults provide the base severity and config
- `packs.<pack>.severityOverrides` overrides built-in severity for rules in that pack
- `rules.<rule>.severity` overrides both built-in severity and pack-level overrides
- `rules.<rule>.config` merges over built-in rule config
- unknown keys fail validation
- CLI flags affect scope and reporter selection only

## Reporter contract

Each violation should include:

- stable rule ID
- pack name
- severity
- confidence
- file path
- source range
- reason
- `fixPattern`

## Planned repository layout

```text
swiftlens/
├── Package.swift
├── Sources/
│   └── SwiftLensCLI/
├── Tests/
│   └── SwiftLensTests/
├── docs/
├── examples/
├── scripts/
└── README.md
```

## Roadmap

Phase 0:

- create repository structure
- freeze V1 governance baseline

Phase 1:

- create executable Swift package
- add SwiftSyntax and YAML parsing dependencies
- wire the CLI command structure

Phase 2:

- define `.swiftlens.yml`
- implement project discovery for Xcode projects and Swift Packages

Phase 3:

- build the SwiftSyntax parser
- build the declaration and ownership index

Phase 4:

- implement the first three rules:
  - `AppRouterOnly`
  - `MassiveSwiftUIView`
  - `SingleUseProtocol`

Phase 5:

- add JSON, YAML, compact, and Markdown reporting
- enforce exit-code policy

Phase 6:

- add Alfred-specific integration and the Alfred policy pack

Phase 7:

- prepare OSS documentation and examples

## Current status

The project is still in the planning and bootstrap stage. The docs define the V1 contract, but the CLI implementation is not complete yet.

