// swift-tools-version: 6.4
import PackageDescription
import Foundation

// Mirrors the root Genie package's flavour switch — see AgentRuntime/Package.swift
// for why a local path dependency has to read the flag again instead of
// inheriting the root target's `-DGENIE_MAS`.
let isMASBuild = ProcessInfo.processInfo.environment["GENIE_MAS"] == "1"
let flavourDefine: SwiftSetting = .define(isMASBuild ? "GENIE_MAS" : "GENIE_DEVELOPER_ID")

let package = Package(
    name: "GenieEnvironmentKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GenieEnvironmentKit", targets: ["GenieEnvironmentKit"]),
        .executable(name: "genie-env", targets: ["genie-env"])
    ],
    targets: [
        // The Linux guest payload (install.sh, worker.py, client.py) only ever runs
        // inside a UTM VM, which the sandbox cannot reach — so Genie Lite ships
        // without it rather than carrying shell scripts App Review would rightly
        // ask about. `UTMBackend.guestFiles()` already reports its absence as a
        // fixable error instead of trapping.
        .target(name: "GenieEnvironmentKit",
                resources: isMASBuild ? [] : [.copy("Guest")],
                swiftSettings: [flavourDefine]),
        .executableTarget(name: "genie-env", dependencies: ["GenieEnvironmentKit"], swiftSettings: [flavourDefine]),
        .testTarget(name: "GenieEnvironmentKitTests", dependencies: ["GenieEnvironmentKit"], swiftSettings: [flavourDefine])
    ],
    swiftLanguageModes: [.v5]
)
