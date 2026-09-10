// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GenieAgentCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "GenieAgentCore", targets: ["GenieAgentCore"])],
    targets: [
        .target(name: "GenieAgentCore"),
        .testTarget(name: "GenieAgentCoreTests", dependencies: ["GenieAgentCore"])
    ],
    swiftLanguageModes: [.v5]
)
