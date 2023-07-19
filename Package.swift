// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "SwiftEva",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Eva", targets: ["Eva"]),
    ],
    targets: [
        .target(name: "Eva"),
        .testTarget(
            name: "EvaTests",
            dependencies: ["Eva"]
        )
    ]
)
