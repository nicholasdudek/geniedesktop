// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Genie",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Genie",
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
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
