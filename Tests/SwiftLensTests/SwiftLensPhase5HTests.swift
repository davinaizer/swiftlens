import Foundation
import Testing
@testable import SwiftLens

private let phase5HCLIExecutionLock = NSLock()

func phase5HRunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5HCLIExecutionLock.lock()
    defer {
        phase5HCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

func phase5HWriteText(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let data = text.data(using: .utf8) else {
        throw SwiftLensError.internalFailure("Unable to encode test text.")
    }
    try data.write(to: url, options: [.atomic])
}

func phase5HTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "swiftlens-phase5h-\(UUID().uuidString)",
        isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

final class Phase5HFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5H")
struct SwiftLensPhase5HTests {
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
        let destination = try phase5HTemporaryDirectory().appendingPathComponent(
            name,
            isDirectory: true
        )
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func featureModulesBoundaryListOutput() -> String {
        """
        Project Boundaries

        Preset:
        - feature-modules

        Ignored Paths:
        - .build/
        - .swiftpm/
        - DerivedData/

        Boundaries:
        - App/
          Source:
            - preset
          Allows:
            - Features/*
            - Shared/*
            - Core/*

        - Features/
          Source:
            - pack: feature-isolation
          Restricted Imports:
            - Features/*

        - Shared/
          Source:
            - pack: shared-boundaries
          Restricted Imports:
            - Features/*

        - Core/
          Source:
            - pack: shared-boundaries
          Restricted Imports:
            - Features/*
        """
            + "\n"
    }

    @Test("boundary list renders preset-aware boundaries and ignore paths")
    func boundaryListRendersPresetAwareBoundariesAndIgnorePaths() throws {
        let root = try phase5HTemporaryDirectory()
        let initResult = phase5HRunCLI(
            ["swiftlens", "init", "--preset", "feature-modules"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
        let result = phase5HRunCLI(
            ["swiftlens", "boundary", "list"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
        let repeatResult = phase5HRunCLI(
            ["swiftlens", "boundary", "list", "--config", ".swiftlens.yml"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(initResult.exitCode == 0)
        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(initResult.stderr.isEmpty)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout == featureModulesBoundaryListOutput())
        #expect(repeatResult.stdout == featureModulesBoundaryListOutput())
        #expect(result.stdout == repeatResult.stdout)
    }

    @Test("boundary list renders explicit config overrides deterministically")
    func boundaryListRendersExplicitConfigOverridesDeterministically() throws {
        let fixture = try copiedFixture("PresetFeatureModulesOverride")
        let fileManager = Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        let result = phase5HRunCLI(["swiftlens", "boundary", "list"], fileManager: fileManager)
        let repeatResult = phase5HRunCLI(
            ["swiftlens", "boundary", "list", "--config", ".swiftlens.yml"],
            fileManager: fileManager
        )

        let expected = """
        Project Boundaries

        Preset:
        - feature-modules

        Ignored Paths:
        - none

        Boundaries:
        - App/
          Source:
            - preset
          Allows:
            - Features/*
            - Shared/*
            - Core/*

        - Features/
          Source:
            - explicit-config
          Restricted Imports:
            - Foundation

        - Shared/
          Source:
            - pack: shared-boundaries
          Restricted Imports:
            - Features/*

        - Core/
          Source:
            - pack: shared-boundaries
          Restricted Imports:
            - Features/*
        """
            + "\n"

        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout == expected)
        #expect(repeatResult.stdout == expected)
    }

    @Test("boundary list hides forbidden-import boundaries when the rule is disabled")
    func boundaryListHidesForbiddenImportBoundariesWhenRuleIsDisabled() throws {
        let fixture = try copiedFixture("PresetFeatureModulesScanned")
        try phase5HWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: .
              include: []
              exclude: []
            rules:
              ForbiddenImportRule:
                enabled: false
                config:
                  forbiddenImports: []
            ignore:
              paths:
                - .build/
                - .swiftpm/
                - DerivedData/
            """,
            to: fixture.appendingPathComponent(".swiftlens.yml")
        )

        let result = phase5HRunCLI(
            ["swiftlens", "boundary", "list"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("Preset:\n- feature-modules"))
        #expect(result.stdout.contains("Boundaries:\n- none"))
    }

    @Test("boundary list does not require the project root to exist")
    func boundaryListDoesNotRequireTheProjectRootToExist() throws {
        let root = try phase5HTemporaryDirectory()
        try phase5HWriteText(
            """
            version: 1
            preset: feature-modules
            project:
              path: MissingProjectRoot
              include: []
              exclude: []
            ignore:
              paths:
                - .build/
                - .swiftpm/
                - DerivedData/
            """,
            to: root.appendingPathComponent(".swiftlens.yml")
        )

        let result = phase5HRunCLI(
            ["swiftlens", "boundary", "list"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
        let repeatResult = phase5HRunCLI(
            ["swiftlens", "boundary", "list", "--config", ".swiftlens.yml"],
            fileManager: Phase5HFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )

        #expect(result.exitCode == 0)
        #expect(repeatResult.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(repeatResult.stderr.isEmpty)
        #expect(result.stdout == featureModulesBoundaryListOutput())
        #expect(repeatResult.stdout == featureModulesBoundaryListOutput())
    }

}
