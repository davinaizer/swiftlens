import Foundation

struct ConfigLoader {
    private let fileManager: FileManager
    private let registry: RuleRegistry

    init(fileManager: FileManager = .default, registry: RuleRegistry = .default) {
        self.fileManager = fileManager
        self.registry = registry
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

    private func resolveProjectRoot(_ path: String, configURL: URL, override: String?) throws -> URL
    {
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

        let allowedTopLevelKeys: Set<String> = ["project", "packs", "rules"]
        guard Set(topLevel.keys).isSubset(of: allowedTopLevelKeys) else {
            let unexpected = Set(topLevel.keys).subtracting(allowedTopLevelKeys).sorted()
            throw SwiftLensError.configuration(
                "Unknown top-level key(s): \(unexpected.joined(separator: ", ")).")
        }

        guard let projectValue = topLevel["project"] else {
            throw SwiftLensError.configuration("Missing required `project` section.")
        }
        guard let packsValue = topLevel["packs"] else {
            throw SwiftLensError.configuration("Missing required `packs` section.")
        }
        guard let rulesValue = topLevel["rules"] else {
            throw SwiftLensError.configuration("Missing required `rules` section.")
        }

        let project = try parseProject(projectValue)
        let packs = try parsePacks(packsValue)
        let rules = try parseRules(rulesValue)
        return SwiftLensConfig(project: project, packs: packs, rules: rules)
    }

    private func parseProject(_ value: YAMLValue) throws -> ProjectConfiguration {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("`project` must be a mapping.")
        }

        let allowedKeys: Set<String> = ["path", "include", "exclude"]
        guard Set(mapping.keys).isSubset(of: allowedKeys) else {
            let unexpected = Set(mapping.keys).subtracting(allowedKeys).sorted()
            throw SwiftLensError.configuration(
                "Unknown `project` key(s): \(unexpected.joined(separator: ", ")).")
        }

        guard
            let path = stringValue(mapping["path"])?.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines), !path.isEmpty
        else {
            throw SwiftLensError.configuration("`project.path` is required.")
        }

