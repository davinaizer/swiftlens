import Foundation

struct FoundationImportRule {
    static let descriptor = RuleDescriptor(
        id: "FoundationImportRule",
        pack: "architecture",
        defaultSeverity: .warning,
        defaultConfidence: .high,
        defaultEnabled: false,
        configKeys: [],
        evaluate: { context in
            var violations: [Violation] = []
            for file in context.files {
                for imported in file.imports where imported.module == "Foundation" {
                    violations.append(
                        Violation(
                            rule: context.descriptor.id,
                            pack: context.descriptor.pack,
                            severity: context.settings.severity,
                            confidence: context.settings.confidence,
                            file: file.url.path,
                            range: imported.range,
                            reason: "Foundation import found.",
                            fixPattern: "Remove the Foundation import or move the code into an allowed module."
                        )
                    )
                }
            }
            return violations
        }
    )
}
