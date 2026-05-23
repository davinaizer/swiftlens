import Foundation

extension ConfigLoaderParser {
    func parseRules(
        _ value: YAMLValue?
    ) throws -> (ruleOrder: [String], ruleConfigurations: [String: RuleConfiguration]) {
        guard let value else {
            return ([], [:])
        }

        switch value {
        case .array(let items):
            return try parseRuleEnablementList(items)
        case .mapping(let mapping):
            return try parseLegacyRules(mapping)
        case .string, .bool:
            throw SwiftLensError.configuration("`rules` must be a list or a mapping.")
        }
    }

    func parseRuleEnablementList(_ items: [YAMLValue]) throws
        -> (ruleOrder: [String], ruleConfigurations: [String: RuleConfiguration]) {
        var order: [String] = []
        var seen: Set<String> = []

        for item in items {
            guard case .string(let ruleID) = item else {
                throw SwiftLensError.configuration("`rules` must contain only strings.")
            }

            guard let canonicalRuleID = canonicalRuleID(for: ruleID) else {
                throw SwiftLensError.configuration("Unknown rule key `\(ruleID)`.")
            }

            guard seen.insert(canonicalRuleID).inserted else {
                continue
            }
            order.append(canonicalRuleID)
        }

        return (order, [:])
    }

    func parseLegacyRules(_ mapping: YAMLMapping) throws
        -> (ruleOrder: [String], ruleConfigurations: [String: RuleConfiguration]) {
        var ruleConfigurations: [String: RuleConfiguration] = [:]
        var ruleIDs: [String] = []

        for (ruleID, ruleValue) in mapping.orderedEntries {
            guard let canonicalRuleID = canonicalRuleID(for: ruleID) else {
                throw SwiftLensError.configuration("Unknown rule key `\(ruleID)`.")
            }

            let descriptor = registry.descriptor(for: canonicalRuleID)
            ruleConfigurations[canonicalRuleID] = try parseRuleConfiguration(
                ruleID: ruleID,
                value: ruleValue,
                descriptor: descriptor
            )
            ruleIDs.append(canonicalRuleID)
        }

        let orderedRuleIDs = registry.descriptors.map(\.id).filter { ruleIDs.contains($0) }
        return (orderedRuleIDs, ruleConfigurations)
    }

    func parseRuleConfiguration(
        ruleID: String,
        value: YAMLValue,
        descriptor: RuleDescriptor?
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

    func parseRuleConfig(
        ruleID: String,
        descriptor: RuleDescriptor?,
        value: YAMLValue?
    ) throws -> [String: YAMLValue] {
        guard let descriptor else {
            return [:]
        }

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

        if ruleID != descriptor.id && descriptor.id == ForbiddenImportRule.descriptor.id {
            return try canonicalForbiddenImportConfig(from: mapping["forbiddenImports"])
        }

        return mapping.dictionary
    }

    func parseArchitecture(_ value: YAMLValue?) throws -> [String: YAMLValue]? {
        guard let value else {
            return nil
        }

        let mapping = try requireMapping(value, field: "`architecture`")
        try validateKeys(
            mapping.keys,
            allowed: ["forbiddenImports"],
            subject: "`architecture`"
        )

        guard let forbiddenImports = mapping["forbiddenImports"] else {
            return nil
        }

        return [
            "forbiddenImports": .array(
                try parseForbiddenImportScopes(from: forbiddenImports)
                    .map { scope in
                        YAMLValue.mapping(YAMLMapping([
                            ("from", YAMLValue.string(scope.from)),
                            ("imports", YAMLValue.array(scope.imports.map(YAMLValue.string)))
                        ]))
                    }
            )
        ]
    }

    func parseIgnore(_ value: YAMLValue?) throws -> IgnoreConfiguration {
        guard let value else {
            return IgnoreConfiguration(paths: [])
        }

        let mapping = try requireMapping(value, field: "`ignore`")
        try validateKeys(mapping.keys, allowed: ["paths"], subject: "`ignore`")

        return IgnoreConfiguration(
            paths: try normalizedIgnorePathList(mapping["paths"], field: "ignore.paths")
        )
    }

    func parseForbiddenImportScopes(from value: YAMLValue) throws -> [ForbiddenImportScope] {
        try ForbiddenImportSupport.decodeScopes(
            from: value,
            field: "architecture.forbiddenImports"
        )
    }

    func canonicalForbiddenImportConfig(from value: YAMLValue?) throws -> [String: YAMLValue] {
        guard let value else {
            return [:]
        }

        let legacyImports = try decoder.stringArrayValue(
            value,
            field: "rules.ForbiddenImportRule.config.forbiddenImports"
        )
        guard !legacyImports.isEmpty else {
            return ["forbiddenImports": .array([])]
        }

        return [
            "forbiddenImports": .array(
                legacyImports.map { module in
                    YAMLValue.mapping(YAMLMapping([
                        ("from", YAMLValue.string("")),
                        ("imports", YAMLValue.array([YAMLValue.string(module)]))
                    ]))
                }
            )
        ]
    }

    func normalizedPathList(_ value: YAMLValue?, field: String) throws -> [String] {
        guard let value else {
            return []
        }

        let rawPaths = try decoder.stringArrayValue(value, field: field)
        return rawPaths.map(normalizeRelativePath)
    }

    func normalizedIgnorePathList(_ value: YAMLValue?, field: String) throws -> [String] {
        let rawPaths = try normalizedPathList(value, field: field)
        return GovernanceNormalization.mergeIgnorePaths(base: [], override: rawPaths)
    }

    func requireMapping(_ value: YAMLValue, field: String) throws -> YAMLMapping {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("\(field) must be a mapping.")
        }
        return mapping
    }

    func validateKeys(
        _ keys: [String],
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

    func canonicalRuleID(for ruleID: String) -> String? {
        registry.canonicalRuleID(for: ruleID)
    }

}
