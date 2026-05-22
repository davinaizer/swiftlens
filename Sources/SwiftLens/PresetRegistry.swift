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
            expansion: PresetRegistry.presetExpansion(
                forbiddenImports: [
                    ("Domain", ["SwiftUI", "UIKit", "AppKit"]),
                    ("UI", ["Data"])
                ]
            )
        ),
        PresetDescriptor(
            id: "feature-modules",
            expansion: PresetRegistry.presetExpansion(
                forbiddenImports: [
                    ("Core", ["Features"]),
                    ("Features", ["Features"]),
                    ("Shared", ["Features"])
                ]
            )
        ),
        PresetDescriptor(
            id: "tca-features",
            expansion: PresetRegistry.presetExpansion(
                forbiddenImports: [
                    ("Dependencies", ["Features"]),
                    ("Dependencies", ["SwiftUI", "UIKit", "AppKit"]),
                    ("Features", ["Features"]),
                    ("Features", ["SwiftUI", "UIKit", "AppKit"]),
                    ("Shared", ["Features"])
                ]
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

    private static func presetExpansion(
        forbiddenImports: [(from: String, imports: [String])]
    ) -> PresetExpansion {
        PresetExpansion(
            rules: [
                ForbiddenImportRule.descriptor.id: forbiddenImportRuleConfiguration(
                    forbiddenImports: forbiddenImports
                )
            ],
            ruleOrder: [ForbiddenImportRule.descriptor.id]
        )
    }

    private static func forbiddenImportRuleConfiguration(
        forbiddenImports: [(from: String, imports: [String])]
    ) -> RuleConfiguration {
        RuleConfiguration(
            enabled: true,
            severity: nil,
            config: [
                "forbiddenImports": .array(
                    forbiddenImports.map { scope in
                        .mapping([
                        "from": .string(normalizeRelativePath(scope.from)),
                        "imports": .array(scope.imports.map(YAMLValue.string))
                        ])
                    }
                )
            ]
        )
    }
}
