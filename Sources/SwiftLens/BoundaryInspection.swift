import Foundation

struct BoundaryInspectionReport: Equatable, Sendable {
    let presetID: String?
    let ignoredPaths: [String]
    let boundaries: [BoundaryInspectionEntry]
}

struct BoundaryInspectionEntry: Equatable, Sendable {
    let path: String
    let sources: [BoundarySource]
    let allows: [String]
    let restrictedImports: [String]
    let notes: [String]
}

struct BoundaryInspector {
    private let registry: RuleRegistry
    private let presetRegistry: PresetRegistry

    init(
        registry: RuleRegistry = .default,
        presetRegistry: PresetRegistry = .default
    ) {
        self.registry = registry
        self.presetRegistry = presetRegistry
    }

    func inspect(_ loadedConfiguration: LoadedConfiguration) throws -> BoundaryInspectionReport {
        let presetID = loadedConfiguration.config.presetID
        let ruleEngine = RuleEngine(registry: registry)
        let canonicalRuleID = ForbiddenImportRule.descriptor.id

        guard let descriptor = registry.descriptor(for: canonicalRuleID) else {
            return BoundaryInspectionReport(
                presetID: presetID,
                ignoredPaths: loadedConfiguration.config.ignore.paths,
                boundaries: []
            )
        }

        let settings = ruleEngine.resolvedSettings(for: descriptor, config: loadedConfiguration.config)
        guard settings.enabled else {
            return BoundaryInspectionReport(
                presetID: presetID,
                ignoredPaths: loadedConfiguration.config.ignore.paths,
                boundaries: []
            )
        }

        var boundaries: [BoundaryInspectionEntry] = []
        if let presetID,
            let descriptor = presetRegistry.descriptor(for: presetID) {
            boundaries.append(contentsOf: descriptor.boundaryBlueprints.map { blueprint in
                BoundaryInspectionEntry(
                    path: displayPath(blueprint.path),
                    sources: [.preset],
                    allows: blueprint.allows,
                    restrictedImports: [],
                    notes: blueprint.notes
                )
            })
        }

        let ruleBoundaries = try resolveRuleBoundaries(
            loadedConfiguration: loadedConfiguration,
            canonicalRuleID: canonicalRuleID
        )
        boundaries.append(contentsOf: ruleBoundaries)

        return BoundaryInspectionReport(
            presetID: presetID,
            ignoredPaths: loadedConfiguration.config.ignore.paths,
            boundaries: boundaries
        )
    }

    private func resolveRuleBoundaries(
        loadedConfiguration: LoadedConfiguration,
        canonicalRuleID: String
    ) throws -> [BoundaryInspectionEntry] {
        guard let ruleConfig = loadedConfiguration.config.rules[canonicalRuleID] else {
            return []
        }

        let source: BoundarySource = loadedConfiguration.boundaryInspection.hasExplicitForbiddenImports
            ? .explicitConfig
            : .preset

        let scopes = try ForbiddenImportSupport.decodeScopes(
            from: ruleConfig.config["forbiddenImports"],
            field: "forbiddenImports"
        )
        let orderedScopes = source == .preset
            ? orderedPresetScopes(scopes, presetID: loadedConfiguration.config.presetID)
            : scopes
        return try boundaryEntries(scopes: orderedScopes, source: source)
    }

    private func boundaryEntries(
        scopes: [ForbiddenImportScope],
        source: BoundarySource
    ) throws -> [BoundaryInspectionEntry] {
        scopes.map { scope in
            BoundaryInspectionEntry(
                path: displayPath(scope.from),
                sources: [source],
                allows: [],
                restrictedImports: scope.imports.map(displayImportPattern),
                notes: source == .preset ? presetNotes(for: scope) : []
            )
        }
    }

    private func presetNotes(for scope: ForbiddenImportScope) -> [String] {
        let normalized = normalizeRelativePath(scope.from)
        let hasFeaturePrefix = scope.imports.contains { normalizeRelativePath($0) == "Features" }
        if normalized == "Features" && hasFeaturePrefix {
            return ["sibling feature imports are restricted"]
        }
        return []
    }

    private func orderedPresetScopes(
        _ scopes: [ForbiddenImportScope],
        presetID: String?
    ) -> [ForbiddenImportScope] {
        guard let presetID,
            let descriptor = presetRegistry.descriptor(for: presetID) else {
            return scopes
        }

        let order = descriptor.boundaryScopeOrder
        let orderIndex: [String: Int] = Dictionary(
            uniqueKeysWithValues: order.enumerated().map { (normalizeRelativePath($0.element), $0.offset) }
        )

        return scopes.sorted { left, right in
            let leftIndex = orderIndex[normalizeRelativePath(left.from)] ?? Int.max
            let rightIndex = orderIndex[normalizeRelativePath(right.from)] ?? Int.max
            if leftIndex != rightIndex {
                return leftIndex < rightIndex
            }
            if normalizeRelativePath(left.from) != normalizeRelativePath(right.from) {
                return normalizeRelativePath(left.from) < normalizeRelativePath(right.from)
            }
            return left.imports.joined(separator: ",") < right.imports.joined(separator: ",")
        }
    }

    private func displayPath(_ path: String) -> String {
        let normalized = normalizeRelativePath(path)
        if normalized.isEmpty {
            return "<root>"
        }
        return normalized + "/"
    }

    private func displayImportPattern(_ value: String) -> String {
        let normalized = normalizeRelativePath(value)
        guard !normalized.isEmpty else {
            return value
        }

        let moduleLikeRoots: Set<String> = [
            "App",
            "Core",
            "Data",
            "Dependencies",
            "Domain",
            "Features",
            "Shared",
            "UI"
        ]
        if normalized.contains("/") || normalized.contains(".") || moduleLikeRoots.contains(normalized) {
            return normalized + "/*"
        }

        return normalized
    }
}
