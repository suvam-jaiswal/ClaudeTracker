// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeTracker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeTracker",
            targets: ["App"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["Core"],
            path: "Sources/App"
        ),
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
        .testTarget(
            name: "SessionStoreTests",
            dependencies: ["Core"],
            path: "Tests"
        )
    ]
)
