import Foundation

struct ScanEngine {
    private let fileManager: FileManager
    private let registry: RuleRegistry

    init(fileManager: FileManager = .default) {
        self.init(fileManager: fileManager, registry: .default)
    }

    init(fileManager: FileManager = .default, registry: RuleRegistry) {
        self.fileManager = fileManager
        self.registry = registry
    }

    func scan(options: ScanOptions) throws -> ScanReport {
        let loadedConfiguration = try ConfigLoader(fileManager: fileManager, registry: registry).load(
            configPath: options.configPath,
            projectPathOverride: options.path
        )

        let files = try discoverSwiftFiles(
            root: loadedConfiguration.projectRootURL,
            include: loadedConfiguration.config.project.include,
            exclude: loadedConfiguration.config.project.exclude
        )

        let parser = SwiftSyntaxParserService()
        let parsedFiles = try files.map { try parser.parseFile(at: $0) }
        let violations = RuleEngine(registry: registry).evaluate(config: loadedConfiguration.config, files: parsedFiles)
        let summary = ScanSummary(filesScanned: parsedFiles.count, violations: violations.count)

        return ScanReport(
            command: "scan",
            projectPath: loadedConfiguration.projectRootURL.path,
            summary: summary,
            violations: violations
        )
    }

    func validateConfig(options: ValidationOptions) throws {
        try ConfigLoader(fileManager: fileManager, registry: registry).validate(configPath: options.configPath)
    }

    private func discoverSwiftFiles(root: URL, include: [String], exclude: [String]) throws -> [URL] {
        guard fileManager.fileExists(atPath: root.path) else {
            throw SwiftLensError.configuration("Project path not found at \(root.path).")
        }

        let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var results: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                if shouldSkipDirectory(url.lastPathComponent) {
                    enumerator?.skipDescendants()
                }
                continue
            }

            guard url.pathExtension == "swift" else {
                continue
            }

            let relativePath = relativePathString(for: url, root: root)
            if !include.isEmpty, !include.contains(where: { matchesScope(relativePath, pattern: $0) }) {
                continue
            }
            if exclude.contains(where: { matchesScope(relativePath, pattern: $0) }) {
                continue
            }

            results.append(url.standardizedFileURL)
        }

        return results.sorted { $0.path < $1.path }
    }

    private func shouldSkipDirectory(_ name: String) -> Bool {
        [".build", ".git", ".swiftpm", "DerivedData", "SourcePackages"].contains(name)
    }

    private func relativePathString(for fileURL: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }

        let suffix = filePath.dropFirst(rootPath.count)
        return String(suffix.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    private func matchesScope(_ relativePath: String, pattern: String) -> Bool {
        let normalized = pattern.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !normalized.isEmpty else {
            return false
        }
        return relativePath == normalized || relativePath.hasPrefix(normalized + "/")
    }
}
