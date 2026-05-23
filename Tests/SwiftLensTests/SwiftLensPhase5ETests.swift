import Foundation
import Testing
@testable import SwiftLens

private let phase5ECLIExecutionLock = NSLock()

private func phase5ERunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5ECLIExecutionLock.lock()
    defer {
        phase5ECLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func phase5EReadText(at url: URL) throws -> String {
    try String(contentsOf: url, encoding: .utf8)
}

private func phase5ETemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "swiftlens-phase5e-\(UUID().uuidString)",
        isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func phase5EWriteText(_ text: String, to url: URL) throws {
    guard let data = text.data(using: .utf8) else {
        throw SwiftLensError.internalFailure("Unable to encode test text.")
    }

    try data.write(to: url, options: [.atomic])
}

private final class Phase5EFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5E")
struct SwiftLensPhase5ETests {
    private let expectedInitConfig = """
    version: 1
    preset: app-layers
    ignore:
      paths:
        - .build/
        - .swiftpm/
        - DerivedData/
    """

    private let expectedFeatureModulesInitConfig = """
    version: 1
    preset: feature-modules
    ignore:
      paths:
        - .build/
        - .swiftpm/
        - DerivedData/
    """

    private func tempFixture(
        fileName: String = "Example.swift",
        fileContents: String = "import Foundation\n\nstruct Example {}\n"
    ) throws -> URL {
        let root = try phase5ETemporaryDirectory()
        try phase5EWriteText(fileContents, to: root.appendingPathComponent(fileName))
        return root
    }

    private func runInit(
        in root: URL,
        preset: String? = nil,
        force: Bool = false
    ) -> CLIExecutionResult {
        var arguments = ["swiftlens", "init"]
        if let preset {
            arguments += ["--preset", preset]
        }
        if force {
            arguments.append("--force")
        }

        return phase5ERunCLI(
            arguments,
            fileManager: Phase5EFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
    }

    private func configURL(in root: URL) -> URL {
        root.appendingPathComponent(".swiftlens.yml")
    }

    @Test("init writes the default app-layers config")
    func initWritesDefaultAppLayersConfig() throws {
        let root = try tempFixture()
        let result = runInit(in: root)
        let contents = try phase5EReadText(at: configURL(in: root))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == "Wrote .swiftlens.yml with preset app-layers.\n")
        #expect(contents == expectedInitConfig + "\n")
    }

    @Test("init writes the requested preset config")
    func initWritesRequestedPresetConfig() throws {
        let root = try tempFixture()
        let result = runInit(in: root, preset: "feature-modules")
        let contents = try phase5EReadText(at: configURL(in: root))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == "Wrote .swiftlens.yml with preset feature-modules.\n")
        #expect(contents == expectedFeatureModulesInitConfig + "\n")
    }

    @Test("init rejects unknown presets deterministically")
    func initRejectsUnknownPresetsDeterministically() throws {
        let root = try tempFixture()
        let result = runInit(in: root, preset: "not-a-real-preset")

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown preset `not-a-real-preset`"))
        #expect(!FileManager.default.fileExists(atPath: configURL(in: root).path))
    }

    @Test("init rejects existing configs without --force")
    func initRejectsExistingConfigsWithoutForce() throws {
        let root = try tempFixture()
        try phase5EWriteText("version: 1\n", to: configURL(in: root))

        let result = runInit(in: root)

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Config file already exists"))
        #expect(try phase5EReadText(at: configURL(in: root)) == "version: 1\n")
    }

    @Test("init prefers overwrite protection over preset validation")
    func initPrefersOverwriteProtectionOverPresetValidation() throws {
        let root = try tempFixture()
        try phase5EWriteText("version: 1\n", to: configURL(in: root))

        let result = runInit(in: root, preset: "not-a-real-preset")

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Config file already exists"))
        #expect(try phase5EReadText(at: configURL(in: root)) == "version: 1\n")
    }

    @Test("init overwrites existing configs with --force")
    func initOverwritesExistingConfigsWithForce() throws {
        let root = try tempFixture()
        try phase5EWriteText("version: 0\n", to: configURL(in: root))

        let result = runInit(in: root, preset: "feature-modules", force: true)
        let contents = try phase5EReadText(at: configURL(in: root))

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(contents == expectedFeatureModulesInitConfig + "\n")
    }

    @Test("init output is byte stable across clean directories")
    func initOutputIsByteStableAcrossCleanDirectories() throws {
        let firstRoot = try tempFixture()
        let secondRoot = try tempFixture()

        let firstResult = runInit(in: firstRoot, preset: "feature-modules")
        let secondResult = runInit(in: secondRoot, preset: "feature-modules")

        let firstContents = try phase5EReadText(at: configURL(in: firstRoot))
        let secondContents = try phase5EReadText(at: configURL(in: secondRoot))

        #expect(firstResult.exitCode == 0)
        #expect(secondResult.exitCode == 0)
        #expect(firstContents == secondContents)
    }

    @Test("generated configs validate successfully")
    func generatedConfigsValidateSuccessfully() throws {
        let root = try tempFixture()
        _ = runInit(in: root)

        let result = phase5ERunCLI(
            ["swiftlens", "validate-config"],
            fileManager: Phase5EFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 0)
        #expect(result.stdout == "Configuration valid.\n")
        #expect(result.stderr.isEmpty)
    }

    @Test("generated configs scan successfully")
    func generatedConfigsScanSuccessfully() throws {
        let root = try tempFixture()
        _ = runInit(in: root, preset: "feature-modules")

        let result = phase5ERunCLI(
            ["swiftlens", "scan", ".", "--format", "json"],
            fileManager: Phase5EFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"violations\":[]"))
    }

    @Test("init help reports the init usage")
    func initHelpReportsInitUsage() throws {
        let result = phase5ERunCLI(["swiftlens", "init", "--help"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("swiftlens init [--preset NAME] [--force]"))
    }
}
