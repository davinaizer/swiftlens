import Foundation

enum SwiftLensCLIParsing {
    static func parse(arguments: [String]) throws -> CLICommand {
        guard arguments.count >= 2 else {
            return .scan(ScanOptions(path: "."))
        }

        let commandName = arguments[1]
        let flags = Array(arguments.dropFirst(2))
        return try parse(commandName: commandName, flags: flags)
    }

    static func helpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Commands:
          swiftlens scan [PATH] [--config PATH] [--format json] [--baseline PATH] [--path PATH] [--verbose]
          swiftlens baseline create [--config PATH] [--output PATH] [--path PATH] [--verbose]
          swiftlens validate-config [--config PATH]
          swiftlens init [--preset NAME] [--force]
          swiftlens preset list
          swiftlens preset explain <PRESET>
          swiftlens rule explain <RULE-ID>
          swiftlens version
          swiftlens help

        Flags:
          --config PATH
          --format json
          --baseline PATH
          --path PATH
          --verbose

        Init flags:
          --preset NAME
          --force
        """
            + "\n"
    }

    static func initHelpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens init [--preset NAME] [--force]

        Flags:
          --preset NAME
          --force
        """
            + "\n"
    }

    private static func parse(commandName: String, flags: [String]) throws -> CLICommand {
        switch commandName {
        case "help", "-h", "--help":
            return .help
        case "version", "--version":
            return .version
        case "validate-config":
            return .validateConfig(ValidationOptions(configPath: try parseConfigPath(flags)))
        case "scan":
            return .scan(try parseScanOptions(flags))
        case "baseline":
            if let command = try BaselineCLI.parse(commandName: commandName, flags: flags) {
                return command
            }
            throw SwiftLensError.usage("Unknown command `\(commandName)`.")
        case "init":
            return .initCommand(try parseInitOptions(flags))
        case "preset", "rule":
            if let command = try ExplainabilityCLI.parse(commandName: commandName, flags: flags) {
                return command
            }
            throw SwiftLensError.usage("Unknown command `\(commandName)`.")
        default:
            throw SwiftLensError.usage("Unknown command `\(commandName)`.")
        }
    }

    private static func parseScanOptions(_ arguments: [String]) throws -> ScanOptions {
        var options = ScanOptions(path: nil)
        var positionalPath: String?
        var state = ScanOptionState()
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            try applyScanArgument(
                argument,
                options: &options,
                state: &state,
                positionalPath: &positionalPath,
                iterator: &iterator
            )
        }

        return try finishScanOptions(
            options: &options,
            state: state,
            positionalPath: positionalPath
        )
    }

    private static func parseInitOptions(_ arguments: [String]) throws -> InitOptions {
        var options = InitOptions()
        var presetSpecified = false
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--help", "-h":
                options.showHelp = true
            case "--preset":
                try consumeUniqueValue(
                    for: "--preset",
                    into: &options.presetID,
                    seen: &presetSpecified,
                    iterator: &iterator
                )
            case "--force":
                options.force = true
            default:
                throw SwiftLensError.usage("Unknown flag `\(argument)`.")
            }
        }

        return options
    }

    private static func applyScanArgument<T: IteratorProtocol>(
        _ argument: String,
        options: inout ScanOptions,
        state: inout ScanOptionState,
        positionalPath: inout String?,
        iterator: inout T
    ) throws where T.Element == String {
        switch argument {
        case "--config":
            try consumeUniqueValue(
                for: "--config",
                into: &options.configPath,
                seen: &state.configSpecified,
                iterator: &iterator
            )
        case "--format":
            try consumeUniqueValue(
                for: "--format",
                into: &state.formatValue,
                seen: &state.formatSpecified,
                iterator: &iterator
            )
        case "--path":
            try consumeUniqueValue(
                for: "--path",
                into: &options.path,
                seen: &state.pathSpecified,
                iterator: &iterator
            )
        case "--baseline":
            try consumeUniqueValue(
                for: "--baseline",
                into: &options.baselinePath,
                seen: &state.baselineSpecified,
                iterator: &iterator
            )
        case "--verbose":
            options.verbose = true
        default:
            try handlePositionalArgument(argument, positionalPath: &positionalPath)
        }
    }

    private static func finishScanOptions(
        options: inout ScanOptions,
        state: ScanOptionState,
        positionalPath: String?
    ) throws -> ScanOptions {
        if !state.pathSpecified {
            options.path = positionalPath ?? (options.configPath == nil ? "." : nil)
        }

        if let formatValue = state.formatValue {
            options.format = formatValue
        }

        if options.format != "json" {
            throw SwiftLensError.usage("Only `--format json` is supported in Phase 1.")
        }

        return options
    }

    private static func parseConfigPath(_ flags: [String]) throws -> String? {
        var iterator = flags.makeIterator()
        var configPath: String?
        while let flag = iterator.next() {
            switch flag {
            case "--config":
                guard let value = iterator.next() else {
                    throw SwiftLensError.usage("Missing value for `--config`.")
                }
                if configPath != nil {
                    throw SwiftLensError.usage("Duplicate flag `--config`.")
                }
                configPath = value
            default:
                throw SwiftLensError.usage("Unknown flag `\(flag)`.")
            }
        }
        return configPath
    }

    private static func consumeUniqueValue<T: IteratorProtocol>(
        for flag: String,
        into storage: inout String?,
        seen: inout Bool,
        iterator: inout T
    ) throws where T.Element == String {
        guard let value = iterator.next() else {
            throw SwiftLensError.usage("Missing value for `\(flag)`.")
        }
        guard !seen else {
            throw SwiftLensError.usage("Duplicate flag `\(flag)`.")
        }
        seen = true
        storage = value
    }

    private static func handlePositionalArgument(
        _ argument: String,
        positionalPath: inout String?
    ) throws {
        if argument.hasPrefix("-") {
            throw SwiftLensError.usage("Unknown flag `\(argument)`.")
        }
        if positionalPath != nil {
            throw SwiftLensError.usage("Unexpected argument `\(argument)`.")
        }
        positionalPath = argument
    }

    private struct ScanOptionState {
        var configSpecified = false
        var formatSpecified = false
        var baselineSpecified = false
        var formatValue: String?
        var pathSpecified = false
    }
}
