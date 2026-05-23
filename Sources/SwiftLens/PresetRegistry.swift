import Foundation

struct PresetExpansion: Equatable, Sendable {
    let rules: [String: RuleConfiguration]
    let ruleOrder: [String]
}

struct PresetBoundaryBlueprint: Equatable, Sendable {
    let path: String
    let allows: [String]
    let notes: [String]
}

struct PresetExplanation: Equatable, Sendable {
    let description: [String]
    let intendedStructure: [String]
    let governanceDefaults: [String]
    let exampleLayout: [String]
    let notes: [String]
}

struct PresetDescriptor: Equatable, Sendable {
    let id: String
    let expansion: PresetExpansion
    let boundaryBlueprints: [PresetBoundaryBlueprint]
    let boundaryScopeOrder: [String]
    let explanation: PresetExplanation
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
            ),
            boundaryBlueprints: [
                PresetBoundaryBlueprint(
                    path: "App",
                    allows: [
                        "UI/*",
                        "Domain/*",
                        "Data/*",
                        "Shared/*"
                    ],
                    notes: []
                )
            ],
            boundaryScopeOrder: [
                "App",
                "UI",
                "Domain",
                "Shared"
            ],
            explanation: PresetExplanation(
                description: [
                    "Layered app governance for single-target or lightly modular projects."
                ],
                intendedStructure: [
                    "Use this preset when a project is organized into broad app layers such as App, UI, Domain, Data, "
                        + "and Shared.",
                    "Treat App as the composition root and keep the remaining layers explicit."
                ],
                governanceDefaults: [
                    "Domain cannot import SwiftUI, UIKit, or AppKit.",
                    "UI cannot import Data.",
                    "The preset stays conservative and does not attempt to infer additional layers."
                ],
                exampleLayout: [
                    "App/",
                    "UI/",
                    "Domain/",
                    "Data/",
                    "Shared/"
                ],
                notes: [
                    "This preset is path and import based only.",
                    "It does not inspect ownership graphs or runtime wiring."
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
            ),
            boundaryBlueprints: [
                PresetBoundaryBlueprint(
                    path: "App",
                    allows: [
                        "Features/*",
                        "Shared/*",
                        "Core/*"
                    ],
                    notes: []
                )
            ],
            boundaryScopeOrder: [
                "App",
                "Features",
                "Shared",
                "Core"
            ],
            explanation: PresetExplanation(
                description: [
                    "Feature-oriented governance for modular SwiftUI applications."
                ],
                intendedStructure: [
                    "Use this preset when application behavior is split into compositional features plus "
                        + "shared and core support code.",
                    "App is the composition root and may import feature modules.",
                    "Sibling feature modules should stay isolated from one another."
                ],
                governanceDefaults: [
                    "Features may not import other Features.* modules.",
                    "Shared may not import Features.*.",
                    "Core may not import Features.*.",
                    "The preset allows App to compose feature modules explicitly."
                ],
                exampleLayout: [
                    "App/",
                    "Features/",
                    "  Auth/",
                    "  Profile/",
                    "Shared/",
                    "Core/"
                ],
                notes: [
                    "The preset encodes explicit forbidden-import scopes only.",
                    "It does not infer feature ownership or module graphs."
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
            ),
            boundaryBlueprints: [
                PresetBoundaryBlueprint(
                    path: "App",
                    allows: [
                        "Features/*",
                        "Shared/*",
                        "Dependencies/*"
                    ],
                    notes: []
                )
            ],
            boundaryScopeOrder: [
                "App",
                "Features",
                "Shared",
                "Dependencies"
            ],
            explanation: PresetExplanation(
                description: [
                    "Governance defaults for reducer-first TCA-style feature architectures."
                ],
                intendedStructure: [
                    "Use this preset when feature state, dependencies, and views are kept in explicit TCA-style "
                        + "boundaries.",
                    "Features should remain isolated and dependency clients should stay in approved dependency "
                        + "zones."
                ],
                governanceDefaults: [
                    "Dependencies may not import Features.*.",
                    "Dependencies may not import SwiftUI, UIKit, or AppKit.",
                    "Features may not import other Features.* modules.",
                    "Features may not import SwiftUI, UIKit, or AppKit directly.",
                    "Shared may not import Features.*."
                ],
                exampleLayout: [
                    "App/",
                    "Features/",
                    "  Auth/",
                    "  Profile/",
                    "Shared/",
                    "Dependencies/"
                ],
                notes: [
                    "This preset remains syntax-first and deterministic.",
                    "It does not model reducer semantics or dependency injection behavior."
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
