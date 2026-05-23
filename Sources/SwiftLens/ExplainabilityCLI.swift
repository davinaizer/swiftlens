import Foundation

enum ExplainabilityCLI {
    static func executePreset(_ command: PresetCLICommand) -> CLIExecutionResult {
        executePresetCommand(command)
    }

    static func executeRule(_ command: RuleCLICommand) -> CLIExecutionResult {
        executeRuleCommand(command)
    }

    static func parse(commandName: String, flags: [String]) throws -> CLICommand? {
        switch commandName {
        case "preset":
            return .preset(try parsePresetCommand(flags))
        case "rule":
            return .rule(try parseRuleCommand(flags))
        default:
            return nil
        }
    }

    static func presetUsageText() -> String {
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

    static func ruleUsageText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens rule explain <RULE-ID>

        Commands:
          swiftlens rule explain <RULE-ID>
        """
            + "\n"
    }

    private static func executePresetCommand(_ command: PresetCLICommand) -> CLIExecutionResult {
        switch command {
        case .help:
            return CLIExecutionResult(exitCode: 0, stdout: presetUsageText(), stderr: "")
        case .list:
            return CLIExecutionResult(
                exitCode: 0,
                stdout: ExplainabilityRenderer.renderPresetList(
                    PresetRegistry.default.descriptors),
                stderr: "")
        case .explain(let presetID):
            guard let descriptor = PresetRegistry.default.descriptor(for: presetID) else {
                return usageError("Unknown preset `\(presetID)`.")
            }
            return CLIExecutionResult(
                exitCode: 0,
                stdout: ExplainabilityRenderer.renderPresetExplanation(descriptor),
                stderr: "")
        }
    }

    private static func executeRuleCommand(_ command: RuleCLICommand) -> CLIExecutionResult {
        switch command {
        case .help:
            return CLIExecutionResult(exitCode: 0, stdout: ruleUsageText(), stderr: "")
        case .explain(let ruleID):
            guard let descriptor = RuleRegistry.default.descriptor(for: ruleID) else {
                return usageError("Unknown rule `\(ruleID)`.")
            }
            return CLIExecutionResult(
                exitCode: 0,
                stdout: ExplainabilityRenderer.renderRuleExplanation(descriptor),
                stderr: "")
        }
    }

    private static func parsePresetCommand(_ arguments: [String]) throws -> PresetCLICommand {
        var iterator = arguments.makeIterator()
        guard let subcommand = iterator.next() else {
            return .help
        }

        switch subcommand {
        case "help", "-h", "--help":
            try ensureNoExtraArguments(iterator: &iterator, subject: "`swiftlens preset`")
            return .help
        case "list":
            try ensureNoExtraArguments(iterator: &iterator, subject: "`swiftlens preset list`")
            return .list
        case "explain":
            guard let presetID = iterator.next() else {
                throw SwiftLensError.usage("Missing value for `preset explain`.")
            }
            try ensureNoExtraArguments(
                iterator: &iterator,
                subject: "`swiftlens preset explain`"
            )
            return .explain(presetID)
        default:
            throw SwiftLensError.usage("Unknown subcommand `\(subcommand)` for `preset`.")
        }
    }

    private static func parseRuleCommand(_ arguments: [String]) throws -> RuleCLICommand {
        var iterator = arguments.makeIterator()
        guard let subcommand = iterator.next() else {
            return .help
        }

        switch subcommand {
        case "help", "-h", "--help":
            try ensureNoExtraArguments(iterator: &iterator, subject: "`swiftlens rule`")
            return .help
        case "explain":
            guard let ruleID = iterator.next() else {
                throw SwiftLensError.usage("Missing value for `rule explain`.")
            }
            try ensureNoExtraArguments(
                iterator: &iterator,
                subject: "`swiftlens rule explain`"
            )
            return .explain(ruleID)
        default:
            throw SwiftLensError.usage("Unknown subcommand `\(subcommand)` for `rule`.")
        }
    }

    private static func ensureNoExtraArguments<T: IteratorProtocol>(
        iterator: inout T,
        subject: String
    ) throws where T.Element == String {
        if let extra = iterator.next() {
            throw SwiftLensError.usage("Unexpected argument `\(extra)` in \(subject).")
        }
    }

    private static func usageError(_ message: String) -> CLIExecutionResult {
        let error = SwiftLensError.usage(message)
        return CLIExecutionResult(
            exitCode: error.exitCode,
            stdout: "",
            stderr: error.message + "\n"
        )
    }
}

enum CLICommand {
    case help
    case version
    case validateConfig(ValidationOptions)
    case scan(ScanOptions)
    case baseline(BaselineCLICommand)
    case initCommand(InitOptions)
    case preset(PresetCLICommand)
    case rule(RuleCLICommand)
    case boundary(BoundaryCLICommand)
}

enum PresetCLICommand {
    case help
    case list
    case explain(String)
}

enum RuleCLICommand {
    case help
    case explain(String)
}
