import Foundation
import Testing
@testable import SwiftLens

private let cliExecutionLock = NSLock()

private func jsonEscapedPath(_ path: String) -> String {
    path.replacingOccurrences(of: "/", with: "\\/")
}

private func runCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    cliExecutionLock.lock()
    defer {
        cliExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private final class FixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 3A")
struct SwiftLensPhase3ATests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    private func scanResult(_ arguments: [String], in fixture: URL) -> CLIExecutionResult {
        runCLI(arguments, fileManager: FixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path))
    }

    @Test("swiftlens defaults to scan . when invoked without arguments")
    func commandWithoutArgumentsDefaultsToScan() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path)

        let result = scanResult(["swiftlens"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"command\":\"scan\""))
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan accepts a positional dot path")
    func scanAcceptsPositionalDotPath() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path)

        let result = scanResult(["swiftlens", "scan", "."], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan accepts a positional Sources path")
    func scanAcceptsPositionalSourcesPath() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path + "/Sources")

        let result = scanResult(["swiftlens", "scan", "Sources"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan accepts a nested positional path")
    func scanAcceptsNestedPositionalPath() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path + "/Sources/Features")

        let result = scanResult(["swiftlens", "scan", "Sources/Features"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan accepts --path")
    func scanAcceptsPathFlag() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path + "/Sources")

        let result = scanResult(["swiftlens", "scan", "--path", "Sources"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan prefers --path over a positional path")
    func scanPrefersPathFlagOverPositionalPath() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path + "/Sources")

        let result = scanResult(["swiftlens", "scan", ".", "--path", "Sources"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("swiftlens scan resolves config from the current working directory only")
    func scanUsesCurrentDirectoryConfigOnly() throws {
        let childDirectory = fixtureURL("ScanSuccess")
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("Feature", isDirectory: true)

        let result = runCLI(
            ["swiftlens", "scan"],
            fileManager: FixedCurrentDirectoryFileManager(currentDirectoryPath: childDirectory.path)
        )

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Config file not found"))
    }

    @Test("swiftlens scan continues to use the cwd config when present")
    func scanUsesCwdConfigWhenPresent() throws {
        let fixture = fixtureURL("ScanSuccess")
        let escapedProjectPath = jsonEscapedPath(fixture.path)

        let result = scanResult(["swiftlens", "scan"], in: fixture)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"projectPath\":\"\(escapedProjectPath)\""))
    }

    @Test("default scan root ignores project.path when omitted")
    func defaultScanRootIgnoresProjectPath() throws {
        let fixture = fixtureURL("DefaultScanRoot")

        let bareResult = scanResult(["swiftlens"], in: fixture)
        let scanResult = scanResult(["swiftlens", "scan"], in: fixture)

        #expect(bareResult.exitCode == 1)
        #expect(scanResult.exitCode == 1)
        #expect(bareResult.stdout.contains("ForbiddenImportRule"))
        #expect(scanResult.stdout.contains("ForbiddenImportRule"))
    }

    @Test("swiftlens scan rejects trailing positional arguments")
    func scanRejectsTrailingPositionalArguments() throws {
        let fixture = fixtureURL("ScanSuccess")

        let result = scanResult(["swiftlens", "scan", "Sources", "extra"], in: fixture)

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unexpected argument `extra`"))
    }

    @Test("swiftlens scan rejects duplicate path flags")
    func scanRejectsDuplicatePathFlags() throws {
        let fixture = fixtureURL("ScanSuccess")

        let result = scanResult([
            "swiftlens",
            "scan",
            "--path",
            "Sources",
            "--path",
            "Sources/Features"
        ], in: fixture)

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Duplicate flag `--path`"))
    }

    @Test("swiftlens scan rejects unsupported format values")
    func scanRejectsUnsupportedFormatValues() throws {
        let fixture = fixtureURL("ScanSuccess")

        let result = scanResult([
            "swiftlens",
            "scan",
            "--format",
            "yaml"
        ], in: fixture)

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Only `--format json` is supported"))
    }
}
