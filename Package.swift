// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftLens",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "SwiftLens", targets: ["SwiftLens"]),
    ],
    targets: [
        .executableTarget(name: "SwiftLens"),
    ]
)
