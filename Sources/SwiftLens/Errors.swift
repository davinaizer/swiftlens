import Foundation

enum SwiftLensError: Error, Equatable {
    case usage(String)
    case configuration(String)
    case internalFailure(String)

    var exitCode: Int32 {
        switch self {
        case .usage, .configuration:
            return 2
        case .internalFailure:
            return 3
        }
    }

    var message: String {
        switch self {
        case .usage(let message):
            return "Usage error: \(message)"
        case .configuration(let message):
            return "Configuration error: \(message)"
        case .internalFailure(let message):
            return "Internal failure: \(message)"
        }
    }
}
