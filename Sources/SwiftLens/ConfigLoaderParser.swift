import Foundation

struct ConfigLoaderParser {
    let registry: RuleRegistry
    private let decoder = ConfigValueDecoder()

    func buildConfig(from root: YAMLValue, configURL: URL) throws -> SwiftLensConfig {
        guard case .mapping(let topLevel) = root else {
            throw SwiftLensError.configuration("Config at \(configURL.path) must be a mapping.")
        }

        try validateTopLevelKeys(topLevel.keys)

        guard let projectValue = topLevel["project"] else {
            throw SwiftLensError.configuration("Missing required `project` section.")
        }
        guard let packsValue = topLevel["packs"] else {
            throw SwiftLensError.configuration("Missing required `packs` section.")
        }
        guard let rulesValue = topLevel["rules"] else {
            throw SwiftLensError.configuration("Missing required `rules` section.")
        }

        return SwiftLensConfig(
            project: try parseProject(projectValue),
            packs: try parsePacks(packsValue),
            rules: try parseRules(rulesValue)
        )
    }

    private func validateTopLevelKeys(_ keys: Dictionary<String, YAMLValue>.Keys) throws {
        let allowedTopLevelKeys: Set<String> = ["project", "packs", "rules"]
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
            include: try decoder.stringArrayValue(mapping["include"], field: "project.include"),
            exclude: try decoder.stringArrayValue(mapping["exclude"], field: "project.exclude")
        )
    }

    private func parsePacks(_ value: YAMLValue) throws -> [String: PackConfiguration] {
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
        let allowedRuleIDs = Set(registry.descriptors(inPack: packName).map { $0.id })
        try validateKeys(
            mapping.keys,
            allowed: allowedRuleIDs,
            subject: "`packs.\(packName).severityOverrides`"
        )

        var overrides: [String: Severity] = [:]
        for (ruleID, ruleValue) in mapping {
            guard let severity = try decoder.severityValue(ruleValue) else {
                throw SwiftLensError.configuration(
                    "`packs.\(packName).severityOverrides.\(ruleID)` must be `advisory`, `warning`, or `error`."
                )
            }
            overrides[ruleID] = severity
        }

        return overrides
    }

    private func parseRules(_ value: YAMLValue) throws -> [String: RuleConfiguration] {
        let mapping = try requireMapping(value, field: "`rules`")
        let allowedRuleIDs = Set(registry.descriptors.map { $0.id })
        try validateKeys(mapping.keys, allowed: allowedRuleIDs, subject: "rule")

        var rules: [String: RuleConfiguration] = [:]
        for (ruleID, ruleValue) in mapping {
            guard let descriptor = registry.descriptor(for: ruleID) else {
                continue
            }

            rules[ruleID] = try parseRuleConfiguration(
                ruleID: ruleID,
                value: ruleValue,
                descriptor: descriptor
            )
        }

        return rules
    }

    private func parseRuleConfiguration(
        ruleID: String,
        value: YAMLValue,
        descriptor: RuleDescriptor
    ) throws -> RuleConfiguration {
        let mapping = try requireMapping(value, field: "`rules.\(ruleID)`")
        try validateKeys(
            mapping.keys,
            allowed: ["enabled", "severity", "config"],
            subject: "`rules.\(ruleID)`"
        )

        let enabled = decoder.boolValue(mapping["enabled"])
        let severity = try decoder.severityValue(
            mapping["severity"],
            field: "`rules.\(ruleID).severity`"
        )
        let config = try parseRuleConfig(
            ruleID: ruleID,
            descriptor: descriptor,
            value: mapping["config"]
        )

        return RuleConfiguration(enabled: enabled, severity: severity, config: config)
    }

    private func parseRuleConfig(
        ruleID: String,
        descriptor: RuleDescriptor,
        value: YAMLValue?
    ) throws -> [String: YAMLValue] {
        guard let value else {
            guard descriptor.configKeys.isEmpty else {
                throw SwiftLensError.configuration(
                    "Missing `rules.\(ruleID).config` configuration."
                )
            }
            return [:]
        }

        let mapping = try requireMapping(value, field: "`rules.\(ruleID).config`")
        if descriptor.configKeys.isEmpty {
            guard mapping.isEmpty else {
                throw SwiftLensError.configuration("`rules.\(ruleID).config` must be empty.")
            }
            return [:]
        }

        guard !mapping.isEmpty else {
            throw SwiftLensError.configuration("Missing `rules.\(ruleID).config` configuration.")
        }
        try validateKeys(
            mapping.keys,
            allowed: descriptor.configKeys,
            subject: "`rules.\(ruleID).config`"
        )
        return mapping
    }

    private func requireMapping(_ value: YAMLValue, field: String) throws -> [String: YAMLValue] {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("\(field) must be a mapping.")
        }
        return mapping
    }

    private func validateKeys(
        _ keys: Dictionary<String, YAMLValue>.Keys,
        allowed: Set<String>,
        subject: String
    ) throws {
        let keySet = Set(keys)
        guard keySet.isSubset(of: allowed) else {
            let unexpected = keySet.subtracting(allowed).sorted()
            throw SwiftLensError.configuration(
                "Unknown \(subject) key(s): \(unexpected.joined(separator: ", "))."
            )
        }
    }

}
