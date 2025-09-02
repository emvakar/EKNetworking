// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "EKNetworking", platforms: [.iOS(.v15), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "EKNetworking", targets: ["EKNetworking"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
         .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
         .package(url: "https://github.com/emvakar/Pulse.git", .branch("main")),
         .package(url: "https://github.com/emvakar/PulseLogHandler.git", .branch("main")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "EKNetworking", dependencies: [
            .product(name: "Moya", package: "Moya"),
            .product(name: "Pulse", package: "Pulse"),
            .product(name: "PulseUI", package: "Pulse"),
            .product(name: "PulseLogHandler", package: "PulseLogHandler"),
            .product(name: "Logging", package: "swift-log"),
        ], path: "Sources/EKNetworking"),
//        .target(name: "Pulse"),
//        .target(name: "PulseUI", dependencies: ["Pulse"]),
    ]
)
