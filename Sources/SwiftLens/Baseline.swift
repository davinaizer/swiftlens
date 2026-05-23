import CryptoKit
import Foundation
import SwiftUI

struct BaselineFile: Codable, Equatable, Sendable {
    let version: Int
    let violations: [BaselineViolation]
}

struct BaselineViolation: Codable, Equatable, Sendable {
    let fingerprint: String
    let rule: String
    let file: String
    let reason: String
}

struct BaselineCreateOptions: Equatable, Sendable {
    var configPath: String?
    var path: String?
    var verbose: Bool = false
    var outputPath: String = ".swiftlens/baseline.json"

    func scanOptions() -> ScanOptions {
        ScanOptions(
            configPath: configPath,
            path: path,
            verbose: verbose
        )
    }
}

struct BaselineFingerprintGenerator {
    private struct Payload: Codable {
        let rule: String
        let file: String
        let reason: String
        let line: Int
    }

    func fingerprint(for violation: Violation, projectRootPath: String) -> String {
        let rootURL = URL(fileURLWithPath: projectRootPath, isDirectory: true)
        let fileURL = URL(fileURLWithPath: violation.file)
        let relativePath = canonicalRelativePath(for: fileURL, root: rootURL)
        let payload = Payload(
            rule: violation.rule,
            file: relativePath,
            reason: violation.reason,
            line: violation.range.start.line
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(payload)) ?? Data()
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

struct BaselineStore {
    private let fileManager: FileManager
    private let fingerprintGenerator: BaselineFingerprintGenerator

    init(
        fileManager: FileManager = .default,
        fingerprintGenerator: BaselineFingerprintGenerator = BaselineFingerprintGenerator()
    ) {
        self.fileManager = fileManager
        self.fingerprintGenerator = fingerprintGenerator
    }

    func load(from path: String) throws -> BaselineFile {
        let url = try resolveURL(for: path)
        let contents: String
        do {
            contents = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw SwiftLensError.configuration("Baseline file not found at \(url.path).")
        }

        let decoder = JSONDecoder()
        let baseline: BaselineFile
        do {
            baseline = try decoder.decode(BaselineFile.self, from: Data(contents.utf8))
        } catch {
            throw SwiftLensError.configuration("Invalid baseline file at \(url.path).")
        }

        guard baseline.version == 1 else {
            throw SwiftLensError.configuration(
                "Unsupported baseline version `\(baseline.version)`.")
        }

        return baseline
    }

    func write(_ baseline: BaselineFile, to path: String) throws {
        let url = try resolveURL(for: path)
        try write(baseline, to: url)
    }

    func write(_ baseline: BaselineFile, to url: URL) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(baseline)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SwiftLensError.internalFailure("Unable to encode baseline file.")
        }

        guard let payload = (string + "\n").data(using: .utf8) else {
            throw SwiftLensError.internalFailure("Unable to encode baseline file.")
        }

        try payload.write(to: url, options: [.atomic])
    }

    func baseline(from report: ScanReport) -> BaselineFile {
        let rootURL = URL(fileURLWithPath: report.projectPath, isDirectory: true)
        let entries = report.violations.map { violation in
            BaselineViolation(
                fingerprint: fingerprintGenerator.fingerprint(
                    for: violation,
                    projectRootPath: report.projectPath
                ),
                rule: violation.rule,
                file: canonicalRelativePath(
                    for: URL(fileURLWithPath: violation.file),
                    root: rootURL
                ),
                reason: violation.reason
            )
        }

        return BaselineFile(
            version: 1,
            violations: entries.sorted(by: Self.compareViolations)
        )
    }

    func baselineViolations(from report: ScanReport) -> [BaselineViolation] {
        baseline(from: report).violations
    }

    func filter(
        _ violations: [Violation],
        using baseline: BaselineFile,
        projectRootPath: String
    ) -> [Violation] {
        let fingerprints = Set(baseline.violations.map(\.fingerprint))
        return violations.filter {
            !fingerprints.contains(
                fingerprintGenerator.fingerprint(
                    for: $0,
                    projectRootPath: projectRootPath
                )
            )
        }
    }

    private func resolveURL(for path: String) throws -> URL {
        let base = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path).standardizedFileURL
        } else {
            url = URL(fileURLWithPath: path, relativeTo: base).standardizedFileURL
        }
        return url
    }

    private static func compareViolations(_ lhs: BaselineViolation, _ rhs: BaselineViolation)
        -> Bool
    {
        if lhs.fingerprint != rhs.fingerprint {
            return lhs.fingerprint < rhs.fingerprint
        }
        if lhs.rule != rhs.rule {
            return lhs.rule < rhs.rule
        }
        if lhs.file != rhs.file {
            return lhs.file < rhs.file
        }
        return lhs.reason < rhs.reason
    }
}
