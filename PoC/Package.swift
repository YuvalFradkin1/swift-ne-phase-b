// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "PoC",
    platforms: [.macOS(.v15)],
    dependencies: [
        // Pre-fix commit — before 558eb3e guard
        .package(
            url: "https://github.com/apple/swift-network-evolution.git",
            revision: "d6a5305ea4c1eb4b96ee83e428dc6d73da23e3e4"
        ),
    ],
    targets: [
        .executableTarget(
            name: "PoC",
            dependencies: [
                .product(name: "SwiftNetwork", package: "swift-network-evolution"),
            ]
        )
    ]
)
