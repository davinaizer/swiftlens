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
        let loadedConfiguration = try ConfigLoader(fileManager: fileManager, registry: registry)
            .load(
                configPath: options.configPath,
                projectPathOverride: options.path
            )

        let files = try discoverSwiftFiles(
            root: loadedConfiguration.projectRootURL,
            include: loadedConfiguration.config.project.include,
            exclude: loadedConfiguration.config.project.exclude,
            ignore: loadedConfiguration.config.ignore.paths
        )

        let parser = SwiftSyntaxParserService()
        let parsedFiles = try files.map { try parser.parseFile(at: $0.url, relativePath: $0.relativePath) }
        let violations = RuleEngine(registry: registry).evaluate(
            config: loadedConfiguration.config, files: parsedFiles)
        let summary = ScanSummary(filesScanned: parsedFiles.count, violations: violations.count)

        return ScanReport(
            command: "scan",
            projectPath: loadedConfiguration.projectRootURL.path,
            summary: summary,
            violations: violations
        )
    }

    func validateConfig(options: ValidationOptions) throws {
        try ConfigLoader(fileManager: fileManager, registry: registry).validate(
            configPath: options.configPath)
    }

    private struct DiscoveredSwiftFile {
        let url: URL
        let relativePath: String
    }

    private func discoverSwiftFiles(
        root: URL,
        include: [String],
        exclude: [String],
        ignore: [String]
    ) throws -> [DiscoveredSwiftFile] {
        guard fileManager.fileExists(atPath: root.path) else {
            throw SwiftLensError.configuration("Project path not found at \(root.path).")
        }

        let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var results: [DiscoveredSwiftFile] = []
        while let url = enumerator?.nextObject() as? URL {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            let relativePath = canonicalRelativePath(for: url, root: root)
            if resourceValues.isDirectory == true {
                if shouldSkipDirectory(url.lastPathComponent)
                    || ignore.contains(where: { pathMatchesPrefixBoundary(relativePath, prefix: $0) }) {
                    enumerator?.skipDescendants()
                }
                continue
            }

            guard url.pathExtension == "swift" else {
                continue
            }

            if ignore.contains(where: { pathMatchesPrefixBoundary(relativePath, prefix: $0) }) {
                continue
            }
            if !include.isEmpty,
                !include.contains(where: { pathMatchesPrefixBoundary(relativePath, prefix: $0) }) {
                continue
            }
            if exclude.contains(where: { pathMatchesPrefixBoundary(relativePath, prefix: $0) }) {
                continue
            }

            results.append(DiscoveredSwiftFile(url: url.standardizedFileURL, relativePath: relativePath))
        }

        return results.sorted { $0.relativePath < $1.relativePath }
    }

    private func shouldSkipDirectory(_ name: String) -> Bool {
        [".build", ".git", ".swiftpm", "DerivedData", "SourcePackages"].contains(name)
    }

}
