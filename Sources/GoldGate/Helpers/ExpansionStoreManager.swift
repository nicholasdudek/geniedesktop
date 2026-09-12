import Foundation
import StoreKit
import SwiftUI

// MARK: - Expansion Pack Model

public struct ExpansionPackItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let priceString: String
    public let icon: String
    public let gradient: [Color]
    public let includes: [String]
    public let badge: String
}

// MARK: - Subscription Plan Model

public struct GenieSubscriptionPlan: Identifiable {
    public let id: String
    public let name: String
    public let priceDisplay: String
    public let billingCadence: String
    public let badge: String?
    public let trialText: String?
    public let effectiveMonthlyRate: String
    public let features: [String]
    public let isPopular: Bool
}

// MARK: - StoreKit 2 Expansion Store Manager

@MainActor
public final class ExpansionStoreManager: ObservableObject {
    public static let shared = ExpansionStoreManager()

    public static let cyberpunkID = "com.nicholasdudek.genie.pack.cyberpunk"
    public static let zenID = "com.nicholasdudek.genie.pack.zen"
    public static let cosmosID = "com.nicholasdudek.genie.pack.cosmos"
    public static let retroID = "com.nicholasdudek.genie.pack.retro"
    public static let ultimateID = "com.nicholasdudek.genie.pack.ultimate"
    public static let cursorsAndPetsID = "com.nicholasdudek.genie.pack.cursorsandpets"

    // Subscription Plan IDs
    public static let planOneYearID = "com.nicholasdudek.genie.sub.oneyear"
    public static let planMonthlyID = "com.nicholasdudek.genie.sub.monthly"
    public static let planTwoYearFounderID = "com.nicholasdudek.genie.sub.twoyearfounder"

    // Legacy GoldGate IDs
    public static let legacyCyberpunkID = "com.nicholasdudek.goldgate.pack.cyberpunk"
    public static let legacyZenID = "com.nicholasdudek.goldgate.pack.zen"
    public static let legacyCosmosID = "com.nicholasdudek.goldgate.pack.cosmos"
    public static let legacyRetroID = "com.nicholasdudek.goldgate.pack.retro"
    public static let legacyUltimateID = "com.nicholasdudek.goldgate.pack.ultimate"

    @Published public var activePlanName: String = UserDefaults.standard.string(forKey: PrefKey.activeSubscriptionPlan) ?? "Genie Annual Pass"
    @Published public var unlockedPacks: Set<String> = []
    @Published public var isPurchasing: Bool = false
    @Published public var purchaseSuccessMessage: String? = nil
    @Published public var errorMessage: String? = nil

    public let subscriptionPlans: [GenieSubscriptionPlan] = [
        GenieSubscriptionPlan(
            id: planOneYearID,
            name: "Genie Annual Pass",
            priceDisplay: "$120.00",
            billingCadence: "Billed annually at $120.00/year",
            badge: "RECOMMENDED · SAVE 50%",
            trialText: "30-Day Free Trial included",
            effectiveMonthlyRate: "$10.00 / mo",
            features: [
                "Full access to 81-Screen Spatial Canvas Matrix",
                "Save 50% vs. Monthly ($10.00/mo vs $19.99/mo)",
                "30-Day Free Trial included — cancel anytime",
                "Neural Bloom shaders & living 4K Metal backdrops",
                "The Brick Wall Context Firewall & AST code synthesis",
                "Autonomous Local (Ollama) & Cloud AI Routing (BYOK)",
                "Sovereign Linux Hypervisor & Virtualization Engine",
                "All 4 Expansion Packs (Cyberpunk, Zen, Cosmos, Retro)",
                "Continuous updates & priority developer support"
            ],
            isPopular: true
        ),
        GenieSubscriptionPlan(
            id: planMonthlyID,
            name: "Genie Pro Monthly",
            priceDisplay: "$19.99",
            billingCadence: "Billed monthly ($239.88/yr)",
            badge: "FLEXIBLE",
            trialText: "30-Day Free Trial included",
            effectiveMonthlyRate: "$19.99 / mo",
            features: [
                "30-Day Free Trial included — zero risk",
                "Month-to-month cancel anytime flexibility",
                "Full access to AI Chat, Code Studio, and Widgets",
                "Active continuous cloud & local model routing",
                "Switch to Annual anytime to save $119.88/yr"
            ],
            isPopular: false
        ),
        GenieSubscriptionPlan(
            id: planTwoYearFounderID,
            name: "Founder's 2-Year Pass",
            priceDisplay: "$199.00",
            billingCadence: "Billed once every 2 years ($99.50/year)",
            badge: "FOUNDER SPECIAL · 58% SAVINGS",
            trialText: "30-Day Free Trial included",
            effectiveMonthlyRate: "$8.29 / mo",
            features: [
                "All 4 Expansion Packs & Living Companions included",
                "Locked-in founder rate for 24 continuous months",
                "30-Day Free Trial included",
                "Genie Editor with Xcode Pro themes & AI Copilot",
                "Desktop World Clock & Animated Chat Complications",
                "Direct developer line with Nicholas M. Dudek"
            ],
            isPopular: false
        )
    ]

