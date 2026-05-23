import Foundation

enum SwiftLensCLI {
    static func execute(arguments: [String], fileManager: FileManager = .default)
        -> CLIExecutionResult {
        do {
            return try execute(command: parse(arguments: arguments), fileManager: fileManager)
        } catch let error as SwiftLensError {
            return CLIExecutionResult(
                exitCode: error.exitCode, stdout: "", stderr: error.message + "\n")
        } catch {
            return CLIExecutionResult(
                exitCode: 3, stdout: "", stderr: "Internal failure: \(error.localizedDescription)\n"
            )
        }
    }

    private static func execute(
        command: CLICommand,
        fileManager: FileManager
    ) throws -> CLIExecutionResult {
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
            return try executeScan(options: options, fileManager: fileManager)
        case .baseline(let baselineCommand):
            return BaselineCLI.execute(baselineCommand, fileManager: fileManager)
        case .initCommand(let options):
            return try executeInit(options: options, fileManager: fileManager)
        case .preset(let presetCommand):
            return ExplainabilityCLI.executePreset(presetCommand)
        case .pack(let packCommand):
            return ExplainabilityCLI.executePack(packCommand)
        case .rule(let ruleCommand):
            return ExplainabilityCLI.executeRule(ruleCommand)
        case .boundary(let boundaryCommand):
            return BoundaryCLI.execute(boundaryCommand, fileManager: fileManager)
        }
    }

    private static func executeScan(
        options: ScanOptions,
        fileManager: FileManager
    ) throws -> CLIExecutionResult {
        let report = try ScanEngine(fileManager: fileManager).scan(options: options)
        let stdout = try JSONReporter().render(report)
        let exitCode: Int32 = report.summary.violations > 0 ? 1 : 0
        return CLIExecutionResult(exitCode: exitCode, stdout: stdout, stderr: "")
    }

    private static func executeInit(
        options: InitOptions,
        fileManager: FileManager
    ) throws -> CLIExecutionResult {
        if options.showHelp {
            return CLIExecutionResult(exitCode: 0, stdout: SwiftLensCLIParsing.initHelpText(), stderr: "")
        }

        let output = try ConfigInitializer(fileManager: fileManager).initialize(options: options)
        return CLIExecutionResult(exitCode: 0, stdout: output, stderr: "")
    }

    private static func parse(arguments: [String]) throws -> CLICommand {
        try SwiftLensCLIParsing.parse(arguments: arguments)
    }

    private static func helpText() -> String {
        SwiftLensCLIParsing.helpText()
    }

    private static func initHelpText() -> String {
        SwiftLensCLIParsing.initHelpText()
    }
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
