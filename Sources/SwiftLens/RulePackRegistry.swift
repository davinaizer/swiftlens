import Foundation

struct ForbiddenImportScope: Equatable, Sendable {
    let from: String
    let imports: [String]
}

struct RulePackBoundaryBlueprint: Equatable, Sendable {
    let path: String
    let allows: [String]
    let restrictedImports: [String]
    let notes: [String]
}

struct RulePackExplanation: Equatable, Sendable {
    let description: [String]
    let enabledRules: [String]
    let generatedBoundaries: [RulePackBoundaryBlueprint]
    let intendedUsage: [String]
    let notes: [String]
    let limitations: [String]
}

struct RulePackExpansion: Equatable, Sendable {
    let rules: [String: RuleConfiguration]
    let ruleOrder: [String]
}

struct RulePackDescriptor: Equatable, Sendable {
    let id: String
    let expansion: RulePackExpansion
    let explanation: RulePackExplanation
}

enum RulePackRegistryError: Error, Equatable {
    case duplicatePackID(String)
}

enum ForbiddenImportSupport {
    static func decodeScopes(from value: YAMLValue?, field: String) throws -> [ForbiddenImportScope] {
        guard let value else {
            return []
        }

        guard case .array(let items) = value else {
            throw SwiftLensError.configuration("`\((field))` must be a list.")
        }

        var scopes: [ForbiddenImportScope] = []
        for item in items {
            guard case .mapping(let mapping) = item else {
                throw SwiftLensError.configuration("`\((field))` must contain mappings.")
            }

            let keySet = Set(mapping.keys)
            let allowed: Set<String> = ["from", "imports"]
            guard keySet.isSubset(of: allowed) else {
                let unexpected = keySet.subtracting(allowed).sorted()
                throw SwiftLensError.configuration(
                    "Unknown \(field) key(s): \(unexpected.joined(separator: ", "))."
                )
            }

            guard case .string(let from)? = mapping["from"] else {
                throw SwiftLensError.configuration("`\((field)).from` is required.")
            }

            scopes.append(
                ForbiddenImportScope(
                    from: normalizeRelativePath(from),
                    imports: try ConfigValueDecoder().stringArrayValue(
                        mapping["imports"],
                        field: field + ".imports"
                    )
                )
            )
        }

        return scopes
    }

    static func encodeScopes(_ scopes: [ForbiddenImportScope]) -> YAMLValue {
        .array(
            scopes.map { scope in
                .mapping([
                    "from": .string(normalizeRelativePath(scope.from)),
                    "imports": .array(scope.imports.map(YAMLValue.string))
                ])
            }
        )
    }

    static func mergeScopes(
        base: [ForbiddenImportScope],
        override: [ForbiddenImportScope]
    ) -> [ForbiddenImportScope] {
        var merged: [ForbiddenImportScope] = []
        var indexByScope: [String: Int] = [:]

        func insert(_ scope: ForbiddenImportScope) {
            let key = normalizeRelativePath(scope.from)
            if let index = indexByScope[key] {
                merged[index] = ForbiddenImportScope(from: key, imports: scope.imports)
                return
            }

            indexByScope[key] = merged.count
            merged.append(ForbiddenImportScope(from: key, imports: scope.imports))
        }

        base.forEach(insert)
        override.forEach(insert)
        return merged
    }

    static func canonicalConfig(from scopes: [ForbiddenImportScope]) -> [String: YAMLValue] {
        ["forbiddenImports": encodeScopes(scopes)]
    }

    static func scopes(from config: [String: YAMLValue]) throws -> [ForbiddenImportScope] {
        try decodeScopes(from: config["forbiddenImports"], field: "forbiddenImports")
    }
}

struct RulePackRegistry: Sendable {
    let descriptors: [RulePackDescriptor]

    init(descriptors: [RulePackDescriptor]) throws {
        var seen: Set<String> = []
        for descriptor in descriptors {
            guard seen.insert(descriptor.id).inserted else {
                throw RulePackRegistryError.duplicatePackID(descriptor.id)
            }
        }
        self.descriptors = descriptors
    }

    static let `default` = makeDefaultRegistry()

    var packIDs: [String] {
        descriptors.map(\.id)
    }

    func descriptor(for packID: String) -> RulePackDescriptor? {
        descriptors.first { $0.id == packID }
    }

    func expansion(for packIDs: [String]) throws -> RulePackExpansion {
        var ruleOrder: [String] = []
        var seenRuleIDs: Set<String> = []
        var resolvedRules: [String: RuleConfiguration] = [:]

        for packID in packIDs {
            guard let descriptor = descriptor(for: packID) else {
                throw SwiftLensError.configuration("Unknown pack `\(packID)`.")
            }

            for ruleID in descriptor.expansion.ruleOrder where seenRuleIDs.insert(ruleID).inserted {
                ruleOrder.append(ruleID)
            }

            for (ruleID, ruleConfiguration) in descriptor.expansion.rules {
                resolvedRules[ruleID] = try mergeRuleConfiguration(
                    base: resolvedRules[ruleID],
                    override: ruleConfiguration,
                    ruleID: ruleID
                )
            }
        }

        return RulePackExpansion(rules: resolvedRules, ruleOrder: ruleOrder)
    }

    private static func makeDefaultRegistry() -> RulePackRegistry {
        do {
            return try RulePackRegistry(descriptors: RulePackRegistryBuiltins.descriptors)
        } catch {
            preconditionFailure("Built-in rule pack registry must be valid: \(error)")
        }
    }

    private func mergeRuleConfiguration(
        base: RuleConfiguration?,
        override: RuleConfiguration,
        ruleID: String
    ) throws -> RuleConfiguration {
        let enabled = override.enabled ?? base?.enabled
        let severity = override.severity ?? base?.severity
        let config = try mergeRuleConfig(
            base: base?.config ?? [:],
            override: override.config,
            ruleID: ruleID
        )

        return RuleConfiguration(enabled: enabled, severity: severity, config: config)
    }

    private func mergeRuleConfig(
        base: [String: YAMLValue],
        override: [String: YAMLValue],
        ruleID: String
    ) throws -> [String: YAMLValue] {
        var merged = base.merging(override) { _, new in new }

        guard ruleID == ForbiddenImportRule.descriptor.id else {
            return merged
        }

        let baseScopes = try ForbiddenImportSupport.scopes(from: base)
        let overrideScopes = try ForbiddenImportSupport.scopes(from: override)
        let mergedScopes = ForbiddenImportSupport.mergeScopes(base: baseScopes, override: overrideScopes)
        merged["forbiddenImports"] = ForbiddenImportSupport.encodeScopes(mergedScopes)
        return merged
    }

}
