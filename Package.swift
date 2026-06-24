// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MicCamPrivacyManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MicCamPrivacyManager", targets: ["MicCamPrivacyManager"])
    ],
    targets: [
        .executableTarget(
            name: "MicCamPrivacyManager",
            path: "Sources/MicCamPrivacyManager",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        )
    ]
)
