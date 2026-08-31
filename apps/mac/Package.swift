// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "HearMeNot",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HearMeNot", targets: ["HearMeNotApp"])
    ],
    targets: [
        .target(
            name: "HearMeNotCore",
            path: "Sources/HearMeNotCore"
        ),
        .executableTarget(
            name: "HearMeNotApp",
            dependencies: ["HearMeNotCore"],
            path: "Sources/HearMeNotApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreMotion")
            ]
        ),
        .testTarget(
            name: "HearMeNotCoreTests",
            dependencies: ["HearMeNotCore"],
            path: "Tests/HearMeNotCoreTests"
        )
    ]
)
