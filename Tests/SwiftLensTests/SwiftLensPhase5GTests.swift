import Foundation
import Testing
@testable import SwiftLens

private let phase5GCLIExecutionLock = NSLock()

private func phase5GRunCLI(
    _ arguments: [String],
    fileManager: FileManager = .default
) -> CLIExecutionResult {
    phase5GCLIExecutionLock.lock()
    defer {
        phase5GCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments, fileManager: fileManager)
}

private func phase5GDecodeReport(from result: CLIExecutionResult) throws -> ScanReport {
    try JSONDecoder().decode(ScanReport.self, from: Data(result.stdout.utf8))
}

private func phase5GDecodeBaseline(from url: URL) throws -> BaselineFile {
    let contents = try String(contentsOf: url, encoding: .utf8)
    return try JSONDecoder().decode(BaselineFile.self, from: Data(contents.utf8))
}

private func phase5GReadText(at url: URL) throws -> String {
    try String(contentsOf: url, encoding: .utf8)
}

private func phase5GWriteText(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let data = text.data(using: .utf8) else {
        throw SwiftLensError.internalFailure("Unable to encode test text.")
    }
    try data.write(to: url, options: [.atomic])
}

private func phase5GTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "swiftlens-phase5g-\(UUID().uuidString)",
        isDirectory: true
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private final class Phase5GFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5G")
struct SwiftLensPhase5GTests {
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
        let destination = try phase5GTemporaryDirectory().appendingPathComponent(name, isDirectory: true)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func scanResult(
        in root: URL,
        baselinePath: String? = nil
    ) -> CLIExecutionResult {
        var arguments = [
            "swiftlens",
            "scan",
            ".",
            "--config",
            ".swiftlens.yml",
            "--format",
            "json"
        ]
        if let baselinePath {
            arguments += ["--baseline", baselinePath]
        }

        return phase5GRunCLI(
            arguments,
            fileManager: Phase5GFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
    }

    private func baselineCreateResult(
        in root: URL,
        outputPath: String? = nil
    ) -> CLIExecutionResult {
        var arguments = [
            "swiftlens",
            "baseline",
            "create",
            "--config",
            ".swiftlens.yml"
        ]
        if let outputPath {
            arguments += ["--output", outputPath]
        }

        return phase5GRunCLI(
            arguments,
            fileManager: Phase5GFixedCurrentDirectoryFileManager(currentDirectoryPath: root.path)
        )
    }

    @Test("baseline create writes a deterministic baseline file from existing violations")
    func baselineCreateWritesDeterministicBaselineFile() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        let scan = scanResult(in: root)
        let report = try phase5GDecodeReport(from: scan)

        let result = baselineCreateResult(in: root)
        let baselineURL = root.appendingPathComponent(".swiftlens/baseline.json")
        let baseline = try phase5GDecodeBaseline(from: baselineURL)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("Created baseline:"))
        #expect(result.stdout.contains(".swiftlens/baseline.json"))
        #expect(result.stdout.contains("Stored violations: \(report.violations.count)"))
        #expect(baseline.version == 1)
        #expect(baseline.violations.count == report.violations.count)
        #expect(baseline.violations.allSatisfy { !$0.file.hasPrefix("/") })
        #expect(baseline.violations.allSatisfy { !$0.fingerprint.isEmpty })
    }

    @Test("baseline create honors a custom output path")
    func baselineCreateHonorsACustomOutputPath() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        let result = baselineCreateResult(
            in: root,
            outputPath: "artifacts/custom-baseline.json"
        )
        let baselineURL = root.appendingPathComponent("artifacts/custom-baseline.json")

        #expect(result.exitCode == 0)
        #expect(FileManager.default.fileExists(atPath: baselineURL.path))
        #expect(try phase5GDecodeBaseline(from: baselineURL).version == 1)
    }

    @Test("repeated baseline creation produces identical bytes")
    func repeatedBaselineCreationProducesIdenticalBytes() throws {
        let firstRoot = try copiedFixture("PresetFeatureModulesScanned")
        let secondRoot = try copiedFixture("PresetFeatureModulesScanned")

        let firstResult = baselineCreateResult(in: firstRoot)
        let secondResult = baselineCreateResult(in: secondRoot)
        let firstBaseline = try phase5GReadText(
            at: firstRoot.appendingPathComponent(".swiftlens/baseline.json")
        )
        let secondBaseline = try phase5GReadText(
            at: secondRoot.appendingPathComponent(".swiftlens/baseline.json")
        )

        #expect(firstResult.exitCode == 0)
        #expect(secondResult.exitCode == 0)
        #expect(firstBaseline == secondBaseline)
    }

    @Test("scan suppresses violations already captured in the baseline")
    func scanSuppressesViolationsAlreadyCapturedInTheBaseline() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        _ = baselineCreateResult(in: root)

        let result = scanResult(in: root, baselinePath: ".swiftlens/baseline.json")
        let report = try phase5GDecodeReport(from: result)

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(report.violations.isEmpty)
    }

    @Test("scan reports only new violations when a baseline is present")
    func scanReportsOnlyNewViolationsWhenABaselineIsPresent() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        _ = baselineCreateResult(in: root)

        let regressionFile = root.appendingPathComponent("Features/NewRegression.swift")
        try phase5GWriteText(
            """
            import Features.Auth

            struct NewRegression {}
            """,
            to: regressionFile
        )

        let result = scanResult(in: root, baselinePath: ".swiftlens/baseline.json")
        let report = try phase5GDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(result.stderr.isEmpty)
        #expect(report.violations.count == 1)
        #expect(report.violations.first?.file.hasSuffix("Features/NewRegression.swift") == true)
    }

    @Test("scan preserves violation ordering after baseline filtering")
    func scanPreservesViolationOrderingAfterBaselineFiltering() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        let scan = scanResult(in: root)
        let report = try phase5GDecodeReport(from: scan)
        let target = report.violations[1]

        let baseline = BaselineFile(
            version: 1,
            violations: [
                BaselineViolation(
                    fingerprint: BaselineFingerprintGenerator().fingerprint(
                        for: target,
                        projectRootPath: report.projectPath
                    ),
                    rule: target.rule,
                    file: canonicalRelativePath(
                        for: URL(fileURLWithPath: target.file),
                        root: URL(fileURLWithPath: report.projectPath, isDirectory: true)
                    ),
                    reason: target.reason
                )
            ]
        )

        let baselineURL = root.appendingPathComponent(".swiftlens/baseline.json")
        try BaselineStore(fileManager: FileManager.default).write(baseline, to: baselineURL)

        let result = scanResult(in: root, baselinePath: ".swiftlens/baseline.json")
        let filtered = try phase5GDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(filtered.violations.map(\.file) == [
            report.violations[0].file,
            report.violations[2].file
        ])
    }

    @Test("empty baselines keep current violations visible")
    func emptyBaselinesKeepCurrentViolationsVisible() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        let baselineURL = root.appendingPathComponent(".swiftlens/baseline.json")
        let emptyBaseline = BaselineFile(version: 1, violations: [])
        try BaselineStore(fileManager: FileManager.default).write(emptyBaseline, to: baselineURL)

        let result = scanResult(in: root, baselinePath: ".swiftlens/baseline.json")
        let report = try phase5GDecodeReport(from: result)

        #expect(result.exitCode == 1)
        #expect(report.violations.count == 3)
    }

    @Test("invalid baselines fail with exit code 2")
    func invalidBaselinesFailWithExitCodeTwo() throws {
        let root = try copiedFixture("PresetFeatureModulesScanned")
        let baselineURL = root.appendingPathComponent(".swiftlens/baseline.json")
        try phase5GWriteText(
            """
            {"version":2,"violations":[]}
            """,
            to: baselineURL
        )

        let result = scanResult(in: root, baselinePath: ".swiftlens/baseline.json")

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("baseline"))
    }

    @Test("help output exposes baseline workflow flags")
    func helpOutputExposesBaselineWorkflowFlags() throws {
        let result = phase5GRunCLI(["swiftlens", "help"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("swiftlens baseline create"))
        #expect(result.stdout.contains("--baseline PATH"))
    }
}
