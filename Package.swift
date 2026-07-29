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
        .library(name: "AcheronLoom", targets: ["AcheronLoom"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(name: "Acheron"),
        .macro(name: "AcheronMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        .target(name: "AcheronLoom", dependencies: ["Acheron", "AcheronMacros"], exclude: ["LOOM.md"]),
        .testTarget(name: "AcheronTests", dependencies: ["Acheron", "AcheronLoom"]),
    ]
)
