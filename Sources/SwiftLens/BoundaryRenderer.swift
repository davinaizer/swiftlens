import Foundation

enum BoundaryRenderer {
    static func render(_ report: BoundaryInspectionReport) -> String {
        var lines: [String] = [
            "Project Boundaries",
            ""
        ]

        lines.append("Preset:")
        lines.append("- \(report.presetID ?? "none")")
        lines.append("")

        lines.append("Ignored Paths:")
        if report.ignoredPaths.isEmpty {
            lines.append("- none")
        } else {
            lines.append(contentsOf: report.ignoredPaths.map { "- \(displayIgnoredPath($0))" })
        }
        lines.append("")

        lines.append("Boundaries:")
        if report.boundaries.isEmpty {
            lines.append("- none")
        } else {
            for (index, boundary) in report.boundaries.enumerated() {
                lines.append("- \(boundary.path)")
                lines.append("  Source:")
                lines.append(contentsOf: boundary.sources.map { "    - \($0.rawValue)" })

                if !boundary.allows.isEmpty {
                    lines.append("  Allows:")
                    lines.append(contentsOf: boundary.allows.map { "    - \($0)" })
                }

                if !boundary.restrictedImports.isEmpty {
                    lines.append("  Restricted Imports:")
                    lines.append(contentsOf: boundary.restrictedImports.map { "    - \($0)" })
                }

                if !boundary.notes.isEmpty {
                    lines.append("  Notes:")
                    lines.append(contentsOf: boundary.notes.map { "    - \($0)" })
                }

                if index != report.boundaries.count - 1 {
                    lines.append("")
                }
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func displayIgnoredPath(_ path: String) -> String {
        let normalized = normalizeRelativePath(path)
        if normalized.isEmpty {
            return "<root>"
        }
        return normalized + "/"
    }
}
