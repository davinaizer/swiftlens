import Foundation

enum GovernanceNormalizationError: Error, Equatable {
    case duplicateScopeIdentity(String)
}

struct ResolvedRulePackExpansion: Equatable, Sendable {
    let ruleConfigurations: [String: ResolvedRuleConfiguration]
    let ruleOrder: [String]
}

extension GovernanceSource {
    var isInternalDefault: Bool {
        switch self {
        case .builtInRuleDefaults, .presetOwnedFallbackDefaults:
            return true
        case .preset, .pack, .explicitConfig:
            return false
        }
    }
}

enum GovernanceNormalization {
    static func mergeSourceTrail(
        base: [GovernanceSource],
        source: GovernanceSource
    ) -> [GovernanceSource] {
        guard !base.contains(source) else {
            return base
        }
        return base + [source]
    }

    static func mergeIgnorePaths(
        base: [String],
        override: [String]
    ) -> [String] {
        var merged: [String] = []
        var seen: Set<String> = []

        for path in base + override {
            let normalized = normalizeRelativePath(path)
            guard seen.insert(normalized).inserted else {
                continue
            }
            merged.append(normalized)
        }

        return merged
    }

    static func mergeForbiddenImportScopes(
        base: [ResolvedForbiddenImportScope],
        override: [ForbiddenImportScope],
        source: GovernanceSource,
        field: String
    ) throws -> [ResolvedForbiddenImportScope] {
        var merged = base
        var indexByScope: [String: Int] = [:]

        for (index, item) in merged.enumerated() {
            indexByScope[normalizeRelativePath(item.scope.from)] = index
        }

        var seenInLayer: Set<String> = []
        for scope in override {
            let key = normalizeRelativePath(scope.from)
            guard seenInLayer.insert(key).inserted else {
                throw SwiftLensError.configuration(
                    "Duplicate normalized scope identity `\(key)` in `\(field)`."
                )
            }

            let resolvedScope = ForbiddenImportScope(
                from: key,
                imports: scope.imports.map(normalizeRelativePath)
            )

            if let index = indexByScope[key] {
                merged[index] = ResolvedForbiddenImportScope(scope: resolvedScope, source: source)
            } else {
                indexByScope[key] = merged.count
                merged.append(ResolvedForbiddenImportScope(scope: resolvedScope, source: source))
            }
        }

        return merged
    }

    static func mergeRuleConfiguration(
        base: ResolvedRuleConfiguration?,
        override: RuleConfiguration,
        ruleID: String,
        source: GovernanceSource
    ) throws -> ResolvedRuleConfiguration {
        let enabled = override.enabled ?? base?.configuration.enabled
        let severity = override.severity ?? base?.configuration.severity
        var config = base?.configuration.config.merging(override.config) { _, new in new } ?? override.config

        let sources = mergeSourceTrail(base: base?.sources ?? [], source: source)
        var scopeResolutions = base?.forbiddenImportScopes ?? []

        if ruleID == ForbiddenImportRule.descriptor.id {
            let baseScopes = scopeResolutions
            let overrideScopes = try ForbiddenImportSupport.scopes(from: override.config)
            scopeResolutions = try mergeForbiddenImportScopes(
                base: baseScopes,
                override: overrideScopes,
                source: source,
                field: "forbiddenImports"
            )
            config["forbiddenImports"] = ForbiddenImportSupport.encodeScopes(
                scopeResolutions.map(\.scope)
            )
        }

        let resolvedConfiguration = RuleConfiguration(
            enabled: enabled,
            severity: severity,
            config: config
        )

        return ResolvedRuleConfiguration(
            configuration: resolvedConfiguration,
            sources: sources,
            forbiddenImportScopes: scopeResolutions
        )
    }
}
