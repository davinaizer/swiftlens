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
                throw SwiftLensError.configuration("Duplicate rule key `\(ruleID)`.")
            }
            order.append(canonicalRuleID)
        }

        return (order, [:])
    }

    func parseLegacyRules(_ mapping: [String: YAMLValue]) throws
        -> (ruleOrder: [String], ruleConfigurations: [String: RuleConfiguration]) {
        var ruleConfigurations: [String: RuleConfiguration] = [:]
        var ruleIDs: [String] = []

        for (ruleID, ruleValue) in mapping {
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

        return mapping
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
                        YAMLValue.mapping([
                            "from": YAMLValue.string(scope.from),
                            "imports": YAMLValue.array(scope.imports.map(YAMLValue.string))
                        ])
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
            paths: try normalizedPathList(mapping["paths"], field: "ignore.paths")
        )
    }

    func parseForbiddenImportScopes(from value: YAMLValue) throws -> [ForbiddenImportScope] {
        guard case .array(let items) = value else {
            throw SwiftLensError.configuration(
                "`architecture.forbiddenImports` must be a list."
            )
        }

        var scopes: [ForbiddenImportScope] = []
        for item in items {
            guard case .mapping(let mapping) = item else {
                throw SwiftLensError.configuration(
                    "`architecture.forbiddenImports` must contain mappings."
                )
            }

            try validateKeys(
                mapping.keys,
                allowed: ["from", "imports"],
                subject: "`architecture.forbiddenImports`"
            )

            guard let from = decoder.stringValue(mapping["from"]) else {
                throw SwiftLensError.configuration(
                    "`architecture.forbiddenImports.from` is required."
                )
            }

            scopes.append(
                ForbiddenImportScope(
                    from: normalizeRelativePath(from),
                    imports: try decoder.stringArrayValue(
                        mapping["imports"],
                        field: "architecture.forbiddenImports.imports"
                    )
                )
            )
        }

        return scopes
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
            return [
                "forbiddenImports": .array([])
            ]
        }

        return [
            "forbiddenImports": .array(
                legacyImports.map { module in
                YAMLValue.mapping([
                        "from": YAMLValue.string(""),
                        "imports": YAMLValue.array([YAMLValue.string(module)])
                    ])
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

    func requireMapping(_ value: YAMLValue, field: String) throws -> [String: YAMLValue] {
        guard case .mapping(let mapping) = value else {
            throw SwiftLensError.configuration("\(field) must be a mapping.")
        }
        return mapping
    }

    func validateKeys(
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

    func canonicalRuleID(for ruleID: String) -> String? {
        registry.canonicalRuleID(for: ruleID)
    }

    func mergeRuleConfiguration(
        base: RuleConfiguration?,
        override: RuleConfiguration
    ) -> RuleConfiguration {
        RuleConfiguration(
            enabled: override.enabled ?? base?.enabled,
            severity: override.severity ?? base?.severity,
            config: base?.config.merging(override.config) { _, new in new } ?? override.config
        )
    }
}

struct ForbiddenImportScope {
    let from: String
    let imports: [String]
}
