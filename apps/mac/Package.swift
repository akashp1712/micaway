// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MicAway",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MicAway", targets: ["MicAwayApp"])
    ],
    targets: [
        .target(
            name: "MicAwayCore",
            path: "Sources/MicAwayCore"
        ),
        .executableTarget(
            name: "MicAwayApp",
            dependencies: ["MicAwayCore"],
            path: "Sources/MicAwayApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreMotion")
            ]
        ),
        .testTarget(
            name: "MicAwayCoreTests",
            dependencies: ["MicAwayCore"],
            path: "Tests/MicAwayCoreTests"
        )
    ]
)