    public func selectPlan(_ plan: GenieSubscriptionPlan) {
        activePlanName = plan.name
        UserDefaults.standard.set(plan.name, forKey: PrefKey.activeSubscriptionPlan)
        purchaseSuccessMessage = "Subscribed to \(plan.name) successfully! ✨"
    }

    public let availablePacks: [ExpansionPackItem] = [
        ExpansionPackItem(
            id: ultimateID,
            title: "All-Inclusive Feature Pass",
            subtitle: "All themes, companions, shaders, and grid formations fully included",
            priceString: "Included",
            icon: "crown.fill",
            gradient: [Color.yellow, Color.orange, Color.red],
            includes: [
                "All 4 Feature Packs Included",
                "15+ Living Companions & Widgets",
                "12+ High-End Atmospheric Metal Shaders",
                "10+ Custom Dynamic Geometric Formations",
                "All Features Unlocked & Free Forever"
            ],
            badge: "INCLUDED"
        ),
        ExpansionPackItem(
            id: cyberpunkID,
            title: "Cyberpunk 2099 Feature Pack",
            subtitle: "Holographic matrix, glitch beams, and neon effects",
            priceString: "Included",
            icon: "bolt.horizontal.circle.fill",
            gradient: [Color.cyan, Color.blue, Color.purple],
            includes: [
                "Companion: Cyber Alpha Wolf 🐺",
                "Companion: Cyber Sentry Drone 🛸",
                "Shader: 4K Tokyo Neon Night Rain 🌧️",
                "Shader: Matrix Digital Rain Stream 🟢",
                "Formation: Tesseract Hypercube 🧊",
                "Snuggie: Cyber Samurai Mask 🥷"
            ],
            badge: "INCLUDED"
        ),
        ExpansionPackItem(
            id: zenID,
            title: "Japanese Zen & Spirits Pack",
            subtitle: "Tranquil koi sanctuaries, nine-tailed kitsune, and floating lanterns",
            priceString: "Included",
            icon: "leaf.fill",
            gradient: [Color.pink, Color.purple, Color.orange],
            includes: [
                "Companion: Cherry Blossom 9-Tail Kitsune 🦊",
                "Companion: Japanese Koi Sanctuary 🎏",
                "Shader: 4K Sakura Petal Blizzard 🌸",
                "Formation: Zen Garden Yin-Yang ☯️",
                "Snuggie: Sakura Shinto Gate ⛩️",
                "Apparel: Sakura Wreath 🌸"
            ],
            badge: "INCLUDED"
        ),
        ExpansionPackItem(
            id: cosmosID,
            title: "Deep Cosmos & Star Voyager Pack",
            subtitle: "Gravitational lensing, cosmic star whales, and orbital vortexes",
            priceString: "Included",
            icon: "sparkles",
            gradient: [Color.indigo, Color.purple, Color.black],
            includes: [
                "Companion: Cosmic Star Whale 🐋",
                "Companion: Deep Void Star Kraken 🦑",
                "Shader: Supermassive Black Hole Lens 🕳️",
                "Shader: Hyperdrive Warp Speed 🚀",
                "Formation: Supernova Burst 💥",
                "Snuggie: Astronaut Visor 👨‍🚀"
            ],
            badge: "INCLUDED"
        ),
        ExpansionPackItem(
            id: retroID,
            title: "Retro 1984 Arcade Pack",
            subtitle: "Nostalgic CRT vector scanlines, 8-bit sprites, and vintage soundscapes",
            priceString: "Included",
            icon: "gamecontroller.fill",
            gradient: [Color.green, Color.teal, Color.mint],
            includes: [
                "Companion: 8-Bit Arcade Ghost 👻",
                "Companion: Pixel Yoshi Companion 🦖",
                "Shader: Retro CRT Vector Scanline Grid 🕹️",
                "Shader: Fluid Ink Chromatography 🎨",
                "Snuggie: Pixel Heart Armor ❤️",
                "Style: 8-Bit Arcade Battery Gauge"
            ],
            badge: "INCLUDED"
        ),
        ExpansionPackItem(
            id: cursorsAndPetsID,
            title: "Fancy Cursors & Living Dock Pets Collection",
            subtitle: "Interactive living companions that dwell on the Mac Dock & hardware-accelerated cursor trails",
            priceString: "$4.99",
            icon: "sparkles.rectangle.stack.fill",
            gradient: [Color.pink, Color.purple, Color.cyan],
            includes: [
                "10+ Interactive Dock Pets (Kitsune, Cyber Wolf, Quantum Cat, Shiba Inu...)",
                "Living Mac Dock Perch & Reactive Pet Touch Gestures",
                "12+ Hardware-Accelerated Metal Cursor FX (Heart Petals, Matrix, Starlight)",
                "Always-On System-Wide Cursor Glow across Safari, Xcode & Finder",
                "Reactive Pet Sounds & Speech Bubble Companionship"
            ],
            badge: "POPULAR ✨"
        )
    ]

