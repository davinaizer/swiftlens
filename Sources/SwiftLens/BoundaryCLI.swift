import Foundation

enum BoundaryCLI {
    static func execute(_ command: BoundaryCLICommand, fileManager: FileManager = .default)
        -> CLIExecutionResult {
        switch command {
        case .help:
            return CLIExecutionResult(exitCode: 0, stdout: helpText(), stderr: "")
        case .list(let options):
            if options.showHelp {
                return CLIExecutionResult(exitCode: 0, stdout: helpText(), stderr: "")
            }
            do {
                let loadedConfiguration = try ConfigLoader(fileManager: fileManager).load(
                    configPath: options.configPath,
                    projectPathOverride: nil,
                    validateProjectRoot: false
                )
                let report = try BoundaryInspector().inspect(loadedConfiguration)
                return CLIExecutionResult(
                    exitCode: 0,
                    stdout: BoundaryRenderer.render(report),
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
        guard commandName == "boundary" else {
            return nil
        }

        return .boundary(try parseBoundaryCommand(flags))
    }

    static func helpText() -> String {
        """
        SwiftLens \(SwiftLensVersion.current)

        Usage:
          swiftlens boundary list [--config PATH]

        Commands:
          swiftlens boundary list
        """
            + "\n"
    }

    private static func parseBoundaryCommand(_ arguments: [String]) throws -> BoundaryCLICommand {
        var iterator = arguments.makeIterator()
        guard let subcommand = iterator.next() else {
            return .help
        }

        switch subcommand {
        case "help", "-h", "--help":
            try ensureNoExtraArguments(iterator: &iterator, subject: "`swiftlens boundary`")
            return .help
        case "list":
            return .list(try parseBoundaryListOptions(Array(iterator)))
        default:
            throw SwiftLensError.usage("Unknown subcommand `\(subcommand)` for `boundary`.")
        }
    }

    private static func parseBoundaryListOptions(_ arguments: [String]) throws -> BoundaryListOptions {
        var options = BoundaryListOptions()
        var configSpecified = false
        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--help", "-h":
                return BoundaryListOptions(configPath: nil, showHelp: true)
            case "--config":
                try consumeUniqueValue(
                    for: "--config",
                    into: &options.configPath,
                    seen: &configSpecified,
                    iterator: &iterator
                )
            default:
                throw SwiftLensError.usage("Unknown flag `\(argument)`.")
            }
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
}

struct BoundaryListOptions: Equatable, Sendable {
    var configPath: String?
    var showHelp: Bool = false
}

enum BoundaryCLICommand {
    case help
    case list(BoundaryListOptions)
}
