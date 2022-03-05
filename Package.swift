// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Acheron",
    platforms: [
        .iOS(.v11), .macOS(.v10_13)
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