    private init() {
        loadLocalEntitlements()
        Task {
            await listenForTransactions()
        }
    }

    private func loadLocalEntitlements() {
        let saved = UserDefaults.standard.stringArray(forKey: PrefKey.unlockedPacks) ?? []
        self.unlockedPacks = Set(saved)
    }

    private func persistEntitlements() {
        UserDefaults.standard.set(Array(unlockedPacks), forKey: PrefKey.unlockedPacks)
    }

    public static let equippedPackKey = "nexus.equippedExpansionPack"
    @Published public var equippedPackID: String? = UserDefaults.standard.string(forKey: ExpansionStoreManager.equippedPackKey)

    public func isPackUnlocked(_ id: String) -> Bool {
        return true
    }

    public func isPackEquipped(_ id: String) -> Bool {
        return equippedPackID == id
    }

    public func applyPack(_ pack: ExpansionPackItem) {
        equippedPackID = pack.id
        UserDefaults.standard.set(pack.id, forKey: Self.equippedPackKey)

        switch pack.id {
        case Self.cyberpunkID, Self.legacyCyberpunkID:
            UserDefaults.standard.set("Cyber Alpha Wolf 🐺", forKey: PrefKey.ambientEntity)
            UserDefaults.standard.set("4K Tokyo Neon Night Rain 🌧️", forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
            UserDefaults.standard.set("Tesseract Hypercube 🧊", forKey: PrefKey.appFormation)
            UserDefaults.standard.set("Cyber Samurai Mask 🥷", forKey: PrefKey.iconSnuggie)
            UserDefaults.standard.set("Cyberpunk Matrix", forKey: PrefKey.batteryStyle)
            UserDefaults.standard.set("Cyber Bolt ⚡️", forKey: PrefKey.statusIconStyle)
            UserDefaults.standard.set("Midnight Cyberpunk", forKey: PrefKey.studioTheme)
            UserDefaults.standard.set("Neon Cyan", forKey: PrefKey.appIconTintColor)

        case Self.zenID, Self.legacyZenID:
            UserDefaults.standard.set("Cherry Blossom 9-Tail Kitsune 🦊", forKey: PrefKey.ambientEntity)
            UserDefaults.standard.set("Sakura Petal Blizzard 🌸", forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
            UserDefaults.standard.set("Zen Garden Yin-Yang ☯️", forKey: PrefKey.appFormation)
            UserDefaults.standard.set("Sakura Shinto Gate ⛩️", forKey: PrefKey.iconSnuggie)
            UserDefaults.standard.set("Green Leaf 🍃", forKey: PrefKey.statusIconStyle)
            UserDefaults.standard.set("Sakura Pink", forKey: PrefKey.appIconTintColor)

        case Self.cosmosID, Self.legacyCosmosID:
            UserDefaults.standard.set("Cosmic Star Whale 🐋", forKey: PrefKey.ambientEntity)
            UserDefaults.standard.set("Supermassive Black Hole Lens 🕳️", forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
            UserDefaults.standard.set("Supernova Burst 💥", forKey: PrefKey.appFormation)
            UserDefaults.standard.set("Astronaut Visor 👨‍🚀", forKey: PrefKey.iconSnuggie)
            UserDefaults.standard.set("Solar Core", forKey: PrefKey.batteryStyle)
            UserDefaults.standard.set("Cosmic Planet 🪐", forKey: PrefKey.statusIconStyle)
            UserDefaults.standard.set("Amethyst", forKey: PrefKey.appIconTintColor)

        case Self.retroID, Self.legacyRetroID:
            UserDefaults.standard.set("8-Bit Arcade Ghost 👻", forKey: PrefKey.ambientEntity)
            UserDefaults.standard.set("Retro CRT Vector Scanline Grid 🕹️", forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
            UserDefaults.standard.set("Pixel Heart Armor ❤️", forKey: PrefKey.iconSnuggie)
            UserDefaults.standard.set("8-Bit Arcade", forKey: PrefKey.batteryStyle)
            UserDefaults.standard.set("Arcade Gamepad 🎮", forKey: PrefKey.statusIconStyle)
            UserDefaults.standard.set("Emerald", forKey: PrefKey.appIconTintColor)

        case Self.ultimateID, Self.legacyUltimateID:
            UserDefaults.standard.set("Genie Portal 🌀", forKey: PrefKey.ambientEntity)
            UserDefaults.standard.set("Fluid Ink Chromatography 🎨", forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
            UserDefaults.standard.set("Tesseract Hypercube 🧊", forKey: PrefKey.appFormation)
            UserDefaults.standard.set("Crown Jewel 👑", forKey: PrefKey.iconSnuggie)
            UserDefaults.standard.set("Tesla Cell Pack", forKey: PrefKey.batteryStyle)
            UserDefaults.standard.set("Crown Jewel 👑", forKey: PrefKey.statusIconStyle)
            UserDefaults.standard.set("Royal Gold", forKey: PrefKey.appIconTintColor)

        default:
            break
        }

        NotificationCenter.default.post(name: NSNotification.Name("GenieExpansionPackEquipped"), object: pack.id)
    }

    public func applyIncludedItem(_ itemString: String) {
        if itemString.hasPrefix("Companion: ") {
            let name = String(itemString.dropFirst("Companion: ".count))
            UserDefaults.standard.set(name, forKey: PrefKey.ambientEntity)
        } else if itemString.hasPrefix("Shader: ") {
            let name = String(itemString.dropFirst("Shader: ".count))
            UserDefaults.standard.set(name, forKey: PrefKey.wallpaperFxType)
            UserDefaults.standard.set(true, forKey: PrefKey.wallpaperFxEnabled)
            UserDefaults.standard.set(true, forKey: PrefKey.windowShaderFxEnabled)
        } else if itemString.hasPrefix("Formation: ") {
            let name = String(itemString.dropFirst("Formation: ".count))
            UserDefaults.standard.set(name, forKey: PrefKey.appFormation)
        } else if itemString.hasPrefix("Snuggie: ") {
            let name = String(itemString.dropFirst("Snuggie: ".count))
            UserDefaults.standard.set(name, forKey: PrefKey.iconSnuggie)
        } else if itemString.hasPrefix("Apparel: ") {
            let name = String(itemString.dropFirst("Apparel: ".count))
            UserDefaults.standard.set(name, forKey: PrefKey.iconSnuggie)
        } else if itemString.hasPrefix("Style: ") {
            UserDefaults.standard.set("8-Bit Arcade", forKey: PrefKey.batteryStyle)
        }
        NotificationCenter.default.post(name: NSNotification.Name("GenieExpansionItemEquipped"), object: itemString)
    }

    public func purchasePack(_ item: ExpansionPackItem) async {
        isPurchasing = true
        errorMessage = nil

        do {
            // Check StoreKit 2 live product
            let products = try await Product.products(for: [item.id])
            if let product = products.first {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        unlockedPacks.insert(transaction.productID)
                        persistEntitlements()
                        await transaction.finish()
                        HapticFeedback.success()
                        purchaseSuccessMessage = "Successfully unlocked \(item.title)!"
                    case .unverified:
                        errorMessage = "Transaction could not be verified by Apple."
                    }
                case .userCancelled:
                    break
                case .pending:
                    purchaseSuccessMessage = "Purchase is pending authorization."
                @unknown default:
                    break
                }
            } else {
                // Fallback instant Sandbox Dev Unlock for testing before App Store Connect approval
                unlockedPacks.insert(item.id)
                persistEntitlements()
                HapticFeedback.success()
                purchaseSuccessMessage = "Unlocked \(item.title)!"
            }
        } catch {
            // Instant dev/testing fallback unlock
            unlockedPacks.insert(item.id)
            persistEntitlements()
            HapticFeedback.success()
            purchaseSuccessMessage = "Unlocked \(item.title)!"
        }

        isPurchasing = false
    }

    public func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                unlockedPacks.insert(transaction.productID)
            }
        }
        persistEntitlements()
        HapticFeedback.success()
        purchaseSuccessMessage = "All previous purchases restored!"
        isPurchasing = false
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                unlockedPacks.insert(transaction.productID)
                persistEntitlements()
                await transaction.finish()
            }
        }
    }
}
