import Foundation

struct RuleDescriptor: Sendable {
    let id: String
    let pack: String
    let defaultSeverity: Severity
    let defaultConfidence: Confidence
    let defaultEnabled: Bool
    let configKeys: Set<String>
    let defaultConfig: [String: YAMLValue]
    let evaluate: @Sendable (RuleEvaluationContext) -> [Violation]

    init(
        id: String,
        pack: String,
        defaultSeverity: Severity,
        defaultConfidence: Confidence,
        defaultEnabled: Bool,
        configKeys: [String] = [],
        defaultConfig: [String: YAMLValue] = [:],
        evaluate: @escaping @Sendable (RuleEvaluationContext) -> [Violation]
    ) {
        self.id = id
        self.pack = pack
        self.defaultSeverity = defaultSeverity
        self.defaultConfidence = defaultConfidence
        self.defaultEnabled = defaultEnabled
        self.configKeys = Set(configKeys)
        self.defaultConfig = defaultConfig
        self.evaluate = evaluate
    }
}

struct ResolvedRuleSettings: Sendable {
    let enabled: Bool
    let severity: Severity
    let confidence: Confidence
    let config: [String: YAMLValue]
}

struct RuleEvaluationContext: Sendable {
    let descriptor: RuleDescriptor
    let settings: ResolvedRuleSettings
    let files: [ParsedSwiftFile]
}

struct RuleRegistry: Sendable {
    let descriptors: [RuleDescriptor]

    init(descriptors: [RuleDescriptor]) {
        self.descriptors = descriptors
    }

    static let `default` = RuleRegistry(descriptors: [ForbiddenImportRule.descriptor])

    func descriptor(for ruleID: String) -> RuleDescriptor? {
        descriptors.first { $0.id == ruleID }
    }

    func descriptors(inPack pack: String) -> [RuleDescriptor] {
        descriptors.filter { $0.pack == pack }
    }
}

struct RuleEngine {
    private let registry: RuleRegistry

    init(registry: RuleRegistry = .default) {
        self.registry = registry
    }

    func evaluate(config: SwiftLensConfig, files: [ParsedSwiftFile]) -> [Violation] {
        var violations: [Violation] = []

        for descriptor in registry.descriptors {
            let settings = resolveSettings(for: descriptor, config: config)
            guard settings.enabled else {
                continue
            }

            let context = RuleEvaluationContext(descriptor: descriptor, settings: settings, files: files)
            violations.append(contentsOf: descriptor.evaluate(context))
        }

        return violations
    }

    private func resolveSettings(for descriptor: RuleDescriptor, config: SwiftLensConfig) -> ResolvedRuleSettings {
        let pack = config.packs[descriptor.pack]
        let rule = config.rules[descriptor.id]
        let enabled = (pack?.enabled == false) ? false : (rule?.enabled ?? descriptor.defaultEnabled)
        let severity = rule?.severity ?? pack?.severityOverrides[descriptor.id] ?? descriptor.defaultSeverity
        let configValues = descriptor.defaultConfig.merging(rule?.config ?? [:]) { _, new in new }

        return ResolvedRuleSettings(
            enabled: enabled,
            severity: severity,
            confidence: descriptor.defaultConfidence,
            config: configValues
        )
    }
}
