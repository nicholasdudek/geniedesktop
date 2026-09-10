// swift-tools-version: 6.4
import PackageDescription
import Foundation

// Genie ships two builds from this one package:
//
//   swift build -c release                  → Developer ID (full)
//   GENIE_MAS=1 swift build -c release      → Genie Lite (Mac App Store)
//
// The flag drives GenieCapabilities, which gates every subsystem the sandbox
// or the App Store Review Guidelines forbid. Keep the two flavours in separate
// build directories — the compiled define differs, and SwiftPM will happily
// hand you a stale binary from the other flavour otherwise. The packaging
// scripts pass --scratch-path for exactly that reason.
let isMASBuild = ProcessInfo.processInfo.environment["GENIE_MAS"] == "1"

let package = Package(
    name: "Genie",
    platforms: [.macOS("27.0")],
    dependencies: [.package(path: "AgentRuntime"), .package(path: "EnvironmentKit")],
    targets: [
        .target(
            name: "GenieFinderSyncShared",
            path: "Sources/GenieFinderSyncShared"
        ),
        // Not a real .appex — SwiftPM can't emit the MH_BUNDLE Mach-O type
        // Finder Sync extensions require. This target exists so the
        // extension's source compiles and type-checks with `swift build`.
        // To actually ship it, add an Xcode "Finder Sync Extension" target
        // and add GenieFinderSync.swift + Info.plist + entitlements to it.
        .target(
            name: "GenieFinderSync",
            dependencies: ["GenieFinderSyncShared"],
            path: "Sources/GenieFinderSync",
            exclude: [
                "Info.plist",
                "GenieFinderSync.entitlements"
            ],
            linkerSettings: [.linkedFramework("FinderSync")]
        ),
        // Not a real .appex — SwiftPM can't emit the MH_BUNDLE Mach-O type
        // WidgetKit extensions require. This target exists so the
        // extension's source compiles and type-checks with `swift build`.
        // To actually ship it, add an Xcode "Widget Extension" target
        // and add GenieWidgets.swift + Info.plist + entitlements to it.
        .target(
            name: "GenieWidgets",
            dependencies: ["GenieFinderSyncShared"],
            path: "Sources/GenieWidgets",
            exclude: [
                "Info.plist",
                "GenieWidgets.entitlements"
            ],
            linkerSettings: [.linkedFramework("WidgetKit")]
        ),
        .executableTarget(
            name: "Genie",
            dependencies: [
                .product(name: "GenieAgentCore", package: "AgentRuntime"),
                .product(name: "GenieEnvironmentKit", package: "EnvironmentKit"),
                "GenieFinderSyncShared"
            ],
            path: "Sources/GoldGate",
            exclude: [
                "Info.plist", 
                "Genie.entitlements", 
                "Genie.AppStore.entitlements", 
                "AppIcon.icns", 
                "HeaderBadge.jpg", 
                "HeaderBadge.png", 
                "NanoEmblem.jpg", 
                "GenieDynamic_Thumbnail.png", 
                "GoldenGateDynamic_Thumbnail.png", 
                "Assets.xcassets",
                "Helpers/README.md",
                "Models/README.md",
                "Views/README.md"
            ],
            swiftSettings: [
                .define(isMASBuild ? "GENIE_MAS" : "GENIE_DEVELOPER_ID")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
