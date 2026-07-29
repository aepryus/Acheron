// swift-tools-version:5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Acheron",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .macCatalyst(.v13)
    ],
    products: [
        .library(name: "Acheron", targets: ["Acheron"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(name: "AcheronMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        .target(name: "Acheron", dependencies: ["AcheronMacros"]),
        .testTarget(name: "AcheronTests", dependencies: ["Acheron"]),
    ]
)
