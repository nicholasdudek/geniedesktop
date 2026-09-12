// swift-tools-version: 6.4
import PackageDescription
import Foundation

// Mirrors the root Genie package's flavour switch.
//
// SwiftPM does not propagate a target's `.define` into its dependencies, so the
// root package's `-DGENIE_MAS` never reached GenieAgentCore. Without this, the
// agent's Process()-based tools (`/usr/bin/sdef`, `/usr/bin/open`,
// `/usr/bin/diff3`) compiled into the sandboxed App Store build, where spawning
// a binary outside the app bundle cannot work and Guideline 2.5.1 forbids it.
// Keep the two flavours in separate scratch paths — see the root Package.swift.
let isMASBuild = ProcessInfo.processInfo.environment["GENIE_MAS"] == "1"
let flavourDefine: SwiftSetting = .define(isMASBuild ? "GENIE_MAS" : "GENIE_DEVELOPER_ID")

let package = Package(
    name: "GenieAgentCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "GenieAgentCore", targets: ["GenieAgentCore"])],
    targets: [
        .target(name: "GenieAgentCore", swiftSettings: [flavourDefine]),
        .testTarget(name: "GenieAgentCoreTests", dependencies: ["GenieAgentCore"], swiftSettings: [flavourDefine])
    ],
    swiftLanguageModes: [.v5]
)
