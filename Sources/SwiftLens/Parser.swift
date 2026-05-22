import Foundation
import SwiftParser
import SwiftSyntax

struct SwiftSyntaxParserService {
    func parseFile(at url: URL) throws -> ParsedSwiftFile {
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw SwiftLensError.internalFailure("Unable to read Swift source at \(url.path).")
        }

        let tree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: url.path, tree: tree)
        var imports: [ParsedImport] = []

        for item in tree.statements {
            guard let importDecl = item.item.as(ImportDeclSyntax.self) else {
                continue
            }

            let module = importedModuleName(from: importDecl)
            let start = converter.location(for: importDecl.positionAfterSkippingLeadingTrivia)
            let end = converter.location(for: importDecl.endPositionBeforeTrailingTrivia)
            let range = SourceRange(
                start: SourceLocation(line: start.line, column: start.column),
                end: SourceLocation(line: end.line, column: end.column)
            )
            imports.append(ParsedImport(module: module, range: range))
        }

        return ParsedSwiftFile(url: url, imports: imports)
    }

    private func importedModuleName(from importDecl: ImportDeclSyntax) -> String {
        let path = importDecl.path.map { $0.name.text }.joined(separator: ".")
        if !path.isEmpty {
            return path
        }

        let trimmed = importDecl.trimmedDescription
        let cleaned =
            trimmed
            .replacingOccurrences(of: "@_exported ", with: "")
            .replacingOccurrences(of: "import ", with: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
