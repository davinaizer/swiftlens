import Foundation
import Testing
@testable import SwiftLens

private let phase5FCLIExecutionLock = NSLock()

private func phase5FRunCLI(_ arguments: [String]) -> CLIExecutionResult {
    phase5FCLIExecutionLock.lock()
    defer {
        phase5FCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments)
}

private let phase5FPresetListOutput = """
Available presets:

- app-layers
  Layered app governance for single-target or lightly modular projects.

- feature-modules
  Feature-oriented governance for modular SwiftUI applications.

- tca-features
  Governance defaults for reducer-first TCA-style feature architectures.
"""
    + "\n"

private let phase5FPackListOutput = """
Available rule packs:

- feature-isolation
  Restricts sibling feature imports for modular feature-oriented apps.

- shared-boundaries
  Prevents shared support code from depending on features.

- app-shell
  Defines the app composition-root boundary.

- domain-ui-separation
  Separates UI code from domain and data-layer dependencies.

- dependency-direction
  Constrains dependency clients and feature code to approved import directions.
"""
    + "\n"

private let phase5FAppLayersExplanation = """
Description

Layered app governance for single-target or lightly modular projects.

Composition

pack: domain-ui-separation
pack: app-shell

Intended Structure

Use this preset when a project is organized into broad app layers such as App, UI, Domain, Data, and Shared.
Treat App as the composition root and keep the remaining layers explicit.

Governance Defaults

Domain cannot import SwiftUI, UIKit, or AppKit.
UI cannot import Data.
The preset stays conservative and does not attempt to infer additional layers.

Example Layout

App/
UI/
Domain/
Data/
Shared/

Notes

This preset is path and import based only.
It does not inspect ownership graphs or runtime wiring.
"""
    + "\n"

private let phase5FFeatureModulesExplanation = """
Description

Feature-oriented governance for modular SwiftUI applications.

Composition

pack: feature-isolation
pack: shared-boundaries
pack: app-shell

Intended Structure

Use this preset when application behavior is split into compositional features plus shared and core support code.
App is the composition root and may import feature modules.
Sibling feature modules should stay isolated from one another.

Governance Defaults

Features may not import other Features.* modules.
Shared may not import Features.*.
Core may not import Features.*.
The preset allows App to compose feature modules explicitly.

Example Layout

App/
Features/
  Auth/
  Profile/
Shared/
Core/

Notes

The preset encodes explicit forbidden-import scopes only.
It does not infer feature ownership or module graphs.
"""
    + "\n"

private let phase5FRuleExplanation = """
Purpose

Enforce explicit import boundaries declared by path-scoped governance rules.

Detection Mechanism

Scan declared `import` statements only.
Normalize imported module names into path-like segments.
Match the file path against configured `from` scopes using prefix-boundary checks.
Compare the imported module against each configured forbidden import prefix.
Do not resolve symbols, build targets, transitive dependencies, or runtime behavior.

Config Shape

rules:
  - architecture.forbidden-import
architecture:
  forbiddenImports:
    -
      from: Features/
      imports:
        - Infrastructure

Deterministic Behavior

Matching is syntax-first and path-bound.
The same input config and source tree produce the same result on every run.
No semantic analysis or graph construction is performed.

Limitations

Only declared imports are inspected.
The rule does not infer ownership or resolve module graphs.
Path and import matching are intentionally conservative.

Example Violation

File: Features/Auth/AuthFeature.swift
import Infrastructure
This violates a scope that forbids `Infrastructure` imports from `Features/`.

Example Config

rules:
  - architecture.forbidden-import
architecture:
  forbiddenImports:
    -
      from: Features/
      imports:
        - Infrastructure
"""
    + "\n"

private let phase5FFeatureIsolationPackExplanation = """
Source

pack: feature-isolation

Description

Restricts sibling feature imports for modular feature-oriented apps.

Enabled Rules

- architecture.forbidden-import

Generated Boundaries

- Features/
  Restricted Imports:
    - Features/*
  Notes:
    - Sibling feature imports are restricted.

Intended Usage

Use this pack when features should remain isolated from other features.

Notes

This pack is syntax-first and path-bound.

Limitations

It does not infer ownership or transitive module graphs.
"""
    + "\n"

private let phase5FPresetUsage = """
SwiftLens \(SwiftLensVersion.current)

Usage:
  swiftlens preset list
  swiftlens preset explain <PRESET>
  swiftlens pack list
  swiftlens pack explain <PACK>

Commands:
  swiftlens preset list
  swiftlens preset explain <PRESET>
  swiftlens pack list
  swiftlens pack explain <PACK>
"""
    + "\n"

private let phase5FPackUsage = """
SwiftLens \(SwiftLensVersion.current)

Usage:
  swiftlens pack list
  swiftlens pack explain <PACK>

Commands:
  swiftlens pack list
  swiftlens pack explain <PACK>
"""
    + "\n"

