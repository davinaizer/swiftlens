import Foundation

enum ExplainabilityRenderer {
    static func renderPresetList(_ descriptors: [PresetDescriptor]) -> String {
        var lines: [String] = ["Available presets:", ""]

        for (index, descriptor) in descriptors.enumerated() {
            lines.append("- \(descriptor.id)")
            lines.append("  \(descriptor.explanation.description.first ?? "")")
            if index != descriptors.count - 1 {
                lines.append("")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    static func renderPresetExplanation(_ descriptor: PresetDescriptor) -> String {
        renderSections([
            ("Description", descriptor.explanation.description),
            (
                "Composition",
                descriptor.expansion.packOrder.map { "pack: \($0)" }
            ),
            ("Intended Structure", descriptor.explanation.intendedStructure),
            ("Governance Defaults", descriptor.explanation.governanceDefaults),
            ("Example Layout", descriptor.explanation.exampleLayout),
            ("Notes", descriptor.explanation.notes)
        ])
    }

    static func renderPackList(_ descriptors: [RulePackDescriptor]) -> String {
        var lines: [String] = ["Available rule packs:", ""]

        for (index, descriptor) in descriptors.enumerated() {
            lines.append("- \(descriptor.id)")
            lines.append("  \(descriptor.explanation.description.first ?? "")")
            if index != descriptors.count - 1 {
                lines.append("")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    static func renderPackExplanation(_ descriptor: RulePackDescriptor) -> String {
        var lines: [String] = []
        lines.append("Source")
        lines.append("")
        lines.append("pack: \(descriptor.id)")
        lines.append("")
        lines.append("Description")
        lines.append("")
        lines.append(contentsOf: descriptor.explanation.description)
        lines.append("")
        lines.append("Enabled Rules")
        lines.append("")
        if descriptor.explanation.enabledRules.isEmpty {
            lines.append("- none")
        } else {
            lines.append(contentsOf: descriptor.explanation.enabledRules.map { "- \($0)" })
        }
        lines.append("")
        lines.append("Generated Boundaries")
        lines.append("")
        if descriptor.explanation.generatedBoundaries.isEmpty {
            lines.append("- none")
        } else {
            lines.append(contentsOf: renderBoundarySections(descriptor.explanation.generatedBoundaries))
        }
        lines.append("")
        lines.append("Intended Usage")
        lines.append("")
        lines.append(contentsOf: descriptor.explanation.intendedUsage)
        lines.append("")
        lines.append("Notes")
        lines.append("")
        lines.append(contentsOf: descriptor.explanation.notes)
        lines.append("")
        lines.append("Limitations")
        lines.append("")
        lines.append(contentsOf: descriptor.explanation.limitations)

        return lines.joined(separator: "\n") + "\n"
    }

    static func renderRuleExplanation(_ descriptor: RuleDescriptor) -> String {
        return renderSections([
            ("Purpose", descriptor.explanation.purpose),
            ("Detection Mechanism", descriptor.explanation.detectionMechanism),
            ("Config Shape", descriptor.explanation.configShape),
            ("Deterministic Behavior", descriptor.explanation.deterministicBehavior),
            ("Limitations", descriptor.explanation.limitations),
            ("Example Violation", descriptor.explanation.exampleViolation),
            ("Example Config", descriptor.explanation.exampleConfig)
        ])
    }

    static func renderPresetUsage() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens preset list
          swiftlens preset explain <PRESET>

        Commands:
          swiftlens preset list
          swiftlens preset explain <PRESET>
        """
            + "\n"
    }

    static func renderRuleUsage() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens rule explain <RULE-ID>

        Commands:
          swiftlens rule explain <RULE-ID>
        """
            + "\n"
    }

    private static func renderSections(_ sections: [(String, [String])]) -> String {
        var lines: [String] = []
        for (index, section) in sections.enumerated() {
            lines.append(section.0)
            lines.append("")
            lines.append(contentsOf: section.1)
            if index != sections.count - 1 {
                lines.append("")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func renderBoundarySections(_ boundaries: [RulePackBoundaryBlueprint]) -> [String] {
        var lines: [String] = []
        for (index, boundary) in boundaries.enumerated() {
            lines.append("- \(boundary.path)/")
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
            if index != boundaries.count - 1 {
                lines.append("")
            }
        }
        return lines
    }
}
