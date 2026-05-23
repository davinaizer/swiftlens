import Foundation

struct ForbiddenImportRule {
    static let descriptor = RuleDescriptor(
        id: "architecture.forbidden-import",
        pack: "architecture",
        defaultSeverity: .error,
        defaultConfidence: .high,
        defaultEnabled: true,
        configKeys: ["forbiddenImports"],
        explanation: RuleExplanation(
            purpose: [
                "Enforce explicit import boundaries declared by path-scoped governance rules."
            ],
            detectionMechanism: [
                "Scan declared `import` statements only.",
                "Normalize imported module names into path-like segments.",
                "Match the file path against configured `from` scopes using prefix-boundary checks.",
                "Compare the imported module against each configured forbidden import prefix.",
                "Do not resolve symbols, build targets, transitive dependencies, or runtime behavior."
            ],
            configShape: [
                "rules:",
                "  - architecture.forbidden-import",
                "architecture:",
                "  forbiddenImports:",
                "    -",
                "      from: Features/",
                "      imports:",
                "        - Infrastructure"
            ],
            deterministicBehavior: [
                "Matching is syntax-first and path-bound.",
                "The same input config and source tree produce the same result on every run.",
                "No semantic analysis or graph construction is performed."
            ],
            limitations: [
                "Only declared imports are inspected.",
                "The rule does not infer ownership or resolve module graphs.",
                "Path and import matching are intentionally conservative."
            ],
            exampleViolation: [
                "File: Features/Auth/AuthFeature.swift",
                "import Infrastructure",
                "This violates a scope that forbids `Infrastructure` imports from `Features/`."
            ],
            exampleConfig: [
                "rules:",
                "  - architecture.forbidden-import",
                "architecture:",
                "  forbiddenImports:",
                "    -",
                "      from: Features/",
                "      imports:",
                "        - Infrastructure"
            ]
        ),
        evaluate: { context in
            let forbiddenImports = Self.forbiddenImports(from: context.settings.config)
            guard !forbiddenImports.isEmpty else {
                return []
            }

            var violations: [Violation] = []
            for file in context.files {
                for scope in forbiddenImports where pathMatchesPrefixBoundary(file.relativePath, prefix: scope.from) {
                    let scopeLabel = scope.from.isEmpty ? "<root>" : scope.from
                    for imported in file.imports where scope.imports.contains(where: {
                        importMatchesScope(imported.module, scope: $0)
                    }) {
                        violations.append(
                            Violation(
                                rule: context.descriptor.id,
                                pack: context.descriptor.pack,
                                severity: context.settings.severity,
                                confidence: context.settings.confidence,
                                file: file.url.path,
                                range: imported.range,
                                reason: "Forbidden import `\(imported.module)` found in `\(scopeLabel)`.",
                                fixPattern:
                                    "Remove the forbidden import or move the code into an allowed module."
                            )
                        )
                    }
                }
            }

            return violations
        }
    )

    private static func forbiddenImports(from config: [String: YAMLValue]) -> [ForbiddenImportScope] {
        do {
            return try ForbiddenImportSupport.scopes(from: config)
        } catch {
            return []
        }
    }

    private static func importMatchesScope(_ module: String, scope: String) -> Bool {
        pathMatchesPrefixBoundary(
            module.replacingOccurrences(of: ".", with: "/"),
            prefix: scope
        )
    }
}
