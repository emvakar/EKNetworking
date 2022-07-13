// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "EKNetworking", platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "EKNetworking", targets: ["EKNetworking"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
         .package(url: "https://github.com/emvakar/swift-log-telegram.git", from: "0.0.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "EKNetworking", dependencies: [
            "Moya",
            .product(name: "LoggingTelegram", package: "swift-log-telegram")
        ], path: "Sources/EKNetworking"),
    ]
)