        let include = try stringArrayValue(mapping["include"], field: "project.include")
        let exclude = try stringArrayValue(mapping["exclude"], field: "project.exclude")
        return ProjectConfiguration(path: path, include: include, exclude: exclude)
    }

    private func parsePacks(_ value: YAMLValue) throws -> [String: PackConfiguration] {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("`packs` must be a mapping.")
        }

        let allowedPackNames = Set(registry.descriptors.map { $0.pack })
        guard Set(mapping.keys).isSubset(of: allowedPackNames) else {
            let unexpected = Set(mapping.keys).subtracting(allowedPackNames).sorted()
            throw SwiftLensError.configuration(
                "Unknown pack key(s): \(unexpected.joined(separator: ", ")).")
        }

        var packs: [String: PackConfiguration] = [:]
        for (packName, packValue) in mapping {
            guard case .mapping(let packMapping) = packValue else {
                throw SwiftLensError.configuration("`packs.\(packName)` must be a mapping.")
            }

            let allowedKeys: Set<String> = ["enabled", "severityOverrides"]
            guard Set(packMapping.keys).isSubset(of: allowedKeys) else {
                let unexpected = Set(packMapping.keys).subtracting(allowedKeys).sorted()
                throw SwiftLensError.configuration(
                    "Unknown `packs.\(packName)` key(s): \(unexpected.joined(separator: ", ")).")
            }

            let enabled = boolValue(packMapping["enabled"]) ?? true
            let severityOverrides = try parseSeverityOverrides(
                packMapping["severityOverrides"],
                packName: packName
            )

            packs[packName] = PackConfiguration(
                enabled: enabled, severityOverrides: severityOverrides)
        }

        return packs
    }

    private func parseSeverityOverrides(_ value: YAMLValue?, packName: String) throws -> [String:
        Severity]
    {
        guard let value else {
            return [:]
        }

        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration(
                "`packs.\(packName).severityOverrides` must be a mapping.")
        }

        let allowedRuleIDs = Set(registry.descriptors(inPack: packName).map { $0.id })
        guard Set(mapping.keys).isSubset(of: allowedRuleIDs) else {
            let unexpected = Set(mapping.keys).subtracting(allowedRuleIDs).sorted()
            throw SwiftLensError.configuration(
                "Unknown `packs.\(packName).severityOverrides` key(s): \(unexpected.joined(separator: ", "))."
            )
        }

        var overrides: [String: Severity] = [:]
        for (ruleID, value) in mapping {
            guard let severity = severityValue(value) else {
                throw SwiftLensError.configuration(
                    "`packs.\(packName).severityOverrides.\(ruleID)` must be `advisory`, `warning`, or `error`."
                )
            }
            overrides[ruleID] = severity
        }

        return overrides
    }

    private func parseRules(_ value: YAMLValue) throws -> [String: RuleConfiguration] {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("`rules` must be a mapping.")
        }

        let allowedRuleIDs = Set(registry.descriptors.map { $0.id })
        guard Set(mapping.keys).isSubset(of: allowedRuleIDs) else {
            let unexpected = Set(mapping.keys).subtracting(allowedRuleIDs).sorted()
            throw SwiftLensError.configuration(
                "Unknown rule key(s): \(unexpected.joined(separator: ", ")).")
        }

        var rules: [String: RuleConfiguration] = [:]
        for (ruleID, ruleValue) in mapping {
            guard let descriptor = registry.descriptor(for: ruleID) else {
                continue
            }

            guard case .mapping(let ruleMapping) = ruleValue else {
                throw SwiftLensError.configuration("`rules.\(ruleID)` must be a mapping.")
            }

            let allowedKeys: Set<String> = ["enabled", "severity", "config"]
            guard Set(ruleMapping.keys).isSubset(of: allowedKeys) else {
                let unexpected = Set(ruleMapping.keys).subtracting(allowedKeys).sorted()
                throw SwiftLensError.configuration(
                    "Unknown `rules.\(ruleID)` key(s): \(unexpected.joined(separator: ", ")).")
            }

            let enabled = boolValue(ruleMapping["enabled"])
            let severity = severityValue(ruleMapping["severity"])
            if ruleMapping["severity"] != nil, severity == nil {
                throw SwiftLensError.configuration(
                    "`rules.\(ruleID).severity` must be `advisory`, `warning`, or `error`.")
            }

            let config: [String: YAMLValue]
            if let configValue = ruleMapping["config"] {
                guard case .mapping(let configMapping) = configValue else {
                    throw SwiftLensError.configuration(
                        "`rules.\(ruleID).config` must be a mapping.")
                }

                if !descriptor.configKeys.isEmpty && configMapping.isEmpty {
                    throw SwiftLensError.configuration(
                        "Missing `rules.\(ruleID).config` configuration.")
                }

                guard Set(configMapping.keys).isSubset(of: descriptor.configKeys) else {
                    let unexpected = Set(configMapping.keys).subtracting(descriptor.configKeys)
                        .sorted()
                    throw SwiftLensError.configuration(
                        "Unknown `rules.\(ruleID).config` key(s): \(unexpected.joined(separator: ", "))."
                    )
                }

                if descriptor.configKeys.isEmpty && !configMapping.isEmpty {
                    throw SwiftLensError.configuration("`rules.\(ruleID).config` must be empty.")
                }

                config = configMapping
            } else if descriptor.configKeys.isEmpty {
                config = [:]
            } else {
                throw SwiftLensError.configuration(
                    "Missing `rules.\(ruleID).config` configuration.")
            }

            rules[ruleID] = RuleConfiguration(enabled: enabled, severity: severity, config: config)
        }

        return rules
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

    private func severityValue(_ value: YAMLValue?) -> Severity? {
        guard let value else {
            return nil
        }

        switch value {
        case .string(let string):
            return Severity(rawValue: string)
        case .bool, .array, .mapping:
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
