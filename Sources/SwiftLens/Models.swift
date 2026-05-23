import Foundation

enum Severity: String, Codable, Equatable, Sendable {
    case advisory
    case warning
    case error
}

enum Confidence: String, Codable, Equatable, Sendable {
    case low
    case medium
    case high
}

struct SourceLocation: Codable, Equatable, Sendable {
    let line: Int
    let column: Int
}

struct SourceRange: Codable, Equatable, Sendable {
    let start: SourceLocation
    let end: SourceLocation
}

struct Violation: Codable, Equatable, Sendable {
    let rule: String
    let pack: String
    let severity: Severity
    let confidence: Confidence
    let file: String
    let range: SourceRange
    let reason: String
    let fixPattern: String?
}

struct ScanSummary: Codable, Equatable, Sendable {
    let filesScanned: Int
    let violations: Int
}

struct ScanReport: Codable, Equatable, Sendable {
    let command: String
    let projectPath: String
    let summary: ScanSummary
    let violations: [Violation]
}

struct ScanOptions: Equatable, Sendable {
    var configPath: String?
    var format: String = "json"
    var path: String?
    var verbose: Bool = false
    var baselinePath: String?
}

struct ValidationOptions: Equatable, Sendable {
    var configPath: String?
}

struct BoundaryInspectionMetadata: Equatable, Sendable {
    let hasExplicitForbiddenImports: Bool
}

enum GovernanceSource: Equatable, Hashable, Sendable {
    case builtInRuleDefaults
    case presetOwnedFallbackDefaults
    case preset
    case pack(String)
    case explicitConfig

    var displayName: String {
        switch self {
        case .builtInRuleDefaults:
            return "built-in-rule-defaults"
        case .presetOwnedFallbackDefaults:
            return "preset-owned-fallback-defaults"
        case .preset:
            return "preset"
        case .pack(let packID):
            return "pack: \(packID)"
        case .explicitConfig:
            return "explicit-config"
        }
    }
}

extension GovernanceSource: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "built-in-rule-defaults":
            self = .builtInRuleDefaults
        case "preset-owned-fallback-defaults":
            self = .presetOwnedFallbackDefaults
        case "preset":
            self = .preset
        case "explicit-config":
            self = .explicitConfig
        default:
            if value.hasPrefix("pack: ") {
                self = .pack(String(value.dropFirst("pack: ".count)))
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown governance source `\(value)`."
                )
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(displayName)
    }
}

struct ResolvedForbiddenImportScope: Equatable, Sendable {
    let scope: ForbiddenImportScope
    let source: GovernanceSource
}

struct ResolvedRuleConfiguration: Equatable, Sendable {
    let configuration: RuleConfiguration
    let sources: [GovernanceSource]
    let forbiddenImportScopes: [ResolvedForbiddenImportScope]
}

struct GovernanceResolution: Equatable, Sendable {
    let ruleConfigurations: [String: ResolvedRuleConfiguration]
    let ruleOrder: [String]
    let ignorePaths: [String]
}

struct InitOptions: Equatable, Sendable {
    var presetID: String?
    var force: Bool = false
    var showHelp: Bool = false
}

struct ProjectConfiguration: Equatable, Sendable {
    let path: String
    let include: [String]
    let exclude: [String]
}

struct IgnoreConfiguration: Equatable, Sendable {
    let paths: [String]
}

struct RuleConfiguration: Equatable, Sendable {
    let enabled: Bool?
    let severity: Severity?
    let config: [String: YAMLValue]
}

struct SwiftLensConfig: Equatable, Sendable {
    let presetID: String?
    let project: ProjectConfiguration
    let rules: [String: RuleConfiguration]
    let ruleOrder: [String]
    let ignore: IgnoreConfiguration

    init(
        presetID: String? = nil,
        project: ProjectConfiguration,
        rules: [String: RuleConfiguration] = [:],
        ruleOrder: [String] = [],
        ignore: IgnoreConfiguration = IgnoreConfiguration(paths: [])
    ) {
        self.presetID = presetID
        self.project = project
        self.rules = rules
        self.ruleOrder = ruleOrder
        self.ignore = ignore
    }
}

struct LoadedConfiguration: Equatable, Sendable {
    let configURL: URL
    let projectRootURL: URL
    let config: SwiftLensConfig
    let boundaryInspection: BoundaryInspectionMetadata
    let governance: GovernanceResolution
}

struct ConfigBuildResult: Equatable, Sendable {
    let config: SwiftLensConfig
    let governance: GovernanceResolution
}

struct ParsedImport: Equatable, Sendable {
    let module: String
    let range: SourceRange
}

struct ParsedSwiftFile: Equatable, Sendable {
    let url: URL
    let relativePath: String
    let imports: [ParsedImport]
}

struct CLIExecutionResult: Equatable, Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}
