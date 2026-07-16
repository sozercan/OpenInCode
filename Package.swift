// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpenInCode",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(
            name: "OpenInCode",
            targets: ["OpenInCode"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "OpenInCode",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "OpenInCodeTests",
            dependencies: ["OpenInCode"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
