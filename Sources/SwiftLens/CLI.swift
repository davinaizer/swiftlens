import Foundation

enum SwiftLensCLI {
    static func execute(arguments: [String], fileManager: FileManager = .default)
        -> CLIExecutionResult {
        do {
            let command = try parse(arguments: arguments)
            switch command {
            case .help:
                return CLIExecutionResult(exitCode: 0, stdout: helpText(), stderr: "")
            case .version:
                return CLIExecutionResult(
                    exitCode: 0, stdout: "SwiftLens \(SwiftLensVersion.current)\n", stderr: "")
            case .validateConfig(let options):
                try ScanEngine(fileManager: fileManager).validateConfig(options: options)
                return CLIExecutionResult(exitCode: 0, stdout: "Configuration valid.\n", stderr: "")
            case .scan(let options):
                let report = try ScanEngine(fileManager: fileManager).scan(options: options)
                let stdout = try JSONReporter().render(report)
                let exitCode: Int32 = report.summary.violations > 0 ? 1 : 0
                return CLIExecutionResult(exitCode: exitCode, stdout: stdout, stderr: "")
            case .initCommand(let options):
                if options.showHelp {
                    return CLIExecutionResult(exitCode: 0, stdout: initHelpText(), stderr: "")
                }

                let output = try ConfigInitializer(fileManager: fileManager).initialize(
                    options: options
                )
                return CLIExecutionResult(exitCode: 0, stdout: output, stderr: "")
            }
        } catch let error as SwiftLensError {
            return CLIExecutionResult(
                exitCode: error.exitCode, stdout: "", stderr: error.message + "\n")
        } catch {
            return CLIExecutionResult(
                exitCode: 3, stdout: "", stderr: "Internal failure: \(error.localizedDescription)\n"
            )
        }
    }

    private static func parse(arguments: [String]) throws -> CLICommand {
        guard arguments.count >= 2 else {
            return .scan(ScanOptions(path: "."))
        }

        let commandName = arguments[1]
        let flags = Array(arguments.dropFirst(2))

        switch commandName {
        case "help", "-h", "--help":
            return .help
        case "version", "--version":
            return .version
        case "validate-config":
            return .validateConfig(ValidationOptions(configPath: try parseConfigPath(flags)))
        case "scan":
            return .scan(try parseScanOptions(flags))
        case "init":
            return .initCommand(try parseInitOptions(flags))
        default:
            throw SwiftLensError.usage("Unknown command `\(commandName)`.")
        }
    }

    private static func parseScanOptions(_ arguments: [String]) throws -> ScanOptions {
        var options = ScanOptions(path: nil)
        var positionalPath: String?
        var configSpecified = false
        var formatSpecified = false
        var formatValue: String?
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
            case "--format":
                try consumeUniqueValue(
                    for: "--format",
                    into: &formatValue,
                    seen: &formatSpecified,
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

        if let formatValue {
            options.format = formatValue
        }

        if options.format != "json" {
            throw SwiftLensError.usage("Only `--format json` is supported in Phase 1.")
        }

        return options
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

    private static func helpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Commands:
          swiftlens scan [PATH] [--config PATH] [--format json] [--path PATH] [--verbose]
          swiftlens validate-config [--config PATH]
          swiftlens init [--preset NAME] [--force]
          swiftlens version
          swiftlens help

        Flags:
          --config PATH
          --format json
          --path PATH
          --verbose

        Init flags:
          --preset NAME
          --force
        """
            + "\n"
    }

    private static func initHelpText() -> String {
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
}

private enum CLICommand {
    case help
    case version
    case validateConfig(ValidationOptions)
    case scan(ScanOptions)
    case initCommand(InitOptions)
}

@main
struct SwiftLensMain {
    static func main() {
        let result = SwiftLensCLI.execute(arguments: CommandLine.arguments)
        if !result.stdout.isEmpty {
            FileHandle.standardOutput.write(Data(result.stdout.utf8))
        }
        if !result.stderr.isEmpty {
            FileHandle.standardError.write(Data(result.stderr.utf8))
        }
        exit(result.exitCode)
    }
}
