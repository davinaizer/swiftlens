import Foundation

struct ForbiddenImportRule {
    static let ruleID = "ForbiddenImportRule"
    static let pack = "architecture"
    static let severity = Severity.error
    static let confidence = Confidence.high

    func evaluate(config: SwiftLensConfig, files: [ParsedSwiftFile]) -> [Violation] {
        guard config.forbiddenImportRule.enabled else {
            return []
        }

        let forbidden = Set(config.forbiddenImportRule.forbiddenImports)
        guard !forbidden.isEmpty else {
            return []
        }

        return files.flatMap { file in
            file.imports.compactMap { imported in
                guard forbidden.contains(imported.module) else {
                    return nil
                }

                return Violation(
                    rule: Self.ruleID,
                    pack: Self.pack,
                    severity: Self.severity,
                    confidence: Self.confidence,
                    file: file.url.path,
                    range: imported.range,
                    reason: "Forbidden import `\(imported.module)` found.",
                    fixPattern: "Remove the forbidden import or move the code into an allowed module."
                )
            }
        }
    }
}

