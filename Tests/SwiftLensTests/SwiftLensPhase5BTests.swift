import Foundation
import Testing
@testable import SwiftLens

private let phase5BCLIExecutionLock = NSLock()

private func phase5BRunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5BCLIExecutionLock.lock()
    defer {
        phase5BCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func phase5BDecodeReport(from result: CLIExecutionResult) throws -> ScanReport {
    try JSONDecoder().decode(ScanReport.self, from: Data(result.stdout.utf8))
}

private final class Phase5BFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5B")
struct SwiftLensPhase5BTests {
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

    private func scanResult(_ fixtureName: String) -> CLIExecutionResult {
        let fixture = fixtureURL(fixtureName)
        return phase5BRunCLI(
            [
                "swiftlens",
                "scan",
                "--config",
                configURL(fixtureName).path,
                "--format",
                "json"
            ],
            fileManager: Phase5BFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )
    }

    @Test("app-layers enforces conservative layer boundaries")
    func appLayersEnforcesConservativeLayerBoundaries() throws {
        let fixture = fixtureURL("PresetAppLayers")
        let result = scanResult("PresetAppLayers")
        let report = try phase5BDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.map(\.file) == [
            fixture.path + "/Domain/Alpha.swift",
            fixture.path + "/Domain/Beta.swift",
            fixture.path + "/UI/Gamma.swift"
        ])
        #expect(report.violations.contains(where: { $0.file.contains("Domainish/Alpha.swift") }) == false)
        #expect(report.violations.contains(where: { $0.file.contains("App/App.swift") }) == false)
    }

    @Test("feature-modules isolates sibling features and shared/core code")
    func featureModulesIsolateSiblingFeaturesAndSharedCoreCode() throws {
        let fixture = fixtureURL("PresetFeatureModulesScanned")
        let result = scanResult("PresetFeatureModulesScanned")
        let report = try phase5BDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.map(\.file) == [
            fixture.path + "/Core/Core.swift",
            fixture.path + "/Features/Auth/AuthFeature.swift",
            fixture.path + "/Shared/Shared.swift"
        ])
        #expect(report.violations.contains(where: { $0.file.contains("App/App.swift") }) == false)
        #expect(
            report.violations.contains(where: {
                $0.file.contains("Features/Profile/ProfileFeature.swift")
            }) == false
        )
    }

    @Test("tca-features keeps dependency clients and sibling feature imports isolated")
    func tcaFeaturesKeepsDependencyClientsAndSiblingFeatureImportsIsolated() throws {
        let fixture = fixtureURL("PresetTCAFeatures")
        let result = scanResult("PresetTCAFeatures")
        let report = try phase5BDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.map(\.file) == [
            fixture.path + "/Dependencies/Live.swift",
            fixture.path + "/Features/Auth/AuthFeature.swift",
            fixture.path + "/Features/Auth/AuthView.swift",
            fixture.path + "/Shared/Shared.swift"
        ])
        #expect(report.violations.filter { $0.file.contains("Features/Auth/AuthFeature.swift") }.count == 1)
        #expect(
            report.violations.contains(where: {
                $0.file.contains("Features/Auth/AuthView.swift") && $0.reason.contains("SwiftUI")
            })
        )
        #expect(
            report.violations.contains(where: {
                $0.file.contains("Features/Profile/ProfileFeature.swift")
            }) == false
        )
    }
}
