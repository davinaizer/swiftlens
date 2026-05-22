import Foundation

struct ConfigLoader {
    private let fileManager: FileManager
    private let registry: RuleRegistry
    private let presetRegistry: PresetRegistry

    init(
        fileManager: FileManager = .default,
        registry: RuleRegistry = .default,
        presetRegistry: PresetRegistry = .default
    ) {
        self.fileManager = fileManager
        self.registry = registry
        self.presetRegistry = presetRegistry
    }

    func load(configPath: String?, projectPathOverride: String?) throws -> LoadedConfiguration {
        let configURL = try resolveConfigURL(configPath: configPath)
        let contents: String
        do {
            contents = try String(contentsOf: configURL, encoding: .utf8)
        } catch {
            throw SwiftLensError.configuration("Unable to read config at \(configURL.path).")
        }

        let root = try YAMLParser().parse(contents)
        let config = try ConfigLoaderParser(registry: registry, presetRegistry: presetRegistry)
            .buildConfig(from: root, configURL: configURL)
        let projectRootURL = try resolveProjectRoot(
            config.project.path, configURL: configURL, override: projectPathOverride)
        return LoadedConfiguration(
            configURL: configURL, projectRootURL: projectRootURL, config: config)
    }

    func validate(configPath: String?) throws {
        _ = try load(configPath: configPath, projectPathOverride: nil)
    }

    private func resolveConfigURL(configPath: String?) throws -> URL {
        let base = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        if let configPath {
            let url: URL
            if configPath.hasPrefix("/") {
                url = URL(fileURLWithPath: configPath).standardizedFileURL
            } else {
                url = URL(fileURLWithPath: configPath, relativeTo: base).standardizedFileURL
            }
            guard fileManager.fileExists(atPath: url.path) else {
                throw SwiftLensError.configuration("Config file not found at \(url.path).")
            }
            return url
        }

        let defaultURL = base.appendingPathComponent(".swiftlens.yml").standardizedFileURL
        guard fileManager.fileExists(atPath: defaultURL.path) else {
            throw SwiftLensError.configuration("Config file not found at \(defaultURL.path).")
        }
        return defaultURL
    }

    private func resolveProjectRoot(_ path: String, configURL: URL, override: String?) throws -> URL {
        let base = override ?? path
        let rootBaseURL: URL
        if override == nil {
            rootBaseURL = configURL.deletingLastPathComponent()
        } else {
            rootBaseURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        }

        let baseURL = URL(fileURLWithPath: base, relativeTo: rootBaseURL).standardizedFileURL
        guard fileManager.fileExists(atPath: baseURL.path) else {
            throw SwiftLensError.configuration("Project path not found at \(baseURL.path).")
        }
        return baseURL
    }
}
