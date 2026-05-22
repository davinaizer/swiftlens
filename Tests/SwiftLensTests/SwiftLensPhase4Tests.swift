import Foundation
import Testing
@testable import SwiftLens

private let phase4CLIExecutionLock = NSLock()

private func phase4RunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase4CLIExecutionLock.lock()
    defer {
        phase4CLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func decodeReport(from result: CLIExecutionResult) throws -> ScanReport {
    try JSONDecoder().decode(ScanReport.self, from: Data(result.stdout.utf8))
}

private final class Phase4FixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 4")
struct SwiftLensPhase4Tests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    private func scanResult(_ arguments: [String], in fixture: URL) -> CLIExecutionResult {
        phase4RunCLI(
            arguments,
            fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )
    }

    @Test("flat config flags matching path imports")
    func scanFlagsMatchingPathImports() throws {
        let fixture = fixtureURL("FlatGovernance")
        let result = scanResult([
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ], in: fixture)

        let report = try decodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.contains(where: { $0.file.contains("Features/Match.swift") }))
        #expect(report.violations.contains(where: { $0.file.contains("Features/A.swift") }))
    }

    @Test("flat config leaves non-forbidden imports alone")
    func scanLeavesNonForbiddenImportsAlone() throws {
        let fixture = fixtureURL("FlatGovernance")
        let result = scanResult([
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ], in: fixture)

        let report = try decodeReport(from: result)

        #expect(report.violations.contains(where: { $0.file.contains("Features/NoMatch.swift") }) == false)
    }

    @Test("flat config ignores outside matching source paths")
    func scanIgnoresOutsideMatchingSourcePaths() throws {
        let fixture = fixtureURL("FlatGovernance")
        let result = scanResult([
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ], in: fixture)

        let report = try decodeReport(from: result)

        #expect(report.violations.contains(where: { $0.file.contains("Infrastructure/Outside.swift") }) == false)
    }

    @Test("flat config skips ignored paths before parsing")
    func scanSkipsIgnoredPathsBeforeParsing() throws {
        let fixture = fixtureURL("FlatGovernance")
        let result = scanResult([
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ], in: fixture)

        let report = try decodeReport(from: result)

        #expect(report.summary.filesScanned == 5)
        #expect(report.violations.contains(where: { $0.file.contains("DerivedData/Ignored.swift") }) == false)
    }

    @Test("flat config produces deterministic violation order")
    func scanProducesDeterministicViolationOrder() throws {
        let fixture = fixtureURL("FlatGovernance")
        let result = scanResult([
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ], in: fixture)

        let report = try decodeReport(from: result)
        let files = report.violations.map(\.file)

        #expect(files == [
            fixture.path + "/Features/A.swift",
            fixture.path + "/Features/B.swift",
            fixture.path + "/Features/Match.swift"
        ])
    }

    @Test("path normalization resolves dot-dot segments")
    func normalizeRelativePathResolvesDotDotSegments() throws {
        #expect(normalizeRelativePath("Features/../Features/") == "Features")
        #expect(pathMatchesPrefixBoundary("Features/Profile/View.swift", prefix: "Features/../Features/"))
    }

    @Test("validate-config rejects missing rules section")
    func validateConfigRejectsMissingRulesSection() throws {
        let fixture = fixtureURL("FlatMissingRules")
        let result = phase4RunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path
        ], fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Missing required `rules` section"))
    }

    @Test("validate-config accepts missing architecture.forbiddenImports")
    func validateConfigAcceptsMissingArchitectureForbiddenImports() throws {
        let fixture = fixtureURL("FlatMissingArchitecture")
        let result = phase4RunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path
        ], fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
    }

    @Test("validate-config accepts empty architecture.forbiddenImports")
    func validateConfigAcceptsEmptyArchitectureForbiddenImports() throws {
        let fixture = fixtureURL("FlatEmptyArchitecture")
        let result = phase4RunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path
        ], fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
    }

    @Test("validate-config rejects invalid architecture.forbiddenImports")
    func validateConfigRejectsInvalidArchitectureForbiddenImports() throws {
        let fixture = fixtureURL("FlatInvalidArchitecture")
        let result = phase4RunCLI([
            "swiftlens",
            "validate-config",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path
        ], fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("architecture.forbiddenImports"))
    }

    @Test("legacy ForbiddenImportRule config resolves through the alias path")
    func legacyForbiddenImportConfigResolvesThroughAliasPath() throws {
        let fixture = fixtureURL("ScanFailure")
        let result = phase4RunCLI([
            "swiftlens",
            "scan",
            "--config",
            fixture.appendingPathComponent(".swiftlens.yml").path,
            "--format",
            "json"
        ], fileManager: Phase4FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))

        let report = try decodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.contains(where: { $0.rule == "architecture.forbidden-import" }))
    }
}
