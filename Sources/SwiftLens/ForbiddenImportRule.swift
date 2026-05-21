import Foundation

struct ForbiddenImportRule {
    static let descriptor = RuleDescriptor(
        id: "ForbiddenImportRule",
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

            let forbidden = Set(forbiddenImports)
            return context.files.flatMap { file in
                file.imports.compactMap { imported in
                    guard forbidden.contains(imported.module) else {
                        return nil
                    }

                    return Violation(
                        rule: context.descriptor.id,
                        pack: context.descriptor.pack,
                        severity: context.settings.severity,
                        confidence: context.settings.confidence,
                        file: file.url.path,
                        range: imported.range,
                        reason: "Forbidden import `\(imported.module)` found.",
                        fixPattern: "Remove the forbidden import or move the code into an allowed module."
                    )
                }
            }
        }
    )

    private static func forbiddenImports(from config: [String: YAMLValue]) -> [String] {
        guard let value = config["forbiddenImports"] else {
            return []
        }

        guard case .array(let items) = value else {
            return []
        }

        return items.compactMap { item in
            guard case .string(let string) = item else {
                return nil
            }
            return string
        }
    }
}
