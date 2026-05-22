import Foundation

enum SwiftLensCLI {
    static func execute(arguments: [String], fileManager: FileManager = .default) -> CLIExecutionResult {
        do {
            let command = try parse(arguments: arguments)
            switch command {
            case .help:
                return CLIExecutionResult(exitCode: 0, stdout: helpText(), stderr: "")
            case .version:
                return CLIExecutionResult(exitCode: 0, stdout: "SwiftLens \(SwiftLensVersion.current)\n", stderr: "")
            case .validateConfig(let options):
                try ScanEngine(fileManager: fileManager).validateConfig(options: options)
                return CLIExecutionResult(exitCode: 0, stdout: "Configuration valid.\n", stderr: "")
            case .scan(let options):
                let report = try ScanEngine(fileManager: fileManager).scan(options: options)
                let stdout = try JSONReporter().render(report)
                let exitCode: Int32 = report.summary.violations > 0 ? 1 : 0
                return CLIExecutionResult(exitCode: exitCode, stdout: stdout, stderr: "")
            }
        } catch let error as SwiftLensError {
            return CLIExecutionResult(exitCode: error.exitCode, stdout: "", stderr: error.message + "\n")
        } catch {
            return CLIExecutionResult(exitCode: 3, stdout: "", stderr: "Internal failure: \(error.localizedDescription)\n")
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
        default:
            throw SwiftLensError.usage("Unknown command `\(commandName)`.")
        }
    }

    private static func parseScanOptions(_ flags: [String]) throws -> ScanOptions {
        var options = ScanOptions(path: ".")
        var iterator = flags.makeIterator()
        while let flag = iterator.next() {
            switch flag {
            case "--config":
                guard let value = iterator.next() else {
                    throw SwiftLensError.usage("Missing value for `--config`.")
                }
                options.configPath = value
            case "--format":
                guard let value = iterator.next() else {
                    throw SwiftLensError.usage("Missing value for `--format`.")
                }
                options.format = value
            case "--path":
                guard let value = iterator.next() else {
                    throw SwiftLensError.usage("Missing value for `--path`.")
                }
                options.path = value
            case "--verbose":
                options.verbose = true
            default:
                throw SwiftLensError.usage("Unknown flag `\(flag)`.")
            }
        }

        if options.configPath != nil, options.path == "." {
            options.path = nil
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

    private static func helpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Commands:
          swiftlens scan [--config PATH] [--format json] [--path PATH] [--verbose]
          swiftlens validate-config [--config PATH]
          swiftlens version
          swiftlens help

        Flags:
          --config PATH
          --format json
          --path PATH
          --verbose
        """
        + "\n"
    }
}

private enum CLICommand {
    case help
    case version
    case validateConfig(ValidationOptions)
    case scan(ScanOptions)
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
