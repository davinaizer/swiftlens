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

        let result = runCLI(["swiftlens", "scan", "--config", config.path, "--format", "json"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"violations\":[]"))
    }

    @Test("scan fails with an emitted forbidden import violation")
    func scanFailsOnForbiddenImport() throws {
        let config = fixtureRoot
            .appendingPathComponent("ScanFailure", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = runCLI(["swiftlens", "scan", "--config", config.path, "--format", "json"])

        #expect(result.exitCode == 1)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("architecture.forbidden-import"))
        #expect(result.stdout.contains("\"violations\":"))
    }

    @Test("validate-config rejects unknown keys")
    func validateConfigRejectsUnknownKeys() throws {
        let config = fixtureRoot
            .appendingPathComponent("InvalidConfig", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = runCLI(["swiftlens", "validate-config", "--config", config.path])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown top-level key"))
    }

    @Test("validate-config rejects unrelated flags")
    func validateConfigRejectsUnrelatedFlags() throws {
        let config = fixtureRoot
            .appendingPathComponent("ScanSuccess", isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")

        let result = runCLI(["swiftlens", "validate-config", "--config", config.path, "--verbose"])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown flag `--verbose`"))
    }

    @Test("version reports the generated release version")
    func versionReportsGeneratedReleaseVersion() throws {
        let result = runCLI(["swiftlens", "version"])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout == "SwiftLens \(SwiftLensVersion.current)\n")
    }
}

@Suite("SwiftLens Phase 2")
struct SwiftLensPhase2Tests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func configURL(_ fixtureName: String) -> URL {
        fixtureRoot
            .appendingPathComponent(fixtureName, isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")
    }

    private func scanResult(for fixtureName: String) -> CLIExecutionResult {
        runCLI([
            "swiftlens",
            "scan",
            "--config",
            configURL(fixtureName).path,
            "--format",
            "json"
        ])
    }

    @Test("scan honors pack severity overrides")
    func scanHonorsPackSeverityOverrides() throws {
        let result = scanResult(for: "PackSeverityOverride")

        #expect(result.exitCode == 1)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"rule\":\"architecture.forbidden-import\""))
        #expect(result.stdout.contains("\"severity\":\"warning\""))
    }

    @Test("scan lets rule severity override pack severity overrides")
    func scanLetsRuleSeverityOverrideWin() throws {
        let result = scanResult(for: "RuleSeverityOverride")

        #expect(result.exitCode == 1)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"rule\":\"architecture.forbidden-import\""))
        #expect(result.stdout.contains("\"severity\":\"error\""))
    }

    @Test("scan disables a rule when its configuration turns it off")
    func scanDisablesRuleWhenDisabled() throws {
        let result = scanResult(for: "RuleDisabled")

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("\"violations\":[]"))
    }

    @Test("validate-config accepts the phase 2 config schema")
    func validateConfigAcceptsPhase2Schema() throws {
        let result = runCLI([
            "swiftlens",
            "validate-config",
            "--config",
            configURL("ScanSuccess").path
        ])

        #expect(result.exitCode == 0)
        #expect(result.stderr.isEmpty)
        #expect(result.stdout.contains("Configuration valid."))
    }

    @Test("validate-config rejects unknown pack names")
    func validateConfigRejectsUnknownPackNames() throws {
        let result = runCLI([
            "swiftlens",
            "validate-config",
            "--config",
            configURL("InvalidPack").path
        ])

        #expect(result.exitCode == 2)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("Unknown pack key"))
    }

    @Test("rule engine preserves descriptor order")
    func ruleEnginePreservesDescriptorOrder() throws {
        func descriptor(id: String) -> RuleDescriptor {
            RuleDescriptor(
                id: id,
                pack: "architecture",
                defaultSeverity: .warning,
                defaultConfidence: .high,
                defaultEnabled: true,
                explanation: RuleExplanation(
                    purpose: ["Test rule."],
                    detectionMechanism: ["Test rule."],
                    configShape: ["Test rule."],
                    deterministicBehavior: ["Test rule."],
                    limitations: ["Test rule."],
                    exampleViolation: ["Test rule."],
                    exampleConfig: ["Test rule."]
                ),
                evaluate: { context in
                    [
                        Violation(
                            rule: context.descriptor.id,
                            pack: context.descriptor.pack,
                            severity: context.settings.severity,
                            confidence: context.settings.confidence,
                            file: "fixture.swift",
                            range: SourceRange(
                                start: SourceLocation(line: 1, column: 1),
                                end: SourceLocation(line: 1, column: 1)
                            ),
                            reason: "Test rule \(context.descriptor.id).",
                            fixPattern: nil
                        )
                    ]
                }
            )
        }

        let registry = RuleRegistry(descriptors: [descriptor(id: "AlphaRule"), descriptor(id: "BetaRule")])
        let engine = RuleEngine(registry: registry)
        let config = SwiftLensConfig(
            project: ProjectConfiguration(path: ".", include: [], exclude: []),
            packs: [
                "architecture": PackConfiguration(enabled: true, severityOverrides: [:])
            ],
            rules: [:],
            ruleOrder: ["AlphaRule", "BetaRule"]
        )

        let violations = engine.evaluate(config: config, files: [])

        #expect(violations.map { $0.rule } == ["AlphaRule", "BetaRule"])
    }
}
