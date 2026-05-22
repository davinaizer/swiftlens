import Foundation

struct ConfigValueDecoder {
    func stringValue(_ value: YAMLValue?) -> String? {
        guard let value else {
            return nil
        }

        switch value {
        case .string(let string):
            return string
        case .bool(let bool):
            return bool ? "true" : "false"
        case .array, .mapping:
            return nil
        }
    }

    func boolValue(_ value: YAMLValue?) -> Bool? {
        guard let value else {
            return nil
        }

        switch value {
        case .bool(let bool):
            return bool
        case .string(let string):
            if string == "true" {
                return true
            }
            if string == "false" {
                return false
            }
            return nil
        case .array, .mapping:
            return nil
        }
    }

    func severityValue(_ value: YAMLValue?, field: String? = nil) throws -> Severity? {
        guard let value else {
            return nil
        }

        switch value {
        case .string(let string):
            guard let severity = Severity(rawValue: string) else {
                if let field {
                    throw SwiftLensError.configuration(
                        "\(field) must be `advisory`, `warning`, or `error`."
                    )
                }
                return nil
            }
            return severity
        case .bool, .array, .mapping:
            if let field {
                throw SwiftLensError.configuration(
                    "\(field) must be `advisory`, `warning`, or `error`."
                )
            }
            return nil
        }
    }

    func stringArrayValue(_ value: YAMLValue?, field: String) throws -> [String] {
        guard let value else {
            return []
        }

        guard case .array(let items) = value else {
            throw SwiftLensError.configuration("`\((field))` must be a list.")
        }

        var strings: [String] = []
        for item in items {
            switch item {
            case .string(let string):
                strings.append(string)
            case .bool, .array, .mapping:
                throw SwiftLensError.configuration("`\((field))` must contain only strings.")
            }
        }
        return strings
    }
}
