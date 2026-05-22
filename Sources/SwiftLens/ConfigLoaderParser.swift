import Foundation

struct ConfigLoaderParser {
    let registry: RuleRegistry
    let presetRegistry: PresetRegistry
    let decoder = ConfigValueDecoder()

    func buildConfig(from root: YAMLValue, configURL: URL) throws -> SwiftLensConfig {
        guard case .mapping(let topLevel) = root else {
            throw SwiftLensError.configuration("Config at \(configURL.path) must be a mapping.")
        }

        try validateTopLevelKeys(topLevel.keys)
        try parseVersion(topLevel["version"])
        let presetID = try parsePreset(topLevel["preset"])
        let project = try resolveProjectConfiguration(topLevel["project"], presetID: presetID)
        let rulesValue = try resolveRulesValue(topLevel["rules"], presetID: presetID)
        let presetExpansion = try presetExpansion(for: presetID)
        let packs = try parsePacks(topLevel["packs"])
        let legacyRuleState = try parseRules(rulesValue)
        let architectureRuleConfig = try parseArchitecture(topLevel["architecture"])
        let ignore = try parseIgnore(topLevel["ignore"])

        var rules = presetExpansion?.rules ?? [:]
        if let architectureRuleConfig {
            let canonicalRuleID = ForbiddenImportRule.descriptor.id
            let baseRuleConfiguration = rules[canonicalRuleID]
            rules[canonicalRuleID] = mergeRuleConfiguration(
                base: baseRuleConfiguration,
                override: RuleConfiguration(
                    enabled: nil,
                    severity: nil,
                    config: architectureRuleConfig
                )
            )
        }

        for (ruleID, ruleConfiguration) in legacyRuleState.ruleConfigurations {
            rules[ruleID] = mergeRuleConfiguration(
                base: rules[ruleID],
                override: ruleConfiguration
            )
        }

        let ruleOrder = rulesValue == nil ? (presetExpansion?.ruleOrder ?? legacyRuleState.ruleOrder)
            : legacyRuleState.ruleOrder
        return SwiftLensConfig(
            presetID: presetID,
            project: project,
            packs: packs,
            rules: rules,
            ruleOrder: ruleOrder,
            ignore: ignore
        )
    }

    private func validateTopLevelKeys(_ keys: Dictionary<String, YAMLValue>.Keys) throws {
        let allowedTopLevelKeys: Set<String> = [
            "version",
            "preset",
            "project",
            "packs",
            "rules",
            "architecture",
            "ignore"
        ]
        try validateKeys(keys, allowed: allowedTopLevelKeys, subject: "top-level")
    }

    private func parseVersion(_ value: YAMLValue?) throws {
        guard let value else {
            return
        }

        guard let version = decoder.stringValue(value)?.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        ), version == "1" else {
            throw SwiftLensError.configuration(
                "Unsupported config version `\(decoder.stringValue(value) ?? "unknown")`."
            )
        }
    }

    private func resolveProjectConfiguration(
        _ value: YAMLValue?,
        presetID: String?
    ) throws -> ProjectConfiguration {
        if let value {
            return try parseProject(value)
        }

        if presetID != nil {
            return ProjectConfiguration(path: ".", include: [], exclude: [])
        }

        throw SwiftLensError.configuration("Missing required `project` section.")
    }

    private func resolveRulesValue(_ value: YAMLValue?, presetID: String?) throws -> YAMLValue? {
        if value != nil {
            return value
        }

        if presetID == nil {
            throw SwiftLensError.configuration("Missing required `rules` section.")
        }

        return nil
    }

    private func parsePreset(_ value: YAMLValue?) throws -> String? {
        guard let value else {
            return nil
        }

        guard let presetID = decoder.stringValue(value)?.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        ), !presetID.isEmpty else {
            throw SwiftLensError.configuration("`preset` must be a string.")
        }

        guard presetRegistry.descriptor(for: presetID) != nil else {
            throw SwiftLensError.configuration("Unknown preset `\(presetID)`.")
        }

        return presetID
    }

    private func presetExpansion(for presetID: String?) throws -> PresetExpansion? {
        guard let presetID else {
            return nil
        }

        guard let expansion = presetRegistry.expansion(for: presetID) else {
            throw SwiftLensError.configuration("Unknown preset `\(presetID)`.")
        }

        return expansion
    }

    private func parseProject(_ value: YAMLValue) throws -> ProjectConfiguration {
        let mapping = try requireMapping(value, field: "`project`")
        try validateKeys(mapping.keys, allowed: ["path", "include", "exclude"], subject: "`project`")

        guard let path = decoder.stringValue(mapping["path"])?.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        ), !path.isEmpty else {
            throw SwiftLensError.configuration("`project.path` is required.")
        }

        return ProjectConfiguration(
            path: path,
            include: try normalizedPathList(mapping["include"], field: "project.include"),
            exclude: try normalizedPathList(mapping["exclude"], field: "project.exclude")
        )
    }

    private func parsePacks(_ value: YAMLValue?) throws -> [String: PackConfiguration] {
        guard let value else {
            return [:]
        }

        let mapping = try requireMapping(value, field: "`packs`")
        let allowedPackNames = Set(registry.descriptors.map { $0.pack })
        try validateKeys(mapping.keys, allowed: allowedPackNames, subject: "pack")

        var packs: [String: PackConfiguration] = [:]
        for (packName, packValue) in mapping {
            packs[packName] = try parsePackConfiguration(packName: packName, value: packValue)
        }

        return packs
    }

    private func parsePackConfiguration(
        packName: String,
        value: YAMLValue
    ) throws -> PackConfiguration {
        let mapping = try requireMapping(value, field: "`packs.\(packName)`")
        try validateKeys(
            mapping.keys,
            allowed: ["enabled", "severityOverrides"],
            subject: "`packs.\(packName)`"
        )

        let enabled = decoder.boolValue(mapping["enabled"]) ?? true
        return PackConfiguration(
            enabled: enabled,
            severityOverrides: try parseSeverityOverrides(
                mapping["severityOverrides"],
                packName: packName
            )
        )
    }

    private func parseSeverityOverrides(
        _ value: YAMLValue?,
        packName: String
    ) throws -> [String: Severity] {
        guard let value else {
            return [:]
        }

        let mapping = try requireMapping(value, field: "`packs.\(packName).severityOverrides`")
        var overrides: [String: Severity] = [:]

        for (ruleID, ruleValue) in mapping {
            guard let canonicalRuleID = canonicalRuleID(for: ruleID) else {
                throw SwiftLensError.configuration("Unknown pack key `\(ruleID)`.")
            }
            guard let severity = try decoder.severityValue(ruleValue) else {
                throw SwiftLensError.configuration(
                    "`packs.\(packName).severityOverrides.\(ruleID)` must be `advisory`, `warning`, or `error`."
                )
            }
            overrides[canonicalRuleID] = severity
        }

        return overrides
    }
}
