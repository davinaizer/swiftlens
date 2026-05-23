import Foundation

func normalizeRelativePath(_ path: String) -> String {
    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed != "." else {
        return ""
    }

    let components = trimmed.replacingOccurrences(of: "\\", with: "/")
        .split(separator: "/", omittingEmptySubsequences: true)
        .map(String.init)
    var normalized: [String] = []

    for component in components {
        switch component {
        case ".":
            continue
        case "..":
            if !normalized.isEmpty, normalized.last != ".." {
                normalized.removeLast()
            } else {
                normalized.append(component)
            }
        default:
            normalized.append(component)
        }
    }

    guard !normalized.isEmpty else {
        return ""
    }

    return normalized.joined(separator: "/")
}

func pathMatchesPrefixBoundary(_ path: String, prefix: String) -> Bool {
    let normalizedPath = normalizeRelativePath(path)
    let normalizedPrefix = normalizeRelativePath(prefix)

    guard !normalizedPrefix.isEmpty else {
        return true
    }

    return normalizedPath == normalizedPrefix || normalizedPath.hasPrefix(normalizedPrefix + "/")
}

func canonicalRelativePath(for fileURL: URL, root: URL) -> String {
    let rootPath = root.standardizedFileURL.path
    let filePath = fileURL.standardizedFileURL.path

    guard filePath != rootPath else {
        return ""
    }

    guard filePath.hasPrefix(rootPath + "/") else {
        return normalizeRelativePath(filePath)
    }

    return normalizeRelativePath(String(filePath.dropFirst(rootPath.count + 1)))
}
