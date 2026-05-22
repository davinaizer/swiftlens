import Foundation

private struct YAMLLine {
    let number: Int
    let indent: Int
    let content: String
}

indirect enum YAMLValue: Equatable, Sendable {
    case string(String)
    case bool(Bool)
    case array([YAMLValue])
    case mapping([String: YAMLValue])
}

struct YAMLParser {
    func parse(_ source: String) throws -> YAMLValue {
        let lines = try tokenize(source)
        var index = 0
        return try parseMapping(lines: lines, index: &index, expectedIndent: 0)
    }

    private func tokenize(_ source: String) throws -> [YAMLLine] {
        var lines: [YAMLLine] = []
        for (offset, rawLine) in source.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated() {
            let lineNumber = offset + 1
            let stripped = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if stripped.isEmpty || stripped.hasPrefix("#") {
                continue
            }

            let indent = rawLine.prefix { $0 == " " }.count
            if rawLine.contains("\t") {
                throw SwiftLensError.configuration(
                    "Tabs are not supported in YAML at line \(lineNumber).")
            }

            let commentFree: Substring
            if let hashIndex = rawLine.firstIndex(of: "#") {
                commentFree = rawLine[..<hashIndex]
            } else {
                commentFree = rawLine[...]
            }

            let content = commentFree.trimmingCharacters(in: .whitespaces)
            if content.isEmpty {
                continue
            }

            lines.append(YAMLLine(number: lineNumber, indent: indent, content: content))
        }
        return lines
    }

    private func parseMapping(lines: [YAMLLine], index: inout Int, expectedIndent: Int) throws
        -> YAMLValue {
        var values: [String: YAMLValue] = [:]

        while index < lines.count {
            let line = lines[index]
            guard line.indent == expectedIndent else {
                if line.indent < expectedIndent {
                    break
                }
                throw SwiftLensError.configuration("Invalid indentation at line \(line.number).")
            }

            guard !line.content.hasPrefix("-") else {
                throw SwiftLensError.configuration("Unexpected list item at line \(line.number).")
            }

            guard let separatorIndex = line.content.firstIndex(of: ":") else {
                throw SwiftLensError.configuration("Missing ':' at line \(line.number).")
            }

            let key = line.content[..<separatorIndex].trimmingCharacters(in: .whitespaces)
            let remainder = line.content[line.content.index(after: separatorIndex)...]
                .trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else {
                throw SwiftLensError.configuration("Empty key at line \(line.number).")
            }

            index += 1

            if !remainder.isEmpty {
                values[key] = parseScalar(remainder)
                continue
            }

            guard index < lines.count else {
                values[key] = .mapping([:])
                continue
            }

            let nextLine = lines[index]
            guard nextLine.indent > expectedIndent else {
                values[key] = .mapping([:])
                continue
            }

            if nextLine.content.hasPrefix("-") {
                values[key] = try parseArray(
                    lines: lines, index: &index, expectedIndent: nextLine.indent)
            } else {
                values[key] = try parseMapping(
                    lines: lines, index: &index, expectedIndent: nextLine.indent)
            }
        }

        return .mapping(values)
    }

    private func parseArray(lines: [YAMLLine], index: inout Int, expectedIndent: Int) throws
        -> YAMLValue {
        var values: [YAMLValue] = []

        while index < lines.count {
            let line = lines[index]
            guard line.indent == expectedIndent else {
                if line.indent < expectedIndent {
                    break
                }
                throw SwiftLensError.configuration(
                    "Invalid list indentation at line \(line.number).")
            }

            guard line.content.hasPrefix("-") else {
                break
            }

            let remainder = line.content.dropFirst().trimmingCharacters(in: .whitespaces)
            index += 1

            if !remainder.isEmpty {
                values.append(parseScalar(String(remainder)))
                continue
            }

            guard index < lines.count else {
                values.append(.mapping([:]))
                continue
            }

            let nextLine = lines[index]
            guard nextLine.indent > expectedIndent else {
                values.append(.mapping([:]))
                continue
            }

            if nextLine.content.hasPrefix("-") {
                values.append(
                    try parseArray(lines: lines, index: &index, expectedIndent: nextLine.indent))
            } else {
                values.append(
                    try parseMapping(lines: lines, index: &index, expectedIndent: nextLine.indent))
            }
        }

        return .array(values)
    }

    private func parseScalar(_ text: String) -> YAMLValue {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let array = parseInlineArray(trimmed) {
            return .array(array)
        }
        if trimmed == "true" {
            return .bool(true)
        }
        if trimmed == "false" {
            return .bool(false)
        }
        if let quoted = quotedStringValue(trimmed) {
            return .string(quoted)
        }
        return .string(trimmed)
    }

    private func parseInlineArray(_ text: String) -> [YAMLValue]? {
        guard text.hasPrefix("[") && text.hasSuffix("]") else {
            return nil
        }

        let body = text.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else {
            return []
        }

        return body.split(separator: ",").map { item in
            parseInlineScalar(String(item.trimmingCharacters(in: .whitespaces)))
        }
    }

    private func parseInlineScalar(_ text: String) -> YAMLValue {
        if text == "true" {
            return .bool(true)
        }
        if text == "false" {
            return .bool(false)
        }
        if let quoted = quotedStringValue(text) {
            return .string(quoted)
        }
        return .string(text)
    }

    private func quotedStringValue(_ text: String) -> String? {
        if text.hasPrefix("\""), text.hasSuffix("\""), text.count >= 2 {
            return String(text.dropFirst().dropLast())
        }
        if text.hasPrefix("'"), text.hasSuffix("'"), text.count >= 2 {
            return String(text.dropFirst().dropLast())
        }
        return nil
    }
}
