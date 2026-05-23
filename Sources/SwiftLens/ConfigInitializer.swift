import Foundation

struct ConfigInitializer {
    private let fileManager: FileManager
    private let presetRegistry: PresetRegistry

    init(
        fileManager: FileManager = .default,
        presetRegistry: PresetRegistry = .default
    ) {
        self.fileManager = fileManager
        self.presetRegistry = presetRegistry
    }

    func initialize(options: InitOptions) throws -> String {
        let configURL = configURL()

        if fileManager.fileExists(atPath: configURL.path), !options.force {
            throw SwiftLensError.configuration(
                "Config file already exists at \(configURL.path). Use --force to overwrite."
            )
        }

        let presetID = try resolvePresetID(options.presetID)

        let contents = ConfigInitRenderer.render(presetID: presetID)
        guard let data = contents.data(using: .utf8) else {
            throw SwiftLensError.internalFailure("Unable to encode init config.")
        }

        do {
            try data.write(to: configURL, options: [.atomic])
        } catch {
            throw SwiftLensError.internalFailure("Unable to write config at \(configURL.path).")
        }

        return "Wrote \(configURL.lastPathComponent) with preset \(presetID).\n"
    }

    private func resolvePresetID(_ presetID: String?) throws -> String {
        let resolvedPresetID: String
        if let presetID {
            let trimmedPresetID = presetID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPresetID.isEmpty else {
                throw SwiftLensError.configuration("`--preset` must not be empty.")
            }
            resolvedPresetID = trimmedPresetID
        } else {
            resolvedPresetID = "app-layers"
        }

        guard presetRegistry.descriptor(for: resolvedPresetID) != nil else {
            throw SwiftLensError.configuration("Unknown preset `\(resolvedPresetID)`.")
        }

        return resolvedPresetID
    }

    private func configURL() -> URL {
        URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent(".swiftlens.yml")
            .standardizedFileURL
    }
}

enum ConfigInitRenderer {
    static func render(presetID: String) -> String {
        [
            "version: 1",
            "preset: \(presetID)",
            "ignore:",
            "  paths:",
            "    - .build/",
            "    - .swiftpm/",
            "    - DerivedData/"
        ].joined(separator: "\n") + "\n"
    }
}
