import Foundation

struct RuleDescriptor: Sendable {
    let id: String
    let pack: String
    let defaultSeverity: Severity
    let defaultConfidence: Confidence
    let defaultEnabled: Bool
    let configKeys: Set<String>
    let defaultConfig: [String: YAMLValue]
    let explanation: RuleExplanation
    let evaluate: @Sendable (RuleEvaluationContext) -> [Violation]

    init(
        id: String,
        pack: String,
        defaultSeverity: Severity,
        defaultConfidence: Confidence,
        defaultEnabled: Bool,
        configKeys: [String] = [],
        defaultConfig: [String: YAMLValue] = [:],
        explanation: RuleExplanation,
        evaluate: @escaping @Sendable (RuleEvaluationContext) -> [Violation]
    ) {
        self.id = id
        self.pack = pack
        self.defaultSeverity = defaultSeverity
        self.defaultConfidence = defaultConfidence
        self.defaultEnabled = defaultEnabled
        self.configKeys = Set(configKeys)
        self.defaultConfig = defaultConfig
        self.explanation = explanation
        self.evaluate = evaluate
    }
}

struct RuleExplanation: Equatable, Sendable {
    let purpose: [String]
    let detectionMechanism: [String]
    let configShape: [String]
    let deterministicBehavior: [String]
    let limitations: [String]
    let exampleViolation: [String]
    let exampleConfig: [String]
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
    let aliases: [String: String]

    init(descriptors: [RuleDescriptor], aliases: [String: String] = [:]) {
        self.descriptors = descriptors
        self.aliases = aliases
    }

    static let `default` = RuleRegistry(
        descriptors: [ForbiddenImportRule.descriptor],
        aliases: ["ForbiddenImportRule": ForbiddenImportRule.descriptor.id]
    )

    func canonicalRuleID(for ruleID: String) -> String? {
        if descriptors.contains(where: { $0.id == ruleID }) {
            return ruleID
        }

        return aliases[ruleID]
    }

    func descriptor(for ruleID: String) -> RuleDescriptor? {
        guard let canonicalID = canonicalRuleID(for: ruleID) else {
            return nil
        }

        return descriptors.first { $0.id == canonicalID }
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

        for ruleID in config.ruleOrder {
            guard let descriptor = registry.descriptor(for: ruleID) else {
                continue
            }

            let settings = resolveSettings(for: descriptor, config: config)
            guard settings.enabled else {
                continue
            }

            let context = RuleEvaluationContext(
                descriptor: descriptor, settings: settings, files: files)
            violations.append(contentsOf: descriptor.evaluate(context))
        }

        return violations
    }

    private func resolveSettings(for descriptor: RuleDescriptor, config: SwiftLensConfig)
        -> ResolvedRuleSettings {
        let pack = config.packs[descriptor.pack]
        let rule = config.rules[descriptor.id]
        let enabled =
            (pack?.enabled == false) ? false : (rule?.enabled ?? descriptor.defaultEnabled)
        let severity =
            rule?.severity ?? pack?.severityOverrides[descriptor.id] ?? descriptor.defaultSeverity
        let configValues = descriptor.defaultConfig.merging(rule?.config ?? [:]) { _, new in new }

        return ResolvedRuleSettings(
            enabled: enabled,
            severity: severity,
            confidence: descriptor.defaultConfidence,
            config: configValues
        )
    }
}
