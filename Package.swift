// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ScriptMagic",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ScriptMagicCore",
            targets: ["ScriptMagicCore"]
        ),
        .executable(
            name: "ScriptMagic",
            targets: ["ScriptMagicApp"]
        )
    ],
    targets: [
        .target(
            name: "ScriptMagicCore"
        ),
        .executableTarget(
            name: "ScriptMagicApp",
            dependencies: ["ScriptMagicCore"]
        ),
        .testTarget(
            name: "ScriptMagicCoreTests",
            dependencies: ["ScriptMagicCore"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
