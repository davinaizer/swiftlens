import Foundation
import Testing
@testable import SwiftLens

private let phase5CCLIExecutionLock = NSLock()

private func phase5CRunCLI(_ arguments: [String]) -> CLIExecutionResult {
    phase5CCLIExecutionLock.lock()
    defer {
        phase5CCLIExecutionLock.unlock()
    }

    return SwiftLensCLI.execute(arguments: arguments)
}

private final class Phase5CFixedCurrentDirectoryFileManager: FileManager {
    private let fixedCurrentDirectoryPath: String

    init(currentDirectoryPath: String) {
        self.fixedCurrentDirectoryPath = currentDirectoryPath
        super.init()
    }

    override var currentDirectoryPath: String {
        fixedCurrentDirectoryPath
    }
}

@Suite("SwiftLens Phase 5C")
struct SwiftLensPhase5CTests {
    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    private func fixtureURL(_ name: String) -> URL {
        fixtureRoot.appendingPathComponent(name, isDirectory: true)
    }

    private func makeForbiddenImportPack(
        id: String,
        from scope: String,
        imports: [String]
    ) -> RulePackDescriptor {
        RulePackDescriptor(
            id: id,
            expansion: RulePackExpansion(
                rules: [
                    ForbiddenImportRule.descriptor.id: RuleConfiguration(
                        enabled: true,
                        severity: nil,
                        config: ForbiddenImportSupport.canonicalConfig(from: [
                            ForbiddenImportScope(from: scope, imports: imports)
                        ])
                    )
                ],
                ruleOrder: [ForbiddenImportRule.descriptor.id]
            ),
            explanation: RulePackExplanation(
                description: ["\(id) pack."],
                enabledRules: [ForbiddenImportRule.descriptor.id],
                generatedBoundaries: [],
                intendedUsage: ["Test only."],
                notes: ["Test only."],
                limitations: ["Test only."]
            )
        )
    }

    @Test("pack registry keeps stable built-in pack IDs")
    func packRegistryKeepsStableBuiltInPackIDs() throws {
        #expect(RulePackRegistry.default.packIDs == [
            "feature-isolation",
            "shared-boundaries",
            "app-shell",
            "domain-ui-separation",
            "dependency-direction"
        ])
    }

    @Test("duplicate pack IDs fail deterministically")
    func duplicatePackIDsFailDeterministically() throws {
        let duplicate = RulePackDescriptor(
            id: "duplicate",
            expansion: RulePackExpansion(rules: [:], ruleOrder: []),
            explanation: RulePackExplanation(
                description: ["Duplicate pack."],
                enabledRules: [],
                generatedBoundaries: [],
                intendedUsage: ["Test only."],
                notes: ["Test only."],
                limitations: ["Test only."]
            )
        )

        do {
            _ = try RulePackRegistry(descriptors: [duplicate, duplicate])
            #expect(Bool(false))
        } catch let error as RulePackRegistryError {
            #expect(error == .duplicatePackID("duplicate"))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("preset compositions expand through built-in packs")
    func presetCompositionsExpandThroughBuiltInPacks() throws {
        let fixture = fixtureURL("PresetFeatureModules")
        let loader = ConfigLoader(
            fileManager: Phase5CFixedCurrentDirectoryFileManager(currentDirectoryPath: fixture.path)
        )

        let loaded = try loader.load(configPath: ".swiftlens.yml", projectPathOverride: nil)
        let ruleConfig = try #require(loaded.config.rules[ForbiddenImportRule.descriptor.id])
        let scopes = try ForbiddenImportSupport.decodeScopes(
            from: ruleConfig.config["forbiddenImports"],
            field: "forbiddenImports"
        )

        #expect(loaded.config.ruleOrder == [ForbiddenImportRule.descriptor.id])
        #expect(scopes.map(\.from) == ["Features", "Shared", "Core"])
        #expect(scopes.map(\.imports) == [
            ["Features"],
            ["Features"],
            ["Features"]
        ])
    }

    @Test("pack expansion resolves duplicate rule contributions deterministically")
    func packExpansionResolvesDuplicateRuleContributionsDeterministically() throws {
        let firstPack = makeForbiddenImportPack(
            id: "first-pack",
            from: "Features",
            imports: ["Alpha"]
        )
        let secondPack = makeForbiddenImportPack(
            id: "second-pack",
            from: "Features",
            imports: ["Beta"]
        )

        let registry = try RulePackRegistry(descriptors: [firstPack, secondPack])
        let expansion = try registry.expansion(for: ["first-pack", "second-pack"])
        let scopes = try ForbiddenImportSupport.decodeScopes(
            from: expansion.rules[ForbiddenImportRule.descriptor.id]?.config["forbiddenImports"],
            field: "forbiddenImports"
        )

        #expect(expansion.ruleOrder == [ForbiddenImportRule.descriptor.id])
        #expect(scopes.map(\.from) == ["Features"])
        #expect(scopes.map(\.imports) == [["Beta"]])
    }

    @Test("pack expansion preserves deterministic override ordering")
    func packExpansionPreservesDeterministicOverrideOrdering() throws {
        let registry = RulePackRegistry.default
        let first = try registry.expansion(for: ["feature-isolation", "shared-boundaries"])
        let second = try registry.expansion(for: ["feature-isolation", "shared-boundaries"])

        let firstScopes = try ForbiddenImportSupport.decodeScopes(
            from: first.rules[ForbiddenImportRule.descriptor.id]?.config["forbiddenImports"],
            field: "forbiddenImports"
        )
        let secondScopes = try ForbiddenImportSupport.decodeScopes(
            from: second.rules[ForbiddenImportRule.descriptor.id]?.config["forbiddenImports"],
            field: "forbiddenImports"
        )

        #expect(first == second)
        #expect(firstScopes.map { $0.from } == ["Features", "Shared", "Core"])
        #expect(secondScopes.map { $0.from } == ["Features", "Shared", "Core"])
    }

    @Test("explicit rules preserve preset pack rule order")
    func explicitRulesPreservePresetPackRuleOrder() throws {
        let parser = ConfigLoaderParser(
            registry: .default,
            presetRegistry: .default,
            rulePackRegistry: .default
        )

        #expect(
            parser.mergedRuleOrder(
                presetRuleOrder: ["preset-a", "preset-b"],
                explicitRuleOrder: ["preset-b", "explicit-c"],
                hasExplicitRules: true
            ) == ["preset-a", "preset-b", "explicit-c"]
        )
        #expect(
            parser.mergedRuleOrder(
                presetRuleOrder: ["preset-a", "preset-b"],
                explicitRuleOrder: ["preset-b", "explicit-c"],
                hasExplicitRules: false
            ) == ["preset-a", "preset-b"]
        )
    }
}
