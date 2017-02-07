import PackageDescription

let package = Package(
    name: "Mqtt",
    targets: [
        Target(name: "Mqtt")
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/socks", majorVersion: 1, minor: 2)
    ],
    exclude: [
        "Examples"
    ]
)
