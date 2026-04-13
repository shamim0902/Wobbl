// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Wobbl",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Wobbl",
            path: "Wobbl",
            linkerSettings: [
                .linkedFramework("SpriteKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