private let phase5FRuleUsage = """
SwiftLens \(SwiftLensVersion.current)

Usage:
  swiftlens rule explain <RULE-ID>

Commands:
  swiftlens rule explain <RULE-ID>
"""
    + "\n"

@Suite("SwiftLens Phase 5F")
struct SwiftLensPhase5FTests {
    @Test("preset list renders stable ordering and formatting")
    func presetListRendersStableOrderingAndFormatting() throws {
        let result = phase5FRunCLI(["swiftlens", "preset", "list"])
        let repeatResult = phase5FRunCLI(["swiftlens", "preset", "list"])

        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout == phase5FPresetListOutput)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("preset explain renders app-layers explanation deterministically")
    func presetExplainRendersAppLayersExplanationDeterministically() throws {
        let result = phase5FRunCLI(["swiftlens", "preset", "explain", "app-layers"])
        let repeatResult = phase5FRunCLI(["swiftlens", "preset", "explain", "app-layers"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == phase5FAppLayersExplanation)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("preset explain renders feature-modules explanation deterministically")
    func presetExplainRendersFeatureModulesExplanationDeterministically() throws {
        let result = phase5FRunCLI(["swiftlens", "preset", "explain", "feature-modules"])
        let repeatResult = phase5FRunCLI(["swiftlens", "preset", "explain", "feature-modules"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == phase5FFeatureModulesExplanation)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("rule explain renders forbidden import explanation deterministically")
    func ruleExplainRendersForbiddenImportExplanationDeterministically() throws {
        let result = phase5FRunCLI(["swiftlens", "rule", "explain", "architecture.forbidden-import"])
        let repeatResult = phase5FRunCLI([
            "swiftlens",
            "rule",
            "explain",
            "architecture.forbidden-import"
        ])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == phase5FRuleExplanation)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("pack list renders stable ordering and formatting")
    func packListRendersStableOrderingAndFormatting() throws {
        let result = phase5FRunCLI(["swiftlens", "pack", "list"])
        let repeatResult = phase5FRunCLI(["swiftlens", "pack", "list"])

        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout == phase5FPackListOutput)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("pack explain renders feature-isolation explanation deterministically")
    func packExplainRendersFeatureIsolationExplanationDeterministically() throws {
        let result = phase5FRunCLI(["swiftlens", "pack", "explain", "feature-isolation"])
        let repeatResult = phase5FRunCLI([
            "swiftlens",
            "pack",
            "explain",
            "feature-isolation"
        ])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == phase5FFeatureIsolationPackExplanation)
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("unknown pack fails with usage exit code")
    func unknownPackFailsWithUsageExitCode() throws {
        let result = phase5FRunCLI(["swiftlens", "pack", "explain", "not-a-real-pack"])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr == "Usage error: Unknown pack `not-a-real-pack`.\n")
    }

    @Test("unknown preset fails with usage exit code")
    func unknownPresetFailsWithUsageExitCode() throws {
        let result = phase5FRunCLI(["swiftlens", "preset", "explain", "not-a-real-preset"])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr == "Usage error: Unknown preset `not-a-real-preset`.\n")
    }

    @Test("unknown rule fails with usage exit code")
    func unknownRuleFailsWithUsageExitCode() throws {
        let result = phase5FRunCLI(["swiftlens", "rule", "explain", "not-a-real-rule"])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr == "Usage error: Unknown rule `not-a-real-rule`.\n")
    }

    @Test("help output includes explainability commands")
    func helpOutputIncludesExplainabilityCommands() throws {
        let result = phase5FRunCLI(["swiftlens", "help"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("swiftlens preset list"))
        #expect(result.stdout.contains("swiftlens preset explain <PRESET>"))
        #expect(result.stdout.contains("swiftlens pack list"))
        #expect(result.stdout.contains("swiftlens pack explain <PACK>"))
        #expect(result.stdout.contains("swiftlens rule explain <RULE-ID>"))
    }

    @Test("preset command family help is deterministic")
    func presetCommandFamilyHelpIsDeterministic() throws {
        let first = phase5FRunCLI(["swiftlens", "preset"])
        let second = phase5FRunCLI(["swiftlens", "preset", "--help"])

        #expect(first.exitCode == 0)
        #expect(second.exitCode == 0)
        #expect(first.stderr.isEmpty)
        #expect(second.stderr.isEmpty)
        #expect(first.stdout == phase5FPresetUsage)
        #expect(second.stdout == phase5FPresetUsage)
    }

    @Test("rule command family help is deterministic")
    func ruleCommandFamilyHelpIsDeterministic() throws {
        let first = phase5FRunCLI(["swiftlens", "rule"])
        let second = phase5FRunCLI(["swiftlens", "rule", "--help"])

        #expect(first.exitCode == 0)
        #expect(second.exitCode == 0)
        #expect(first.stderr.isEmpty)
        #expect(second.stderr.isEmpty)
        #expect(first.stdout == phase5FRuleUsage)
        #expect(second.stdout == phase5FRuleUsage)
    }
}
