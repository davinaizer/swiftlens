import Foundation
import Testing
@testable import SwiftLens

private let phase5DCLIExecutionLock = NSLock()

private func phase5DRunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5DCLIExecutionLock.lock()
    defer {
        phase5DCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func phase5DDecodeReport(from result: CLIExecutionResult) throws -> ScanReport {
    try JSONDecoder().decode(ScanReport.self, from: Data(result.stdout.utf8))
}

private func phase5DTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "swiftlens-phase5d-\(UUID().uuidString)",
        isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func phase5DWriteText(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let data = text.data(using: .utf8) else {
        throw SwiftLensError.internalFailure("Unable to encode test text.")
    }
    try data.write(to: url, options: [.atomic])
}

private final class Phase5DFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5D")
struct SwiftLensPhase5DTests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    private func copiedFixture(_ name: String) throws -> URL {
        let source = fixtureURL(name)
        let destination = try phase5DTemporaryDirectory().appendingPathComponent(
            name,
            isDirectory: true
        )
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    @Test("duplicate canonical rules collapse deterministically")
    func duplicateCanonicalRulesCollapseDeterministically() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            rules:
              - ForbiddenImportRule
              - architecture.forbidden-import
              - ForbiddenImportRule
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let loaded = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(loaded.config.ruleOrder == [ForbiddenImportRule.descriptor.id])
        #expect(Array(loaded.config.rules.keys) == [ForbiddenImportRule.descriptor.id])
    }

    @Test("legacy rule mappings keep file order when canonical keys collide")
    func legacyRuleMappingsKeepFileOrderWhenCanonicalKeysCollide() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: .
              include: []
              exclude: []
            rules:
              architecture.forbidden-import:
                config:
                  forbiddenImports:
                    -
                      from: .
                      imports:
                        - Foundation
              ForbiddenImportRule:
                config:
                  forbiddenImports:
                    - UIKit
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let loaded = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        let resolution = try #require(
            loaded.governance.ruleConfigurations[ForbiddenImportRule.descriptor.id]
        )
        let rootScope = try #require(
            resolution.forbiddenImportScopes.first(where: { $0.scope.from == "" })
        )

        #expect(rootScope.scope.imports == ["UIKit"])
    }

    @Test("duplicate same-layer scopes fail deterministically")
    func duplicateSameLayerScopesFailDeterministically() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: .
              include: []
              exclude: []
            architecture:
              forbiddenImports:
                -
                  from: Features/
                  imports:
                    - UIKit
                -
                  from: Features/
                  imports:
                    - Foundation
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let result = phase5DRunCLI(
            ["swiftlens", "validate-config", "--config", ".swiftlens.yml"],
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Duplicate normalized scope identity `Features`"))
    }

    @Test("explicit config precedence overrides preset pack defaults")
    func explicitConfigPrecedenceOverridesPresetPackDefaults() throws {
        let fixture = fixtureURL("PresetFeatureModulesOverride")
        let loaded = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        let resolution = try #require(
            loaded.governance.ruleConfigurations[ForbiddenImportRule.descriptor.id]
        )
        let scopes = resolution.forbiddenImportScopes

        #expect(resolution.sources.contains(.explicitConfig))
        #expect(scopes.map(\.source) == [
            .explicitConfig,
            .pack("shared-boundaries"),
            .pack("shared-boundaries"),
        ])
        #expect(scopes.first(where: { $0.scope.from == "Features" })?.scope.imports == ["Foundation"])
    }

    @Test("pack override ordering stays deterministic")
    func packOverrideOrderingStaysDeterministic() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let loaded = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        let resolution = try #require(
            loaded.governance.ruleConfigurations[ForbiddenImportRule.descriptor.id]
        )

        #expect(resolution.forbiddenImportScopes.map { $0.scope.from } == [
            "Features",
            "Shared",
            "Core"
        ])
        #expect(resolution.forbiddenImportScopes.map { $0.source } == [
            .pack("feature-isolation"),
            .pack("shared-boundaries"),
            .pack("shared-boundaries")
        ])
    }

    @Test("ignore paths merge deterministically")
    func ignorePathsMergeDeterministically() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            ignore:
              paths:
                - .build/
                - DerivedData/
                - .build/
                - .swiftpm/
                - DerivedData/
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let loaded = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(loaded.config.ignore.paths == [".build", "DerivedData", ".swiftpm"])
        #expect(loaded.governance.ignorePaths == [".build", "DerivedData", ".swiftpm"])
    }

    @Test("equivalent configs normalize identically")
    func equivalentConfigsNormalizeIdentically() throws {
        let firstRoot = try phase5DTemporaryDirectory()
        let secondRoot = try phase5DTemporaryDirectory()

        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            rules:
              - ForbiddenImportRule
            ignore:
              paths:
                - .build/
                - DerivedData/
            """,
            to: firstRoot.appendingPathComponent(".swiftlens.yml")
        )
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            rules:
              - architecture.forbidden-import
              - ForbiddenImportRule
            ignore:
              paths:
                - .build/
                - DerivedData/
            """,
            to: secondRoot.appendingPathComponent(".swiftlens.yml")
        )

        let first = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: firstRoot.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)
        let second = try ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: secondRoot.path)
        ).load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(first.config == second.config)
        #expect(first.governance == second.governance)
    }

    @Test("repeated parsing normalizes identically across 100 loads")
    func repeatedParsingNormalizesIdenticallyAcross100Loads() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: .
              include: []
              exclude: []
            rules:
              architecture.forbidden-import:
                config:
                  forbiddenImports:
                    -
                      from: Features/
                      imports:
                        - UIKit
                        - Foundation
            ignore:
              paths:
                - .build/
                - DerivedData/
                - .swiftpm/
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let loader = ConfigLoader(
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
        let first = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)
        for iteration in 1..<100 {
            let next = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)
            #expect(next == first, "Normalized config diverged on iteration \(iteration)")
        }
    }

    @Test("boundary inspection renders effective provenance")
    func boundaryInspectionRendersEffectiveProvenance() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let result = phase5DRunCLI(
            ["swiftlens", "boundary", "list"],
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("Source:\n    - pack: feature-isolation"))
        #expect(result.stdout.contains("Source:\n    - pack: shared-boundaries"))
    }

    @Test("override explainability stays visible")
    func overrideExplainabilityStaysVisible() throws {
        let preset = phase5DRunCLI(["swiftlens", "preset", "explain", "feature-modules"])
        let pack = phase5DRunCLI(["swiftlens", "pack", "explain", "feature-isolation"])

        #expect(preset.stdout.contains("Composition"))
        #expect(preset.stdout.contains("pack: feature-isolation"))
        #expect(pack.stdout.contains("Source"))
        #expect(pack.stdout.contains("pack: feature-isolation"))
    }

    @Test("invalid merge failures return exit code 2")
    func invalidMergeFailuresReturnExitCodeTwo() throws {
        let root = try phase5DTemporaryDirectory()
        try phase5DWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: .
              include: []
              exclude: []
            rules:
              ForbiddenImportRule:
                enabled: true
                config:
                  forbiddenImports:
                    - UIKit
                    - Foundation
            architecture:
              forbiddenImports:
                -
                  from: Features/
                  imports:
                    - UIKit
                -
                  from: Features/
                  imports:
                    - Foundation
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let result = phase5DRunCLI(
            ["swiftlens", "scan", "--config", ".swiftlens.yml", "--format", "json"],
            fileManager: Phase5DFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Duplicate normalized scope identity `Features`"))
    }
}
