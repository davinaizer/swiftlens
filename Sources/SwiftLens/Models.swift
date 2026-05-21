import Foundation

enum Severity: String, Codable, Equatable {
    case advisory
    case warning
    case error
}

enum Confidence: String, Codable, Equatable {
    case low
    case medium
    case high
}

struct SourceLocation: Codable, Equatable {
    let line: Int
    let column: Int
}

struct SourceRange: Codable, Equatable {
    let start: SourceLocation
    let end: SourceLocation
}

struct Violation: Codable, Equatable {
    let rule: String
    let pack: String
    let severity: Severity
    let confidence: Confidence
    let file: String
    let range: SourceRange
    let reason: String
    let fixPattern: String?
}

struct ScanSummary: Codable, Equatable {
    let filesScanned: Int
    let violations: Int
}

struct ScanReport: Codable, Equatable {
    let command: String
    let projectPath: String
    let summary: ScanSummary
    let violations: [Violation]
}

struct ScanOptions: Equatable {
    var configPath: String?
    var format: String = "json"
    var path: String?
    var verbose: Bool = false
}

struct ValidationOptions: Equatable {
    var configPath: String?
}

struct ProjectConfiguration: Equatable {
    let path: String
    let include: [String]
    let exclude: [String]
}

struct ForbiddenImportRuleConfiguration: Equatable {
    let enabled: Bool
    let forbiddenImports: [String]
}

struct SwiftLensConfig: Equatable {
    let project: ProjectConfiguration
    let forbiddenImportRule: ForbiddenImportRuleConfiguration
}

struct LoadedConfiguration: Equatable {
    let configURL: URL
    let projectRootURL: URL
    let config: SwiftLensConfig
}

struct ParsedImport: Equatable {
    let module: String
    let range: SourceRange
}

struct ParsedSwiftFile: Equatable {
    let url: URL
    let imports: [ParsedImport]
}

struct CLIExecutionResult: Equatable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

