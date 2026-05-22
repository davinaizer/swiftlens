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
}

struct ValidationOptions: Equatable, Sendable {
    var configPath: String?
}

struct ProjectConfiguration: Equatable, Sendable {
    let path: String
    let include: [String]
    let exclude: [String]
}

struct IgnoreConfiguration: Equatable, Sendable {
    let paths: [String]
}

struct PackConfiguration: Equatable, Sendable {
    let enabled: Bool
    let severityOverrides: [String: Severity]
}

struct RuleConfiguration: Equatable, Sendable {
    let enabled: Bool?
    let severity: Severity?
    let config: [String: YAMLValue]
}

struct SwiftLensConfig: Equatable, Sendable {
    let project: ProjectConfiguration
    let packs: [String: PackConfiguration]
    let rules: [String: RuleConfiguration]
    let ruleOrder: [String]
    let ignore: IgnoreConfiguration

    init(
        project: ProjectConfiguration,
        packs: [String: PackConfiguration] = [:],
        rules: [String: RuleConfiguration] = [:],
        ruleOrder: [String] = [],
        ignore: IgnoreConfiguration = IgnoreConfiguration(paths: [])
    ) {
        self.project = project
        self.packs = packs
        self.rules = rules
        self.ruleOrder = ruleOrder
        self.ignore = ignore
    }
}

struct LoadedConfiguration: Equatable, Sendable {
    let configURL: URL
    let projectRootURL: URL
    let config: SwiftLensConfig
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
