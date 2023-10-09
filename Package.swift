// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Acheron",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .macCatalyst(.v13)
    ],
    products: [
        .library(name: "Acheron", targets: ["Acheron"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Acheron", dependencies: []),
    ]
)
