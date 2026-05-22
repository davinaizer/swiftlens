import Foundation

struct ForbiddenImportRule {
    static let descriptor = RuleDescriptor(
        id: "architecture.forbidden-import",
        pack: "architecture",
        defaultSeverity: .error,
        defaultConfidence: .high,
        defaultEnabled: true,
        configKeys: ["forbiddenImports"],
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

    private struct ForbiddenImportScope {
        let from: String
        let imports: [String]
    }

    private static func forbiddenImports(from config: [String: YAMLValue]) -> [ForbiddenImportScope] {
        guard let value = config["forbiddenImports"] else {
            return []
        }

        guard case .array(let items) = value else {
            return []
        }

        var scopes: [ForbiddenImportScope] = []
        for item in items {
            guard case .mapping(let mapping) = item else {
                return []
            }

            guard let from = mapping["from"]?.stringValue else {
                return []
            }

            let scope = normalizeRelativePath(from)
            let imports: [String]
            do {
                imports = try ConfigValueDecoder().stringArrayValue(
                    mapping["imports"],
                    field: "architecture.forbiddenImports.imports"
                )
            } catch {
                return []
            }
            scopes.append(ForbiddenImportScope(from: scope, imports: imports))
        }

        return scopes
    }

    private static func importMatchesScope(_ module: String, scope: String) -> Bool {
        pathMatchesPrefixBoundary(
            module.replacingOccurrences(of: ".", with: "/"),
            prefix: scope
        )
    }
}

private extension YAMLValue {
    var stringValue: String? {
        guard case .string(let string) = self else {
            return nil
        }
        return string
    }
}
