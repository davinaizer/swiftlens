import Foundation

struct PresetExpansion: Equatable, Sendable {
    let rules: [String: RuleConfiguration]
    let ruleOrder: [String]
}

struct PresetDescriptor: Equatable, Sendable {
    let id: String
    let expansion: PresetExpansion
}

struct PresetRegistry: Sendable {
    let descriptors: [PresetDescriptor]

    static let `default` = PresetRegistry(descriptors: [
        PresetDescriptor(
            id: "app-layers",
            expansion: PresetExpansion(
                rules: [
                    ForbiddenImportRule.descriptor.id: PresetRegistry.forbiddenImportRuleConfiguration(
                        from: "App/",
                        imports: ["UIKit"]
                    )
                ],
                ruleOrder: [ForbiddenImportRule.descriptor.id]
            )
        ),
        PresetDescriptor(
            id: "feature-modules",
            expansion: PresetExpansion(
                rules: [
                    ForbiddenImportRule.descriptor.id: PresetRegistry.forbiddenImportRuleConfiguration(
                        from: "Features/",
                        imports: ["UIKit"]
                    )
                ],
                ruleOrder: [ForbiddenImportRule.descriptor.id]
            )
        ),
        PresetDescriptor(
            id: "tca-features",
            expansion: PresetExpansion(
                rules: [
                    ForbiddenImportRule.descriptor.id: PresetRegistry.forbiddenImportRuleConfiguration(
                        from: "Features/",
                        imports: ["UIKit"]
                    )
                ],
                ruleOrder: [ForbiddenImportRule.descriptor.id]
            )
        )
    ])

    func descriptor(for presetID: String) -> PresetDescriptor? {
        descriptors.first { $0.id == presetID }
    }

    func expansion(for presetID: String) -> PresetExpansion? {
        descriptor(for: presetID)?.expansion
    }

    var presetIDs: [String] {
        descriptors.map(\.id)
    }

    private static func forbiddenImportRuleConfiguration(
        from: String,
        imports: [String]
    ) -> RuleConfiguration {
        RuleConfiguration(
            enabled: true,
            severity: nil,
            config: [
                "forbiddenImports": .array([
                    .mapping([
                        "from": .string(from),
                        "imports": .array(imports.map(YAMLValue.string))
                    ])
                ])
            ]
        )
    }
}
