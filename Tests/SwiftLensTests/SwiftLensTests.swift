import Foundation
import Testing
@testable import SwiftLens

@Suite("SwiftLens Phase 1")
struct SwiftLensPhase1Tests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    @Test("scan succeeds when no forbidden imports are present")
    func scanSucceedsWithoutViolations() throws {
        let config = fixtureRoot
            .appendingPathComponent("ScanSuccess", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = SwiftLensCLI.execute(
            arguments: ["swiftlens", "scan", "--config", config.path, "--format", "json"]
        )

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"violations\":[]"))
    }

    @Test("scan fails with an emitted forbidden import violation")
    func scanFailsOnForbiddenImport() throws {
        let config = fixtureRoot
            .appendingPathComponent("ScanFailure", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = SwiftLensCLI.execute(
            arguments: ["swiftlens", "scan", "--config", config.path, "--format", "json"]
        )

        #expect(result.exitCode == 1)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("ForbiddenImportRule"))
        #expect(result.stdout.contains("\"violations\":"))
    }

    @Test("validate-config rejects unknown keys")
    func validateConfigRejectsUnknownKeys() throws {
        let config = fixtureRoot
            .appendingPathComponent("InvalidConfig", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = SwiftLensCLI.execute(
            arguments: ["swiftlens", "validate-config", "--config", config.path]
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown top-level key"))
    }

    @Test("validate-config rejects unrelated flags")
    func validateConfigRejectsUnrelatedFlags() throws {
        let config = fixtureRoot
            .appendingPathComponent("ScanSuccess", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = SwiftLensCLI.execute(
            arguments: ["swiftlens", "validate-config", "--config", config.path, "--verbose"]
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown flag `--verbose`"))
    }
}
