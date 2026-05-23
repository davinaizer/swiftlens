import Foundation

struct ConfigLoaderParser {
    let registry: RuleRegistry
    let presetRegistry: PresetRegistry
    let rulePackRegistry: RulePackRegistry
    let decoder = ConfigValueDecoder()

    func buildConfig(from root: YAMLValue, configURL: URL) throws -> ConfigBuildResult {
        guard case .mapping(let topLevel) = root else {
            throw SwiftLensError.configuration("Config at \(configURL.path) must be a mapping.")
        }

        try validateTopLevelKeys(topLevel.keys)
        try parseVersion(topLevel["version"])
        let presetID = try parsePreset(topLevel["preset"])
        let project = try resolveProjectConfiguration(topLevel["project"], presetID: presetID)
        let rulesValue = try resolveRulesValue(topLevel["rules"], presetID: presetID)
        let presetExpansion = try presetExpansion(for: presetID)
        let presetRuleExpansion = try presetRuleExpansion(for: presetExpansion)
        let legacyRuleState = try parseRules(rulesValue)
        let architectureRuleConfig = try parseArchitecture(topLevel["architecture"])
        let ignore = try parseIgnore(topLevel["ignore"])

        var resolvedRules = presetRuleExpansion?.ruleConfigurations ?? [:]
        if let architectureRuleConfig {
            let canonicalRuleID = ForbiddenImportRule.descriptor.id
            let baseRuleConfiguration = resolvedRules[canonicalRuleID]
            resolvedRules[canonicalRuleID] = try GovernanceNormalization.mergeRuleConfiguration(
                base: baseRuleConfiguration,
                override: RuleConfiguration(
                    enabled: nil,
                    severity: nil,
                    config: architectureRuleConfig
                ),
                ruleID: canonicalRuleID,
                source: .explicitConfig
            )
        }

        for (ruleID, ruleConfiguration) in legacyRuleState.ruleConfigurations {
            resolvedRules[ruleID] = try GovernanceNormalization.mergeRuleConfiguration(
                base: resolvedRules[ruleID],
                override: ruleConfiguration,
                ruleID: ruleID,
                source: .explicitConfig
            )
        }

        let ruleOrder = mergedRuleOrder(
            presetRuleOrder: presetRuleExpansion?.ruleOrder,
            explicitRuleOrder: legacyRuleState.ruleOrder,
            hasExplicitRules: rulesValue != nil
        )

        let config = SwiftLensConfig(
            presetID: presetID,
            project: project,
            rules: resolvedRules.mapValues(\.configuration),
            ruleOrder: ruleOrder,
            ignore: ignore
        )

        let governance = GovernanceResolution(
            ruleConfigurations: resolvedRules,
            ruleOrder: ruleOrder,
            ignorePaths: ignore.paths
        )

        return ConfigBuildResult(config: config, governance: governance)
    }

    private func validateTopLevelKeys(_ keys: [String]) throws {
        let allowedTopLevelKeys: Set<String> = [
            "version",
            "preset",
            "project",
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

    private func presetRuleExpansion(for presetExpansion: PresetExpansion?) throws -> ResolvedRulePackExpansion? {
        guard let presetExpansion else {
            return nil
        }

        return try rulePackRegistry.resolvedExpansion(for: presetExpansion.packOrder)
    }

    func mergedRuleOrder(
        presetRuleOrder: [String]?,
        explicitRuleOrder: [String],
        hasExplicitRules: Bool
    ) -> [String] {
        guard hasExplicitRules else {
            return presetRuleOrder ?? explicitRuleOrder
        }

        var merged = presetRuleOrder ?? []
        var seen = Set(merged)
        for ruleID in explicitRuleOrder {
            let canonicalRuleID = canonicalRuleID(for: ruleID) ?? ruleID
            guard seen.insert(canonicalRuleID).inserted else {
                continue
            }
            merged.append(canonicalRuleID)
        }

        return merged
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

}
