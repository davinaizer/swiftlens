import Foundation

struct ConfigLoaderParser {
    let registry: RuleRegistry
    let decoder = ConfigValueDecoder()

    func buildConfig(from root: YAMLValue, configURL: URL) throws -> SwiftLensConfig {
        guard case .mapping(let topLevel) = root else {
            throw SwiftLensError.configuration("Config at \(configURL.path) must be a mapping.")
        }

        try validateTopLevelKeys(topLevel.keys)

        guard let projectValue = topLevel["project"] else {
            throw SwiftLensError.configuration("Missing required `project` section.")
        }

        let project = try parseProject(projectValue)
        guard let rulesValue = topLevel["rules"] else {
            throw SwiftLensError.configuration("Missing required `rules` section.")
        }

        let packs = try parsePacks(topLevel["packs"])
        let legacyRuleState = try parseRules(rulesValue)
        let architectureRuleConfig = try parseArchitecture(topLevel["architecture"])
        let ignore = try parseIgnore(topLevel["ignore"])

        var rules = legacyRuleState.ruleConfigurations
        if let architectureRuleConfig {
            let canonicalRuleID = ForbiddenImportRule.descriptor.id
            if let existing = rules[canonicalRuleID] {
                rules[canonicalRuleID] = RuleConfiguration(
                    enabled: existing.enabled,
                    severity: existing.severity,
                    config: existing.config.merging(architectureRuleConfig) { _, new in new }
                )
            } else {
                rules[canonicalRuleID] = RuleConfiguration(
                    enabled: nil,
                    severity: nil,
                    config: architectureRuleConfig
                )
            }
        }

        let ruleOrder = legacyRuleState.ruleOrder
        return SwiftLensConfig(
            project: project,
            packs: packs,
            rules: rules,
            ruleOrder: ruleOrder,
            ignore: ignore
        )
    }

    private func validateTopLevelKeys(_ keys: Dictionary<String, YAMLValue>.Keys) throws {
        let allowedTopLevelKeys: Set<String> = ["project", "packs", "rules", "architecture", "ignore"]
        try validateKeys(keys, allowed: allowedTopLevelKeys, subject: "top-level")
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
