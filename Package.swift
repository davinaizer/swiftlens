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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftLens",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SwiftLensTests",
            dependencies: ["SwiftLens"],
            exclude: ["Fixtures"]
        ),
    ]
)
