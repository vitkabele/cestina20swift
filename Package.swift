// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cestina20Swift",
    platforms: [
        .macOS(.v12),
        .iOS(.v13)
    ],
    products: [
        // Main product of this package is the library
        .library(
            name: "Cestina20Swift",
            targets: ["Cestina20Swift"]),
        // The package also provides CLI utility to demonstrate the library functionality
        .executable(name: "Cestina20Cli",
                    targets: ["Cestina20Cli"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.5.3"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Cestina20Swift",
            dependencies: ["SwiftSoup"]),
        .executableTarget(name: "Cestina20Cli",
            dependencies: [
                "Cestina20Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "Cestina20SwiftTests",
            dependencies: ["Cestina20Swift"]),
    ]
)
