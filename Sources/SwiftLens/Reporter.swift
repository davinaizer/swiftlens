import Foundation

struct JSONReporter {
    func render(_ report: ScanReport) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(report)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SwiftLensError.internalFailure("Unable to encode JSON output.")
        }
        return string + "\n"
    }
}
