// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GenieEnvironmentKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GenieEnvironmentKit", targets: ["GenieEnvironmentKit"]),
        .executable(name: "genie-env", targets: ["genie-env"])
    ],
    targets: [
        .target(name: "GenieEnvironmentKit", resources: [.copy("Guest")]),
        .executableTarget(name: "genie-env", dependencies: ["GenieEnvironmentKit"]),
        .testTarget(name: "GenieEnvironmentKitTests", dependencies: ["GenieEnvironmentKit"])
    ],
    swiftLanguageModes: [.v5]
)
