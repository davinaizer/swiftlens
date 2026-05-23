import Foundation

enum RulePackRegistryBuiltins {
    static let descriptors: [RulePackDescriptor] = [
        featureIsolationPack,
        sharedBoundariesPack,
        appShellPack,
        domainUISeparationPack,
        dependencyDirectionPack
    ]

    private static func forbiddenImportRuleConfig(
        _ scopes: [ForbiddenImportScope]
    ) -> RuleConfiguration {
        RuleConfiguration(
            enabled: true,
            severity: nil,
            config: ForbiddenImportSupport.canonicalConfig(from: scopes)
        )
    }

    private static let featureIsolationPack = RulePackDescriptor(
        id: "feature-isolation",
        expansion: RulePackExpansion(
            rules: [
                ForbiddenImportRule.descriptor.id: forbiddenImportRuleConfig(
                    [ForbiddenImportScope(from: "Features", imports: ["Features"])]
                )
            ],
            ruleOrder: [ForbiddenImportRule.descriptor.id]
        ),
        explanation: RulePackExplanation(
            description: [
                "Restricts sibling feature imports for modular feature-oriented apps."
            ],
            enabledRules: [ForbiddenImportRule.descriptor.id],
            generatedBoundaries: [
                RulePackBoundaryBlueprint(
                    path: "Features",
                    allows: [],
                    restrictedImports: ["Features/*"],
                    notes: [
                        "Sibling feature imports are restricted."
                    ]
                )
            ],
            intendedUsage: [
                "Use this pack when features should remain isolated from other features."
            ],
            notes: [
                "This pack is syntax-first and path-bound."
            ],
            limitations: [
                "It does not infer ownership or transitive module graphs."
            ]
        )
    )

    private static let sharedBoundariesPack = RulePackDescriptor(
        id: "shared-boundaries",
        expansion: RulePackExpansion(
            rules: [
                ForbiddenImportRule.descriptor.id: forbiddenImportRuleConfig([
                    ForbiddenImportScope(from: "Shared", imports: ["Features"]),
                    ForbiddenImportScope(from: "Core", imports: ["Features"])
                ])
            ],
            ruleOrder: [ForbiddenImportRule.descriptor.id]
        ),
        explanation: RulePackExplanation(
            description: [
                "Prevents shared support code from depending on features."
            ],
            enabledRules: [ForbiddenImportRule.descriptor.id],
            generatedBoundaries: [
                RulePackBoundaryBlueprint(
                    path: "Shared",
                    allows: [],
                    restrictedImports: ["Features/*"],
                    notes: [
                        "Shared code should stay feature-agnostic."
                    ]
                ),
                RulePackBoundaryBlueprint(
                    path: "Core",
                    allows: [],
                    restrictedImports: ["Features/*"],
                    notes: [
                        "Core code should stay feature-agnostic."
                    ]
                )
            ],
            intendedUsage: [
                "Use this pack when shared or core modules must not import features."
            ],
            notes: [
                "The pack is deterministic and local-only."
            ],
            limitations: [
                "It only checks declared imports."
            ]
        )
    )

    private static let appShellPack = RulePackDescriptor(
        id: "app-shell",
        expansion: RulePackExpansion(
            rules: [:],
            ruleOrder: []
        ),
        explanation: RulePackExplanation(
            description: [
                "Defines the app composition-root boundary."
            ],
            enabledRules: [],
            generatedBoundaries: [
                RulePackBoundaryBlueprint(
                    path: "App",
                    allows: [],
                    restrictedImports: [],
                    notes: [
                        "Composition-root allow lists are preset-specific."
                    ]
                )
            ],
            intendedUsage: [
                "Use this pack when an app target acts as the composition root."
            ],
            notes: [
                "This pack carries boundary metadata only."
            ],
            limitations: [
                "Allowed imports are intentionally left to the preset layer."
            ]
        )
    )

    private static let domainUISeparationPack = RulePackDescriptor(
        id: "domain-ui-separation",
        expansion: RulePackExpansion(
            rules: [
                ForbiddenImportRule.descriptor.id: forbiddenImportRuleConfig([
                    ForbiddenImportScope(
                        from: "Domain",
                        imports: ["SwiftUI", "UIKit", "AppKit"]
                    ),
                    ForbiddenImportScope(from: "UI", imports: ["Data"])
                ])
            ],
            ruleOrder: [ForbiddenImportRule.descriptor.id]
        ),
        explanation: RulePackExplanation(
            description: [
                "Separates UI code from domain and data-layer dependencies."
            ],
            enabledRules: [ForbiddenImportRule.descriptor.id],
            generatedBoundaries: [
                RulePackBoundaryBlueprint(
                    path: "Domain",
                    allows: [],
                    restrictedImports: ["SwiftUI", "UIKit", "AppKit"],
                    notes: [
                        "Domain should not import UI frameworks."
                    ]
                ),
                RulePackBoundaryBlueprint(
                    path: "UI",
                    allows: [],
                    restrictedImports: ["Data"],
                    notes: [
                        "UI should not import data-layer modules."
                    ]
                )
            ],
            intendedUsage: [
                "Use this pack for layered apps with explicit domain and UI separation."
            ],
            notes: [
                "The pack stays syntax-first and conservative."
            ],
            limitations: [
                "It does not infer additional layer boundaries."
            ]
        )
    )

    private static let dependencyDirectionPack = RulePackDescriptor(
        id: "dependency-direction",
        expansion: RulePackExpansion(
            rules: [
                ForbiddenImportRule.descriptor.id: forbiddenImportRuleConfig([
                    ForbiddenImportScope(
                        from: "Dependencies",
                        imports: ["Features", "SwiftUI", "UIKit", "AppKit"]
                    ),
                    ForbiddenImportScope(
                        from: "Features",
                        imports: ["Features", "SwiftUI", "UIKit", "AppKit"]
                    ),
                    ForbiddenImportScope(from: "Shared", imports: ["Features"])
                ])
            ],
            ruleOrder: [ForbiddenImportRule.descriptor.id]
        ),
        explanation: RulePackExplanation(
            description: [
                "Constrains dependency clients and feature code to approved import directions."
            ],
            enabledRules: [ForbiddenImportRule.descriptor.id],
            generatedBoundaries: [
                RulePackBoundaryBlueprint(
                    path: "Dependencies",
                    allows: [],
                    restrictedImports: ["Features/*", "SwiftUI", "UIKit", "AppKit"],
                    notes: [
                        "Dependency clients should not import feature or UI frameworks."
                    ]
                ),
                RulePackBoundaryBlueprint(
                    path: "Features",
                    allows: [],
                    restrictedImports: ["Features/*", "SwiftUI", "UIKit", "AppKit"],
                    notes: [
                        "Feature code should remain isolated."
                    ]
                ),
                RulePackBoundaryBlueprint(
                    path: "Shared",
                    allows: [],
                    restrictedImports: ["Features/*"],
                    notes: [
                        "Shared code should not import features."
                    ]
                )
            ],
            intendedUsage: [
                "Use this pack for reducer-first or dependency-client-heavy architectures."
            ],
            notes: [
                "It intentionally avoids semantic dependency inference."
            ],
            limitations: [
                "Only declared imports are evaluated."
            ]
        )
    )
}
