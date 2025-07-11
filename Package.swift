// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lync",
    platforms: [
        .iOS(.v12),
        .macCatalyst(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Lync",
            targets: ["Lync"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // No external dependencies required - we use only system frameworks
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "Lync",
            dependencies: [],
            path: "SDK/Sources/Lync"
        ),
        .testTarget(
            name: "LyncTests",
            dependencies: ["Lync"],
            path: "SDK/Tests/LyncTests"
        ),
    ]
) 