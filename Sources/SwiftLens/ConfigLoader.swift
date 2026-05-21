import Foundation

struct ConfigLoader {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
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
        let config = try buildConfig(from: root, configURL: configURL)
        let projectRootURL = try resolveProjectRoot(config.project.path, configURL: configURL, override: projectPathOverride)
        return LoadedConfiguration(configURL: configURL, projectRootURL: projectRootURL, config: config)
    }

    func validate(configPath: String?) throws {
        _ = try load(configPath: configPath, projectPathOverride: nil)
    }

    private func resolveConfigURL(configPath: String?) throws -> URL {
        let base = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        if let configPath {
            let url = URL(fileURLWithPath: configPath, relativeTo: base).standardizedFileURL
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

    private func buildConfig(from root: YAMLValue, configURL: URL) throws -> SwiftLensConfig {
        guard case .mapping(let topLevel) = root else {
            throw SwiftLensError.configuration("Config at \(configURL.path) must be a mapping.")
        }

        let allowedTopLevelKeys: Set<String> = ["project", "rules"]
        guard Set(topLevel.keys).isSubset(of: allowedTopLevelKeys) else {
            let unexpected = Set(topLevel.keys).subtracting(allowedTopLevelKeys).sorted()
            throw SwiftLensError.configuration("Unknown top-level key(s): \(unexpected.joined(separator: ", ")).")
        }

        guard let projectValue = topLevel["project"] else {
            throw SwiftLensError.configuration("Missing required `project` section.")
        }
        guard let rulesValue = topLevel["rules"] else {
            throw SwiftLensError.configuration("Missing required `rules` section.")
        }

        let project = try parseProject(projectValue)
        let forbiddenImportRule = try parseForbiddenImportRule(rulesValue)
        return SwiftLensConfig(project: project, forbiddenImportRule: forbiddenImportRule)
    }

    private func parseProject(_ value: YAMLValue) throws -> ProjectConfiguration {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("`project` must be a mapping.")
        }

        let allowedKeys: Set<String> = ["path", "include", "exclude"]
        guard Set(mapping.keys).isSubset(of: allowedKeys) else {
            let unexpected = Set(mapping.keys).subtracting(allowedKeys).sorted()
            throw SwiftLensError.configuration("Unknown `project` key(s): \(unexpected.joined(separator: ", ")).")
        }

        guard let path = stringValue(mapping["path"])?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !path.isEmpty else {
            throw SwiftLensError.configuration("`project.path` is required.")
        }

        let include = try stringArrayValue(mapping["include"], field: "project.include")
        let exclude = try stringArrayValue(mapping["exclude"], field: "project.exclude")
        return ProjectConfiguration(path: path, include: include, exclude: exclude)
    }

    private func parseForbiddenImportRule(_ value: YAMLValue) throws -> ForbiddenImportRuleConfiguration {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("`rules` must be a mapping.")
        }

        let allowedKeys: Set<String> = ["ForbiddenImportRule"]
        guard Set(mapping.keys).isSubset(of: allowedKeys) else {
            let unexpected = Set(mapping.keys).subtracting(allowedKeys).sorted()
            throw SwiftLensError.configuration("Unknown rule key(s): \(unexpected.joined(separator: ", ")).")
        }

        guard let ruleValue = mapping["ForbiddenImportRule"] else {
            throw SwiftLensError.configuration("Missing `ForbiddenImportRule` configuration.")
        }

        guard case .mapping(let ruleMapping) = ruleValue else {
            throw SwiftLensError.configuration("`rules.ForbiddenImportRule` must be a mapping.")
        }

        let allowedRuleKeys: Set<String> = ["enabled", "config"]
        guard Set(ruleMapping.keys).isSubset(of: allowedRuleKeys) else {
            let unexpected = Set(ruleMapping.keys).subtracting(allowedRuleKeys).sorted()
            throw SwiftLensError.configuration("Unknown `ForbiddenImportRule` key(s): \(unexpected.joined(separator: ", ")).")
        }

        let enabled = boolValue(ruleMapping["enabled"]) ?? true
        guard let configValue = ruleMapping["config"] else {
            throw SwiftLensError.configuration("`rules.ForbiddenImportRule.config` is required.")
        }

        guard case .mapping(let configMapping) = configValue else {
            throw SwiftLensError.configuration("`rules.ForbiddenImportRule.config` must be a mapping.")
        }

        let allowedConfigKeys: Set<String> = ["forbiddenImports"]
        guard Set(configMapping.keys).isSubset(of: allowedConfigKeys) else {
            let unexpected = Set(configMapping.keys).subtracting(allowedConfigKeys).sorted()
            throw SwiftLensError.configuration("Unknown `ForbiddenImportRule.config` key(s): \(unexpected.joined(separator: ", ")).")
        }

        let forbiddenImports = try stringArrayValue(configMapping["forbiddenImports"], field: "rules.ForbiddenImportRule.config.forbiddenImports")
        if enabled, forbiddenImports.isEmpty {
            throw SwiftLensError.configuration("`rules.ForbiddenImportRule.config.forbiddenImports` must contain at least one import.")
        }

        return ForbiddenImportRuleConfiguration(enabled: enabled, forbiddenImports: forbiddenImports)
    }

    private func stringValue(_ value: YAMLValue?) -> String? {
        guard let value else {
            return nil
        }

        switch value {
        case .string(let string):
            return string
        case .bool(let bool):
            return bool ? "true" : "false"
        case .array, .mapping:
            return nil
        }
    }

    private func boolValue(_ value: YAMLValue?) -> Bool? {
        guard let value else {
            return nil
        }

        switch value {
        case .bool(let bool):
            return bool
        case .string(let string):
            if string == "true" {
                return true
            }
            if string == "false" {
                return false
            }
            return nil
        case .array, .mapping:
            return nil
        }
    }

    private func stringArrayValue(_ value: YAMLValue?, field: String) throws -> [String] {
        guard let value else {
            return []
        }

        guard case .array(let items) = value else {
            throw SwiftLensError.configuration("`\((field))` must be a list.")
        }

        var strings: [String] = []
        for item in items {
            switch item {
            case .string(let string):
                strings.append(string)
            case .bool, .array, .mapping:
                throw SwiftLensError.configuration("`\((field))` must contain only strings.")
            }
        }
        return strings
    }
}
