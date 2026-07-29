// swift-tools-version:6.1

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
    traits: ["Weave"],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(name: "AcheronMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        .target(name: "Acheron", dependencies: [
            .target(name: "AcheronMacros", condition: .when(traits: ["Weave"]))
        ]),
        .testTarget(name: "AcheronTests", dependencies: ["Acheron"]),
    ],
    swiftLanguageModes: [.v5]
)
