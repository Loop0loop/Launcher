// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Launch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Launch", targets: ["Launch"]),
        .library(name: "LaunchCore", targets: ["LaunchCore"])
    ],
    targets: [
        .target(name: "LaunchCore"),
        .executableTarget(name: "Launch", dependencies: ["LaunchCore"]),
        .executableTarget(name: "LaunchCheck", dependencies: ["LaunchCore"])
    ]
)
