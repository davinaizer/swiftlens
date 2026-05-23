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
            ("Intended Structure", descriptor.explanation.intendedStructure),
            ("Governance Defaults", descriptor.explanation.governanceDefaults),
            ("Example Layout", descriptor.explanation.exampleLayout),
            ("Notes", descriptor.explanation.notes)
        ])
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
}
