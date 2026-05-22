import Foundation
import Testing
@testable import SwiftLens

private let phase5ACLIExecutionLock = NSLock()

private func phase5ARunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5ACLIExecutionLock.lock()
    defer {
        phase5ACLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func phase5ADecodeReport(from result: CLIExecutionResult) throws -> ScanReport {
    try JSONDecoder().decode(ScanReport.self, from: Data(result.stdout.utf8))
}

private final class Phase5AFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5A")
struct SwiftLensPhase5ATests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    private func configURL(_ fixtureName: String) -> URL {
        fixtureURL(fixtureName).appendingPathComponent(".swiftlens.yml")
    }

    @Test("preset registry keeps stable built-in preset IDs")
    func presetRegistryKeepsStablePresetIDs() throws {
        #expect(PresetRegistry.default.presetIDs == [
            "app-layers",
            "feature-modules",
            "tca-features"
        ])
    }

    @Test("known preset resolves through config loading")
    func knownPresetResolvesThroughConfigLoading() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let loader = ConfigLoader(
            fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        let loaded = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(loaded.config.presetID == "feature-modules")
        #expect(loaded.config.ruleOrder == [ForbiddenImportRule.descriptor.id])
        #expect(loaded.config.rules[ForbiddenImportRule.descriptor.id] != nil)
    }

    @Test("preset-only configs load without an explicit project block")
    func presetOnlyConfigsLoadWithoutExplicitProjectBlock() throws {
        let fixture = fixtureURL("PresetOnly")
        let loader = ConfigLoader(
            fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        let loaded = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(loaded.config.presetID == "feature-modules")
        #expect(loaded.config.project.path == ".")
    }

    @Test("unknown preset fails deterministically")
    func unknownPresetFailsDeterministically() throws {
        let fixture = fixtureURL("InvalidPreset")
        let result = phase5ARunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            configURL("InvalidPreset").path
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown preset `not-a-real-preset`"))
    }

    @Test("unsupported config versions fail deterministically")
    func unsupportedConfigVersionsFailDeterministically() throws {
        let fixture = fixtureURL("InvalidVersion")
        let result = phase5ARunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            configURL("InvalidVersion").path
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unsupported config version `2`"))
    }

    @Test("preset expansion order stays deterministic")
    func presetExpansionOrderStaysDeterministic() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let loader = ConfigLoader(
            fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        let first = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)
        let second = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)

        #expect(first.config == second.config)
    }

    @Test("explicit config overrides preset defaults")
    func explicitConfigOverridesPresetDefaults() throws {
        let fixture = fixtureURL("PresetFeatureModulesOverride")
        let result = phase5ARunCLI([
            "swiftlens",
            "scan",
            "--config",
            configURL("PresetFeatureModulesOverride").path,
            "--format",
            "json"
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        let report = try phase5ADecodeReport(from: result)

        #expect(result.exitCode == 0)
        #expect(report.violations.isEmpty)
    }

    @Test("JSON output remains deterministic across repeated runs")
    func jsonOutputRemainsDeterministicAcrossRepeatedRuns() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let first = phase5ARunCLI([
            "swiftlens",
            "scan",
            "--config",
            configURL("PresetFeatureModules").path,
            "--format",
            "json"
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))
        let second = phase5ARunCLI([
            "swiftlens",
            "scan",
            "--config",
            configURL("PresetFeatureModules").path,
            "--format",
            "json"
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(first.exitCode == 1)
        #expect(second.exitCode == 1)
        #expect(first.stdout == second.stdout)
    }

    @Test("non-preset configs continue to work")
    func nonPresetConfigsContinueToWork() throws {
        let fixture = fixtureURL("ScanSuccess")
        let result = phase5ARunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            configURL("ScanSuccess").path
        ], fileManager: Phase5AFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("Configuration valid."))
    }
}
