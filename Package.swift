// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RhythmCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "RhythmCore", targets: ["RhythmCore"])
    ],
    targets: [
        .target(
            name: "RhythmCore",
            path: "Sources/Rhythm",
            sources: [
                "RhythmModels.swift",
                "PlaybackQueue.swift",
                "LocalRecommendationEngine.swift"
            ]
        ),
        .testTarget(
            name: "RhythmCoreTests",
            dependencies: ["RhythmCore"],
            path: "Tests/RhythmCoreTests"
        )
    ]
)
