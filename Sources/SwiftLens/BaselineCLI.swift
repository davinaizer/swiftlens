import Foundation

enum BaselineCLI {
    static func execute(_ command: BaselineCLICommand, fileManager: FileManager = .default)
        -> CLIExecutionResult {
        switch command {
        case .help:
            return CLIExecutionResult(exitCode: 0, stdout: helpText(), stderr: "")
        case .create(let options):
            do {
                let scanReport = try ScanEngine(fileManager: fileManager).scan(
                    options: options.scanOptions()
                )
                let store = BaselineStore(fileManager: fileManager)
                let baseline = store.baseline(from: scanReport)
                try store.write(baseline, to: options.outputPath)
                return CLIExecutionResult(
                    exitCode: 0,
                    stdout: """
                    Created baseline:
                    \(options.outputPath)

                    Stored violations: \(scanReport.violations.count)
                    """ + "\n",
                    stderr: ""
                )
            } catch let error as SwiftLensError {
                return CLIExecutionResult(
                    exitCode: error.exitCode,
                    stdout: "",
                    stderr: error.message + "\n"
                )
            } catch {
                return CLIExecutionResult(
                    exitCode: 3,
                    stdout: "",
                    stderr: "Internal failure: \(error.localizedDescription)\n"
                )
            }
        }
    }

    static func parse(commandName: String, flags: [String]) throws -> CLICommand? {
        guard commandName == "baseline" else {
            return nil
        }

        return .baseline(try parseBaselineCommand(flags))
    }

    private static func parseBaselineCommand(_ arguments: [String]) throws -> BaselineCLICommand {
        var iterator = arguments.makeIterator()
        guard let subcommand = iterator.next() else {
            return .help
        }

        switch subcommand {
        case "help", "-h", "--help":
            try ensureNoExtraArguments(iterator: &iterator, subject: "`swiftlens baseline`")
            return .help
        case "create":
            return .create(try parseBaselineCreateOptions(Array(iterator)))
        default:
            throw SwiftLensError.usage("Unknown subcommand `\(subcommand)` for `baseline`.")
        }
    }

    private static func parseBaselineCreateOptions(_ arguments: [String]) throws
        -> BaselineCreateOptions {
        var options = BaselineCreateOptions()
        var positionalPath: String?
        var configSpecified = false
        var outputSpecified = false
        var outputPath: String?
        var pathSpecified = false
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--config":
                try consumeUniqueValue(
                    for: "--config",
                    into: &options.configPath,
                    seen: &configSpecified,
                    iterator: &iterator
                )
            case "--output":
                try consumeUniqueValue(
                    for: "--output",
                    into: &outputPath,
                    seen: &outputSpecified,
                    iterator: &iterator
                )
            case "--path":
                try consumeUniqueValue(
                    for: "--path",
                    into: &options.path,
                    seen: &pathSpecified,
                    iterator: &iterator
                )
            case "--verbose":
                options.verbose = true
            default:
                try handlePositionalArgument(argument, positionalPath: &positionalPath)
            }
        }

        if !pathSpecified {
            options.path = positionalPath ?? (options.configPath == nil ? "." : nil)
        }
        if let outputPath {
            options.outputPath = outputPath
        }

        return options
    }

    private static func ensureNoExtraArguments<T: IteratorProtocol>(
        iterator: inout T,
        subject: String
    ) throws where T.Element == String {
        if let extra = iterator.next() {
            throw SwiftLensError.usage("Unexpected argument `\(extra)` in \(subject).")
        }
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

    private static func helpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens baseline create [--config PATH] [--output PATH] [--path PATH] [--verbose]

        Commands:
          swiftlens baseline create
        """
            + "\n"
    }
}

enum BaselineCLICommand {
    case help
    case create(BaselineCreateOptions)
}
