import Foundation
import Testing
@testable import SwiftLens

@Suite("SwiftLens Phase 5H Boundary")
struct SwiftLensPhase5HBoundaryTests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    @Test("boundary list is byte stable across repeated runs")
    func boundaryListIsByteStableAcrossRepeatedRuns() throws {
        let fixture = fixtureURL("PresetFeatureModulesScanned")
        let fileManager = Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        let first = phase5HRunCLI(["swiftlens", "boundary", "list"], fileManager: fileManager)
        let second = phase5HRunCLI(["swiftlens", "boundary", "list"], fileManager: fileManager)

        #expect(first.exitCode == 0)
        #expect(second.exitCode == 0)
        #expect(first.stdout == second.stdout)
    }

    @Test("boundary list rejects missing configs with exit code 2")
    func boundaryListRejectsMissingConfigsWithExitCodeTwo() throws {
        let root = try phase5HTemporaryDirectory()
        let result = phase5HRunCLI(
            ["swiftlens", "boundary", "list"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Config file not found"))
    }

    @Test("boundary list rejects invalid configs")
    func boundaryListRejectsInvalidConfigs() throws {
        let fixture = fixtureURL("InvalidPreset")
        let result = phase5HRunCLI([
            "swiftlens",
            "boundary",
            "list",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path
        ])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown preset `not-a-real-preset`"))
    }

    @Test("boundary help reports usage deterministically")
    func boundaryHelpReportsUsageDeterministically() throws {
        let result = phase5HRunCLI(["swiftlens", "boundary", "--help"])
        let repeatResult = phase5HRunCLI(["swiftlens", "boundary", "--help"])

        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout.contains("swiftlens boundary list [--config PATH]"))
        #expect(result.stdout == repeatResult.stdout)
    }
}
