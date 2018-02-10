// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Mqtt",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Mqtt",
            targets: ["Mqtt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/sockets", from: "2.2.0")
    ],
    targets: [
        .target(
            name: "Mqtt",
            dependencies: ["Sockets"],
            exclude: ["Examples"]),
        .testTarget(
            name: "MqttTests",
            dependencies: ["Mqtt"]),
    ]
)
