import AppKit
import SwiftUI

// MARK: - Status Icon Renderer

final class StatusIconRenderer {

    static var currentPhase: CGFloat = 0.0

    static func renderIcon(statusItem: NSStatusItem?, phase: CGFloat, batteryPct: Int?, isCharging: Bool) {
        guard let statusItem = statusItem, let button = statusItem.button else { return }
        currentPhase = phase

        let style = UserDefaults.standard.string(forKey: PrefKey.batteryStyle)
            ?? UserDefaults.standard.string(forKey: PrefKey.iconStyle)
            ?? "Classic Apple Battery"
        let showPct = UserDefaults.standard.object(forKey: PrefKey.showBatteryPercentage) == nil
            ? true : UserDefaults.standard.bool(forKey: PrefKey.showBatteryPercentage)
        let colorMode = UserDefaults.standard.string(forKey: PrefKey.batteryColorMode) ?? "Dynamic Level"
        let numberTheme = UserDefaults.standard.string(forKey: PrefKey.batteryNumberTheme) ?? "Dynamic Match"
        let glyph = UserDefaults.standard.string(forKey: PrefKey.statusIconGlyph)
            ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle)
            ?? "Genie Lamp 🪔"
        let iconEnabled = UserDefaults.standard.object(forKey: PrefKey.iconEnabled) == nil
            ? true : UserDefaults.standard.bool(forKey: PrefKey.iconEnabled)
        let batteryEnabled = UserDefaults.standard.object(forKey: PrefKey.batteryEnabled) == nil
            ? true : UserDefaults.standard.bool(forKey: PrefKey.batteryEnabled)

        // If battery is disabled, the Genie icon is always enabled as the primary interactive button
        let effectiveIconEnabled = batteryEnabled ? iconEnabled : true

        let batteryImg: NSImage? = batteryEnabled ? generateImage(
            style: style,
            colorMode: colorMode,
            numberTheme: numberTheme,
            showPct: showPct,
            batteryPct: batteryPct ?? 100,
            isCharging: isCharging,
            phase: phase
        ) : nil

        let glyphW: CGFloat = effectiveIconEnabled ? 20 : 0
        let spacing: CGFloat = (effectiveIconEnabled && batteryImg != nil) ? 5 : 0
        let batteryW: CGFloat = batteryImg?.size.width ?? 0
        let totalW: CGFloat = max(20, glyphW + spacing + batteryW)
        let totalH: CGFloat = 20

        let compositeImg = NSImage(size: NSSize(width: totalW, height: totalH), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }

            // 1. Draw Golden Gate Arch or chosen Brand Glyph on the left
            if effectiveIconEnabled {
                ctx.saveGState()
                renderSingleGlyph(ctx: ctx, glyph: glyph, size: glyphW, phase: phase)
                ctx.restoreGState()
            }

            // 2. Draw Live Battery Graphic & Percentage Text directly next to the icon
            if let bImg = batteryImg {
                let destRect = CGRect(x: glyphW + spacing, y: 0, width: bImg.size.width, height: bImg.size.height)
                bImg.draw(in: destRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }

            return true
        }

        compositeImg.isTemplate = false
        button.image = compositeImg
        button.imagePosition = .imageOnly
    }

    // MARK: - Individual Component Renderers for Menu Bar Strip
    static func generateGlyphImage(glyph: String? = nil, size: CGFloat = 18, phase: CGFloat = 0) -> NSImage {
        let selectedGlyph = glyph
            ?? UserDefaults.standard.string(forKey: PrefKey.statusIconGlyph)
            ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle)
            ?? "Genie Lamp 🪔"

        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }
            ctx.saveGState()
            renderSingleGlyph(ctx: ctx, glyph: selectedGlyph, size: size, phase: phase)
            ctx.restoreGState()
            return true
        }
        img.isTemplate = false
        return img
    }

    @MainActor
    static func generateBatteryImage(phase: CGFloat = 0, batteryPct: Int? = nil, isCharging: Bool? = nil, showPct: Bool? = nil) -> NSImage? {
        let batteryEnabled = UserDefaults.standard.object(forKey: PrefKey.batteryEnabled) == nil
            ? true : UserDefaults.standard.bool(forKey: PrefKey.batteryEnabled)
        guard batteryEnabled else { return nil }

        let style = UserDefaults.standard.string(forKey: PrefKey.batteryStyle)
            ?? UserDefaults.standard.string(forKey: PrefKey.iconStyle)
            ?? "Classic Apple Battery"
        let showPctVal = showPct ?? (UserDefaults.standard.object(forKey: PrefKey.showBatteryPercentage) == nil
            ? true : UserDefaults.standard.bool(forKey: PrefKey.showBatteryPercentage))
        let colorMode = UserDefaults.standard.string(forKey: PrefKey.batteryColorMode) ?? "Dynamic Level"
        let numberTheme = UserDefaults.standard.string(forKey: PrefKey.batteryNumberTheme) ?? "Dynamic Match"

        let monitor = BatteryMonitor.shared
        let pct = batteryPct ?? monitor.batteryPct ?? 100
        let charging = isCharging ?? monitor.isCharging

        return generateImage(
            style: style,
            colorMode: colorMode,
            numberTheme: numberTheme,
            showPct: showPctVal,
            batteryPct: pct,
            isCharging: charging,
            phase: phase
        )
    }

    // MARK: - Dedicated Composite Preview Generator (Exact Menu Bar Clone)

    static func generateCompositePreview(
        glyph: String,
        iconEnabled: Bool,
        style: String,
        colorMode: String,
        numberTheme: String,
        showPct: Bool,
        batteryPct: Int,
        isCharging: Bool,
        phase: CGFloat = 0,
        batteryEnabled: Bool = true
    ) -> NSImage? {
        let effectiveIconEnabled = batteryEnabled ? iconEnabled : true
        let batteryImg = batteryEnabled ? generateImage(
            style: style,
            colorMode: colorMode,
            numberTheme: numberTheme,
            showPct: showPct,
            batteryPct: batteryPct,
            isCharging: isCharging,
            phase: phase
        ) : nil

        let glyphW: CGFloat = effectiveIconEnabled ? 20 : 0
        let spacing: CGFloat = (effectiveIconEnabled && batteryImg != nil) ? 5 : 0
        let batteryW: CGFloat = batteryImg?.size.width ?? 0
        let totalW: CGFloat = max(20, glyphW + spacing + batteryW)
        let totalH: CGFloat = 20

        let compositeImg = NSImage(size: NSSize(width: totalW, height: totalH), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }

            if effectiveIconEnabled {
                ctx.saveGState()
                renderSingleGlyph(ctx: ctx, glyph: glyph, size: glyphW, phase: phase)
                ctx.restoreGState()
            }

            if let bImg = batteryImg {
                let destRect = CGRect(x: glyphW + spacing, y: 0, width: bImg.size.width, height: bImg.size.height)
                bImg.draw(in: destRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }

            return true
        }

        compositeImg.isTemplate = false
        return compositeImg
    }

    // MARK: - Dedicated Standalone Glyph Generator (Real Visual Renderings for Menu & Settings)

    static func generateGlyphImage(glyph: String, size: CGFloat = 20, phase: CGFloat = 0) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }
            ctx.saveGState()
            renderSingleGlyph(ctx: ctx, glyph: glyph, size: size, phase: phase)
            ctx.restoreGState()
            return true
        }
        img.isTemplate = false
        return img
    }

    static func renderSingleGlyph(ctx: CGContext, glyph: String, size: CGFloat, phase: CGFloat) {
        switch glyph {
        case "Custom Upload":
            if let customPath = UserDefaults.standard.string(forKey: PrefKey.customBrandLogoPath),
               let customImg = NSImage(contentsOfFile: customPath) {
                let iconRect = CGRect(x: 1, y: 1, width: size - 2, height: size - 2)
                customImg.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            } else {
                drawGoldenGateArch(ctx: ctx, size: size, phase: phase)
            }
        case "Leo Maltese", "Leo 🐶", "Leo Maltese 🐶":
            drawAnimatedLeoMaltese(ctx: ctx, size: size, phase: phase)
        case "Genie Person", "Genie Person 🧞‍♂️", "Genie 🧞", "Genie Spirit", "Genie Spirit 🧞‍♂️", "Genie":
            drawEmojiIcon("🧞‍♂️", size: size)
        case "Genie Lamp", "Genie Lamp 🪔":
            drawAnimatedGenieLamp(ctx: ctx, size: size, phase: phase)
        case "Crystal Ball", "Crystal Ball 🔮":
            drawSymbolIcon(named: "circle.hexagongrid.fill", color: NSColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0), size: size)
        case "Magic Portal", "Magic Portal 🌀":
            drawSymbolIcon(named: "camera.filters", color: NSColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1.0), size: size)
        case "Alien UFO", "Alien UFO 🛸":
            drawSymbolIcon(named: "airplane.circle.fill", color: NSColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0), size: size)
        case "Arcade Joystick", "Arcade Joystick 🕹️":
            drawSymbolIcon(named: "gamecontroller.fill", color: NSColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0), size: size)
        case "Cyber Katana", "Cyber Katana ⚔️":
            drawSymbolIcon(named: "shield.lefthalf.filled", color: NSColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0), size: size)
        case "Cherry Blossom", "Cherry Blossom 🌸":
            drawSymbolIcon(named: "leaf.fill", color: NSColor(red: 1.0, green: 0.5, blue: 0.7, alpha: 1.0), size: size)
        case "Floating Bubble", "Floating Bubble 🫧":
            drawSymbolIcon(named: "circle.circle", color: NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0), size: size)
        case "Lucky Clover", "Lucky Clover 🍀":
            drawSymbolIcon(named: "seal.fill", color: NSColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0), size: size)
        case "Retro Mac":
            drawSymbolIcon(named: "macwindow", color: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), size: size)
        case "Golden Gate Arch", "Golden Gate Arch 🌉", "Golden Bridge Cable 🌁":
            drawGoldenGateArch(ctx: ctx, size: size, phase: phase)
        case "Neon Golden Glow", "Neon Golden Glow 🌟":
            drawNeonGlow(ctx: ctx, size: size, phase: phase)
        case "Cyber Bolt", "Cyber Bolt ⚡️", "Cyberpunk LED", "High Voltage ⚡️":
            drawCyberLED(ctx: ctx, size: size, phase: phase)
        case "Solar Flare", "Solar Flare ☀️", "Sun Horizon 🌅":
            drawSolarFlare(ctx: ctx, size: size, phase: phase)
        case "Pixel Heart", "Pixel Heart 💖":
            drawPixelHeart(ctx: ctx, size: size, phase: phase)
        case "Star Sparkle", "Star Sparkle ✨":
            drawStarSparkle(ctx: ctx, size: size, phase: phase)
        case "Diamond Facet", "Diamond Facet 💎":
            drawDiamondFacet(ctx: ctx, size: size, phase: phase)
        case "Simple Lamp", "Simple Lamp ◐":
            drawSimpleMonoLamp(ctx: ctx, size: size)
        case "Simple Spark", "Simple Spark ✳︎":
            drawSimpleMonoSpark(ctx: ctx, size: size)
        case "Minimal Dot", "Minimal Dot ⚪":
            drawMinimalDot(ctx: ctx, size: size, phase: phase)
        case "Radioactive Pulse", "Radioactive Pulse ☢️":
            drawRadioactivePulse(ctx: ctx, size: size, phase: phase)
        case "Crown Jewel", "Crown Jewel 👑":
            drawSymbolIcon(named: "crown.fill", color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), size: size)
        case "Infinity Loop", "Infinity Loop ♾️", "Infinity Orb":
            drawSymbolIcon(named: "infinity", color: NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0), size: size)
        case "Fire Flame", "Fire Flame 🔥":
            drawSymbolIcon(named: "flame.fill", color: NSColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0), size: size)
        case "Water Droplet", "Water Droplet 💧":
            drawSymbolIcon(named: "drop.fill", color: NSColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 1.0), size: size)
        case "Golden Rocket", "Golden Rocket 🚀":
            drawSymbolIcon(named: "rocket.fill", color: NSColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), size: size)
        case "Cosmic Planet", "Cosmic Planet 🪐":
            drawSymbolIcon(named: "globe.americas.fill", color: NSColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0), size: size)
        case "Golden Shield", "Golden Shield 🛡️":
            drawSymbolIcon(named: "shield.fill", color: NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0), size: size)
        case "Golden Key", "Golden Key 🔑":
            drawSymbolIcon(named: "key.fill", color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), size: size)
        case "Music Note", "Music Note 🎵":
            drawSymbolIcon(named: "music.note", color: NSColor(red: 0.9, green: 0.3, blue: 0.8, alpha: 1.0), size: size)
        case "Arcade Gamepad", "Arcade Gamepad 🎮":
            drawSymbolIcon(named: "gamecontroller.fill", color: NSColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1.0), size: size)
        case "Ghost Spirit", "Ghost Spirit 👻":
            drawSymbolIcon(named: "theatermasks.fill", color: NSColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 1.0), size: size)
        case "Compass Rose", "Compass Rose 🧭":
            drawSymbolIcon(named: "safari.fill", color: NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0), size: size)
        case "Lightning Cloud", "Lightning Cloud ⛈️":
            drawSymbolIcon(named: "cloud.bolt.fill", color: NSColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1.0), size: size)
        case "Cyber Eye", "Cyber Eye 👁️":
            drawSymbolIcon(named: "eye.fill", color: NSColor(red: 0.1, green: 0.9, blue: 0.9, alpha: 1.0), size: size)
        case "Atom Core", "Atom Core ⚛️":
            drawSymbolIcon(named: "atom", color: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0), size: size)
        case "Golden Gear", "Golden Gear ⚙️":
            drawSymbolIcon(named: "gearshape.fill", color: NSColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1.0), size: size)
        case "Magic Wand", "Magic Wand 🪄":
            drawSymbolIcon(named: "wand.and.stars", color: NSColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0), size: size)
        case "Paper Plane", "Paper Plane ✈️":
            drawSymbolIcon(named: "paperplane.fill", color: NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0), size: size)
        case "Green Leaf", "Green Leaf 🍃":
            drawSymbolIcon(named: "leaf.fill", color: NSColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1.0), size: size)
        case "Crescent Moon", "Crescent Moon 🌙":
            drawSymbolIcon(named: "moon.fill", color: NSColor(red: 0.95, green: 0.85, blue: 0.4, alpha: 1.0), size: size)
        case "Terminal Hacker", "Terminal Hacker 💻":
            drawSymbolIcon(named: "terminal.fill", color: NSColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0), size: size)
        case "Quantum Beam", "Quantum Beam 📡":
            drawSymbolIcon(named: "antenna.radiowaves.left.and.right", color: NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0), size: size)
        case "Golden Bell", "Golden Bell 🔔":
            drawSymbolIcon(named: "bell.fill", color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), size: size)
        case "Vault Lock", "Vault Lock 🔒":
            drawSymbolIcon(named: "lock.fill", color: NSColor(red: 0.95, green: 0.75, blue: 0.2, alpha: 1.0), size: size)
        case "Studio Camera", "Studio Camera 📷":
            drawSymbolIcon(named: "camera.fill", color: NSColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0), size: size)
        case "Champion Flag", "Champion Flag 🚩":
            drawSymbolIcon(named: "flag.fill", color: NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), size: size)
        case "Gold Trophy", "Gold Trophy 🏆":
            drawSymbolIcon(named: "trophy.fill", color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), size: size)
        case "King Pin", "King Pin 🎳", "Bowling King Pin", "Bowling King Pin 'King Pin 🎳'":
            drawKingPin(ctx: ctx, size: size, phase: phase)
        case "Tech", "Tech ⚡️":
            drawCyberLED(ctx: ctx, size: size, phase: phase)
        case "Luxury", "Luxury 👑":
            drawSymbolIcon(named: "crown.fill", color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), size: size)
        case "Magic", "Magic 🪄":
            drawSymbolIcon(named: "wand.and.stars", color: NSColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0), size: size)
        case "Nature", "Nature 🍃":
            drawSymbolIcon(named: "leaf.fill", color: NSColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1.0), size: size)
        case "Apple Modern", "Apple Modern ", "Apple Logo":
            drawSymbolIcon(named: "apple.logo", color: .white, size: size)
        default:
            // Custom user emoji detection: if the glyph is an emoji or contains emojis, render it!
            if glyph.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                // If it's a single emoji or short emoji string, draw directly
                let cleanEmoji = glyph.trimmingCharacters(in: .whitespacesAndNewlines)
                drawEmojiIcon(cleanEmoji, size: size)
            } else {
                drawGoldenGateArch(ctx: ctx, size: size, phase: phase)
            }
        }
    }

    // MARK: - Dedicated Battery Generator (Public for Live Preview & Menu Bar)

    static func generateImage(
        style: String,
        colorMode: String,
        numberTheme: String,
        showPct: Bool,
        batteryPct: Int,
        isCharging: Bool,
        phase: CGFloat = 0
    ) -> NSImage? {
        let pctVal = max(0, min(100, batteryPct))
        let pctFloat = CGFloat(pctVal) / 100.0

        let isDigitalNumberOnly = [
            "Digital Clock 7-Segment",
            "Retro LCD Matrix Clock",
            "Cyber Neon Digits",
            "Nixie Tube Digits",
            "Bold Minimal Digital",
            "Digital LED Dot Matrix",
            "VisionOS Digital Pill",
            "Text Only (% Only)"
        ].contains(style)

        let baseW: CGFloat = {
            if isDigitalNumberOnly {
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let boltExtra: CGFloat = (isCharging && showChargingBolt) ? 10 : 0
                let digitCount = pctVal == 100 ? 3 : (pctVal >= 10 ? 2 : 1)
                switch style {
                case "Digital Clock 7-Segment":
                    return CGFloat(digitCount * 9 + 18) + boltExtra
                case "Digital LED Dot Matrix":
                    return CGFloat(digitCount * 9 + 16) + boltExtra
                case "Retro LCD Matrix Clock", "VisionOS Digital Pill":
                    return CGFloat(digitCount * 8 + 24) + boltExtra
                case "Cyber Neon Digits":
                    return CGFloat(digitCount * 8 + 26) + boltExtra
                case "Nixie Tube Digits":
                    return CGFloat(digitCount * 8 + 22) + boltExtra
                default:
                    return CGFloat(digitCount * 8 + 16) + boltExtra
                }
            }
            if !showPct {
                if style == "Classic Apple Battery" || style == "Apple Minimal" || style == "Monochrome" { return 34 }
                if style == "Minimal Pill" || style == "VisionOS Pill" || style == "Minimal Ring" || style == "Radial Ring" || style == "Circular Dual Arc" || style == "Pixel Heart" || style == "Gold Gate Bolt" { return 32 }
                if style == "3-Block Simple" { return 36 }
                return 42
            }
            let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
            let boltExtra: CGFloat = (isCharging && showChargingBolt) ? 8 : 0
            if style == "Minimal Pill" || style == "VisionOS Pill" || style == "3-Block Simple" || style == "Minimal Ring" || style == "Radial Ring" || style == "Circular Dual Arc" || style == "Pixel Heart" || style == "Gold Gate Bolt" {
                return 70 + boltExtra
            }
            return (style == "10-Bar Gauge" || style == "Tesla Cell Pack" || style == "Audio VU Meter"
                || style == "DNA Helix" || style == "Cyberpunk Matrix" || style == "10-Bar Equalizer" || style == "Equalizer Bars" || style == "Liquid Wave" || style == "Dynamic Wave" || style == "10 Neon LEDs" || style == "Animated Hex" || style == "Retro Dot Matrix" || style == "8-Bit Arcade" || style == "Cyberpunk Segment HUD" || style == "Neon Synthwave Barcode" || style == "Nixie Tube Glow" || style == "Quantum Arc Reactor" || style == "Dynamic Island Fluid"
                ? (88 + boltExtra) : 80)
        }()
        let W: CGFloat = baseW
        let H: CGFloat = 20

        func colorForLevel(_ factor: CGFloat, localPhase: CGFloat = 0) -> NSColor {
            let chargePulse = sin(phase * .pi * 3.0 + localPhase)
            
            switch colorMode {
            case "Rainbow Flow", "Rainbow Aura":
                let hue = (phase + localPhase).truncatingRemainder(dividingBy: 1.0)
                return NSColor(hue: hue, saturation: 0.85, brightness: 1.0, alpha: 1.0)
                
            case "Cyber Neon", "Cyber Pink":
                let isPink = Int((phase + localPhase) * 10) % 2 == 0
                return isPink
                    ? NSColor(red: 1.0, green: 0.15, blue: 0.70, alpha: 1.0)
                    : NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
                
            case "Apple Green", "Emerald Green":
                if isCharging {
                    return NSColor(red: 0.20 + 0.10 * chargePulse, green: 0.95, blue: 0.45, alpha: 1.0)
                }
                return NSColor(red: 0.20, green: 0.88, blue: 0.42, alpha: 1.0)
                
            case "Solar Flare", "Solar Orange":
                let wave = 0.5 + 0.5 * sin(phase * .pi * 2.0 + localPhase)
                return NSColor(red: 1.0, green: 0.45 + 0.40 * wave, blue: 0.10, alpha: 1.0)
                
            case "Deep Ocean", "Neon Cyan":
                let wave = 0.5 + 0.5 * sin(phase * .pi * 2.0 + localPhase)
                return NSColor(red: 0.0, green: 0.80 + 0.18 * wave, blue: 0.95, alpha: 1.0)
                
            case "Electric Violet":
                if isCharging {
                    return NSColor(red: 0.85, green: 0.45 + 0.15 * chargePulse, blue: 1.0, alpha: 1.0)
                }
                return NSColor(red: 0.78, green: 0.38, blue: 1.0, alpha: 1.0)
                
            case "Crimson Red":
                if isCharging {
                    return NSColor(red: 1.0, green: 0.30 + 0.15 * chargePulse, blue: 0.35, alpha: 1.0)
                }
                return NSColor(red: 1.0, green: 0.22, blue: 0.28, alpha: 1.0)
                
            case "Monochrome White":
                if isCharging {
                    return NSColor(white: 0.80 + 0.20 * chargePulse, alpha: 1.0)
                }
                return NSColor(white: 0.96, alpha: 1.0)
                
            case "Monochrome Dim":
                if isCharging {
                    return NSColor(white: 0.60 + 0.25 * chargePulse, alpha: 1.0)
                }
                return NSColor(white: 0.70, alpha: 1.0)
                
            default: // Dynamic Level
                if isCharging {
                    let wave = (phase * 1.5 + localPhase).truncatingRemainder(dividingBy: 1.0)
                    if wave > 0.65 {
                        return NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
                    } else if wave > 0.32 {
                        return NSColor(red: 0.20, green: 0.98, blue: 0.45, alpha: 1.0)
                    } else {
                        return NSColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0)
                    }
                }
                if factor > 0.45 {
                    return NSColor(red: 0.20, green: 0.88, blue: 0.42, alpha: 1.0)
                } else if factor > 0.20 {
                    return NSColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 1.0)
                } else {
                    return NSColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
                }
            }
        }

        let sizeScale = clampedIconSizeScale()
        let spacingScale = clampedIconSpacingScale()
        let extraMargin: CGFloat = max(0, 8.0 * (spacingScale - 1.0))
        let renderW = (W * sizeScale) + extraMargin * 2
        let renderH = H * sizeScale

        let img = NSImage(size: NSSize(width: renderW, height: renderH), flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }
            ctx.saveGState()
            defer { ctx.restoreGState() }

            ctx.translateBy(x: extraMargin, y: 0)
            ctx.scaleBy(x: sizeScale, y: sizeScale)

            // Dedicated Drawing For All Battery Styles
            switch style {
            case "Classic Apple Battery", "Apple Minimal", "Monochrome":
                let bw: CGFloat = 24, bh: CGFloat = 11
                let bx: CGFloat = 4, by: CGFloat = (H - bh) / 2
                let bRect = CGRect(x: bx, y: by, width: bw, height: bh)
                let bPath = CGPath(roundedRect: bRect, cornerWidth: 3.0, cornerHeight: 3.0, transform: nil)
                ctx.addPath(bPath)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.45).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()

                let capW: CGFloat = 2.0, capH: CGFloat = 4.5
                let capRect = CGRect(x: bx + bw + 1.0, y: (H - capH) / 2, width: capW, height: capH)
                let capPath = CGPath(roundedRect: capRect, cornerWidth: 1.0, cornerHeight: 1.0, transform: nil)
                ctx.addPath(capPath)
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.40).cgColor)
                ctx.fillPath()

                let fillPad: CGFloat = 2.0
                let maxFillW = bw - (fillPad * 2)
                let curFillW = max(2.0, maxFillW * pctFloat)
                let fillRect = CGRect(x: bx + fillPad, y: by + fillPad, width: curFillW, height: bh - (fillPad * 2))
                let fillPath = CGPath(roundedRect: fillRect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
                ctx.addPath(fillPath)
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()

            case "Minimal Pill", "VisionOS Pill":
                let bw: CGFloat = 26, bh: CGFloat = 10
                let bx: CGFloat = 4, by: CGFloat = (H - bh) / 2
                let bRect = CGRect(x: bx, y: by, width: bw, height: bh)
                ctx.addPath(CGPath(roundedRect: bRect, cornerWidth: bh / 2, cornerHeight: bh / 2, transform: nil))
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.15).cgColor)
                ctx.fillPath()

                let curFillW = max(bh, bw * pctFloat)
                let fillRect = CGRect(x: bx, y: by, width: curFillW, height: bh)
                ctx.addPath(CGPath(roundedRect: fillRect, cornerWidth: bh / 2, cornerHeight: bh / 2, transform: nil))
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()

            case "Minimal Ring", "Radial Ring":
                let center = CGPoint(x: 12, y: H / 2)
                let radius: CGFloat = 7.0
                let lineWidth: CGFloat = 2.2

                let bgPath = CGMutablePath()
                bgPath.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
                ctx.addPath(bgPath)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.strokePath()

                let startAngle: CGFloat = -.pi / 2
                let endAngle = startAngle + (.pi * 2 * pctFloat)
                let arcPath = CGMutablePath()
                arcPath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                ctx.addPath(arcPath)
                ctx.setStrokeColor(colorForLevel(pctFloat).cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                ctx.strokePath()

            case "Circular Dual Arc":
                let center = CGPoint(x: 12, y: H / 2)
                let r1: CGFloat = 7.0, r2: CGFloat = 4.5
                let w: CGFloat = 1.8
                let start1: CGFloat = -.pi / 2
                let end1 = start1 + (.pi * 2 * pctFloat)
                let path1 = CGMutablePath()
                path1.addArc(center: center, radius: r1, startAngle: start1, endAngle: end1, clockwise: false)
                ctx.addPath(path1)
                ctx.setStrokeColor(colorForLevel(pctFloat).cgColor)
                ctx.setLineWidth(w)
                ctx.setLineCap(.round)
                ctx.strokePath()

                let start2: CGFloat = .pi / 2
                let end2 = start2 - (.pi * 2 * pctFloat)
                let path2 = CGMutablePath()
                path2.addArc(center: center, radius: r2, startAngle: start2, endAngle: end2, clockwise: true)
                ctx.addPath(path2)
                ctx.setStrokeColor(colorForLevel(pctFloat, localPhase: 0.5).cgColor)
                ctx.setLineWidth(1.4)
                ctx.setLineCap(.round)
                ctx.strokePath()

            case "3-Block Simple":
                let blockCount = 3
                let bw: CGFloat = 7.0, bh: CGFloat = 10.0, gap: CGFloat = 2.2
                let bx: CGFloat = 4
                for i in 0..<blockCount {
                    let active = CGFloat(i) / CGFloat(blockCount) < pctFloat
                    let r = CGRect(x: bx + CGFloat(i) * (bw + gap), y: (H - bh) / 2, width: bw, height: bh)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 2, cornerHeight: 2, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(pctFloat, localPhase: CGFloat(i) * 0.2).cgColor : NSColor.white.withAlphaComponent(0.14).cgColor)
                    ctx.fillPath()
                }

            case "Pixel Heart":
                let cx: CGFloat = 12, cy: CGFloat = H / 2
                let heartFill = colorForLevel(pctFloat)
                let heartEmpty = NSColor.white.withAlphaComponent(0.15)
                
                let heartMap: [[Int]] = [
                    [0, 1, 1, 0, 1, 1, 0],
                    [1, 1, 1, 1, 1, 1, 1],
                    [1, 1, 1, 1, 1, 1, 1],
                    [0, 1, 1, 1, 1, 1, 0],
                    [0, 0, 1, 1, 1, 0, 0],
                    [0, 0, 0, 1, 0, 0, 0]
                ]
                let pxSize: CGFloat = 1.8
                let startX = cx - (7 * pxSize) / 2
                let startY = cy + (6 * pxSize) / 2
                
                for (rowIdx, row) in heartMap.enumerated() {
                    for (colIdx, val) in row.enumerated() {
                        if val == 1 {
                            let factor = 1.0 - (CGFloat(rowIdx) / 6.0)
                            let active = factor <= pctFloat || (rowIdx >= Int(6.0 * (1.0 - pctFloat)))
                            let r = CGRect(x: startX + CGFloat(colIdx) * pxSize, y: startY - CGFloat(rowIdx) * pxSize, width: pxSize - 0.2, height: pxSize - 0.2)
                            ctx.setFillColor(active ? heartFill.cgColor : heartEmpty.cgColor)
                            ctx.fill(r)
                        }
                    }
                }

            case "Audio VU Meter":
                let barCount = 7
                let barW: CGFloat = 2.4, gap: CGFloat = 1.8
                let startX: CGFloat = 4
                for i in 0..<barCount {
                    let active = CGFloat(i) / CGFloat(barCount) < pctFloat
                    let wave = sin(phase * .pi * 4.0 + CGFloat(i) * 0.9)
                    let beat = isCharging ? (0.4 + 0.6 * abs(wave)) : (0.3 + 0.7 * (CGFloat(i + 1) / CGFloat(barCount)))
                    let barH = active ? max(4.0, (H - 6) * beat) : 3.0
                    let r = CGRect(x: startX + CGFloat(i) * (barW + gap), y: (H - barH) / 2, width: barW, height: barH)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.2, cornerHeight: 1.2, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(CGFloat(i) / CGFloat(barCount), localPhase: CGFloat(i) * 0.15).cgColor : NSColor.white.withAlphaComponent(0.12).cgColor)
                    ctx.fillPath()
                }

            case "DNA Helix":
                let nodeCount = 8
                let startX: CGFloat = 4, nodeW: CGFloat = 2.4
                let stepX: CGFloat = 3.6
                for i in 0..<nodeCount {
                    let t = phase * .pi * 2.0 + CGFloat(i) * 0.6
                    let y1 = (H / 2) + sin(t) * 5.0
                    let y2 = (H / 2) - sin(t) * 5.0
                    let active = CGFloat(i) / CGFloat(nodeCount) < pctFloat
                    let col = active ? colorForLevel(pctFloat, localPhase: CGFloat(i) * 0.1).cgColor : NSColor.white.withAlphaComponent(0.14).cgColor
                    
                    ctx.setStrokeColor(col)
                    ctx.setLineWidth(0.8)
                    ctx.move(to: CGPoint(x: startX + CGFloat(i) * stepX, y: y1))
                    ctx.addLine(to: CGPoint(x: startX + CGFloat(i) * stepX, y: y2))
                    ctx.strokePath()
                    
                    ctx.setFillColor(col)
                    ctx.fillEllipse(in: CGRect(x: startX + CGFloat(i) * stepX - 1.2, y: y1 - 1.2, width: nodeW, height: nodeW))
                    ctx.fillEllipse(in: CGRect(x: startX + CGFloat(i) * stepX - 1.2, y: y2 - 1.2, width: nodeW, height: nodeW))
                }

            case "Cyberpunk Matrix":
                let cellCount = 5
                let cellW: CGFloat = 5.0, cellH: CGFloat = 11.0, gap: CGFloat = 2.0
                let startX: CGFloat = 4
                ctx.setStrokeColor(colorForLevel(pctFloat).withAlphaComponent(0.4).cgColor)
                ctx.setLineWidth(0.8)
                ctx.stroke(CGRect(x: startX - 2, y: (H - cellH) / 2 - 2, width: CGFloat(cellCount) * (cellW + gap) + 2, height: cellH + 4))
                
                for i in 0..<cellCount {
                    let active = CGFloat(i) / CGFloat(cellCount) < pctFloat
                    let r = CGRect(x: startX + CGFloat(i) * (cellW + gap), y: (H - cellH) / 2, width: cellW, height: cellH)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.0, cornerHeight: 1.0, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(CGFloat(i) / CGFloat(cellCount), localPhase: CGFloat(i) * 0.2).cgColor : NSColor.white.withAlphaComponent(0.10).cgColor)
                    ctx.fillPath()
                }

            case "Gold Gate Bolt":
                let bx: CGFloat = 6, by: CGFloat = 3
                let boltPath = CGMutablePath()
                boltPath.move(to: CGPoint(x: bx + 8, y: by + 14))
                boltPath.addLine(to: CGPoint(x: bx + 1, y: by + 7))
                boltPath.addLine(to: CGPoint(x: bx + 6, y: by + 7))
                boltPath.addLine(to: CGPoint(x: bx + 4, y: by + 0))
                boltPath.addLine(to: CGPoint(x: bx + 12, y: by + 8))
                boltPath.addLine(to: CGPoint(x: bx + 7, y: by + 8))
                boltPath.closeSubpath()
                
                ctx.addPath(boltPath)
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()

            case "Gold Gate Logo":
                let bx: CGFloat = 4, by: CGFloat = 3, bw: CGFloat = 26, bh: CGFloat = 14
                // Two towers
                ctx.setFillColor(NSColor(red: 1.0, green: 0.38, blue: 0.12, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: bx + 4, y: by, width: 2.5, height: bh))
                ctx.fill(CGRect(x: bx + bw - 6.5, y: by, width: 2.5, height: bh))
                // Suspension Cable
                let cable = CGMutablePath()
                cable.move(to: CGPoint(x: bx + 5.25, y: by + bh))
                cable.addQuadCurve(to: CGPoint(x: bx + bw - 5.25, y: by + bh), control: CGPoint(x: bx + bw / 2, y: by + 3))
                ctx.addPath(cable)
                ctx.setStrokeColor(NSColor(red: 1.0, green: 0.82, blue: 0.2, alpha: 0.8).cgColor)
                ctx.setLineWidth(1.2)
                ctx.strokePath()
                // Deck fill
                let deckW = (bw - 2) * pctFloat
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fill(CGRect(x: bx + 1, y: by + 3, width: deckW, height: 2.5))

            case "10-Bar Equalizer", "Equalizer Bars":
                let barCount = 10
                let barW: CGFloat = 2.2, gap: CGFloat = 1.6
                let startX: CGFloat = 4
                for i in 0..<barCount {
                    let active = CGFloat(i) / CGFloat(barCount) < pctFloat
                    let wave = sin(phase * .pi * 3.0 + CGFloat(i) * 0.7)
                    let hFactor = isCharging ? (0.4 + 0.6 * abs(wave)) : (CGFloat(i + 1) / CGFloat(barCount))
                    let barH = active ? max(4.0, (H - 6) * hFactor) : 3.0
                    let r = CGRect(x: startX + CGFloat(i) * (barW + gap), y: (H - barH) / 2, width: barW, height: barH)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1, cornerHeight: 1, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(CGFloat(i) / CGFloat(barCount), localPhase: CGFloat(i) * 0.1).cgColor : NSColor.white.withAlphaComponent(0.12).cgColor)
                    ctx.fillPath()
                }

            case "Liquid Wave", "Dynamic Wave":
                let bw: CGFloat = 32, bh: CGFloat = 11
                let bx: CGFloat = 4, by: CGFloat = (H - bh) / 2
                let bRect = CGRect(x: bx, y: by, width: bw, height: bh)
                ctx.addPath(CGPath(roundedRect: bRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil))
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()

                ctx.saveGState()
                ctx.addPath(CGPath(roundedRect: bRect.insetBy(dx: 1.2, dy: 1.2), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil))
                ctx.clip()

                let curFillW = (bw - 2.4) * pctFloat
                let wavePath = CGMutablePath()
                wavePath.move(to: CGPoint(x: bx + 1.2, y: by + 1.2))
                for x in stride(from: 0.0, through: Double(curFillW), by: 1.2) {
                    let yOffset = sin(phase * .pi * 4.0 + (x * 0.4)) * 1.6
                    wavePath.addLine(to: CGPoint(x: bx + 1.2 + CGFloat(x), y: by + 1.2 + bh / 2 + CGFloat(yOffset)))
                }
                wavePath.addLine(to: CGPoint(x: bx + 1.2 + curFillW, y: by + 1.2))
                wavePath.closeSubpath()
                ctx.addPath(wavePath)
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()
                ctx.restoreGState()

            case "Cyberpunk Segment HUD":
                let segmentCount = 8
                let sw: CGFloat = 3.2, sh: CGFloat = 11.0, sGap: CGFloat = 1.6
                let sx: CGFloat = 4.0
                for i in 0..<segmentCount {
                    let active = CGFloat(i + 1) / CGFloat(segmentCount) <= pctFloat + 0.05
                    let rect = CGRect(x: sx + CGFloat(i) * (sw + sGap), y: (H - sh) / 2, width: sw, height: sh)
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
                    p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 2))
                    p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                    p.closeSubpath()
                    ctx.addPath(p)
                    ctx.setFillColor(active ? colorForLevel(pctFloat, localPhase: CGFloat(i) * 0.15).cgColor : NSColor.white.withAlphaComponent(0.12).cgColor)
                    ctx.fillPath()
                }

            case "Neon Synthwave Barcode":
                let barCount = 10
                let bw: CGFloat = 2.4, bgap: CGFloat = 1.4
                let startX: CGFloat = 4.0
                for i in 0..<barCount {
                    let active = CGFloat(i + 1) / CGFloat(barCount) <= pctFloat + 0.05
                    let barH = active ? max(4.0, (H - 6) * (0.5 + 0.5 * sin(phase * .pi * 3.0 + CGFloat(i) * 0.8))) : 3.0
                    let rect = CGRect(x: startX + CGFloat(i) * (bw + bgap), y: (H - barH) / 2, width: bw, height: barH)
                    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 1, cornerHeight: 1, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(pctFloat, localPhase: CGFloat(i) * 0.2).cgColor : NSColor.white.withAlphaComponent(0.10).cgColor)
                    ctx.fillPath()
                }

            case "Nixie Tube Glow":
                let nw: CGFloat = 28, nh: CGFloat = 12
                let nx: CGFloat = 4, ny: CGFloat = (H - nh) / 2
                let nRect = CGRect(x: nx, y: ny, width: nw, height: nh)
                ctx.addPath(CGPath(roundedRect: nRect, cornerWidth: 3, cornerHeight: 3, transform: nil))
                ctx.setStrokeColor(NSColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 0.5).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()

                let curW = max(2.0, (nw - 3) * pctFloat)
                let fillR = CGRect(x: nx + 1.5, y: ny + 1.5, width: curW, height: nh - 3)
                ctx.addPath(CGPath(roundedRect: fillR, cornerWidth: 2, cornerHeight: 2, transform: nil))
                ctx.setFillColor(NSColor(red: 1.0, green: 0.50, blue: 0.05, alpha: 0.85).cgColor)
                ctx.fillPath()

            case "Quantum Arc Reactor":
                let center = CGPoint(x: 12, y: H / 2)
                let radius: CGFloat = 7.0
                ctx.addPath(CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), transform: nil))
                ctx.setStrokeColor(colorForLevel(pctFloat).cgColor)
                ctx.setLineWidth(1.8)
                ctx.strokePath()

                let innerR: CGFloat = 3.5 * pctFloat
                ctx.addPath(CGPath(ellipseIn: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2), transform: nil))
                ctx.setFillColor(colorForLevel(pctFloat, localPhase: 0.3).cgColor)
                ctx.fillPath()

            case "Dynamic Island Fluid":
                let pw: CGFloat = 30, ph: CGFloat = 11
                let px: CGFloat = 4, py: CGFloat = (H - ph) / 2
                let pRect = CGRect(x: px, y: py, width: pw, height: ph)
                ctx.addPath(CGPath(roundedRect: pRect, cornerWidth: ph / 2, cornerHeight: ph / 2, transform: nil))
                ctx.setFillColor(NSColor.black.withAlphaComponent(0.45).cgColor)
                ctx.fillPath()
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()

                ctx.saveGState()
                ctx.addPath(CGPath(roundedRect: pRect.insetBy(dx: 1, dy: 1), cornerWidth: (ph - 2) / 2, cornerHeight: (ph - 2) / 2, transform: nil))
                ctx.clip()
                let fillW = max(ph, pw * pctFloat)
                let fillR = CGRect(x: px, y: py, width: fillW, height: ph)
                ctx.addPath(CGPath(roundedRect: fillR, cornerWidth: ph / 2, cornerHeight: ph / 2, transform: nil))
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()
                ctx.restoreGState()

            case "Ocean Dolphin 🐬":
                // Animated Vector Dolphin with Ocean Wave Level
                let dX: CGFloat = 4.0, dY: CGFloat = 3.0, dW: CGFloat = 26.0
                let waveH = CGFloat(sin(phase * .pi * 3.0)) * 2.0
                
                // Ocean Wave Baseline
                let wave = CGMutablePath()
                wave.move(to: CGPoint(x: dX, y: dY + 2.0))
                wave.addQuadCurve(to: CGPoint(x: dX + dW * 0.5, y: dY + 4.0 + waveH), control: CGPoint(x: dX + dW * 0.25, y: dY + waveH))
                wave.addQuadCurve(to: CGPoint(x: dX + dW, y: dY + 2.0), control: CGPoint(x: dX + dW * 0.75, y: dY + 6.0 + waveH))
                ctx.addPath(wave)
                ctx.setStrokeColor(NSColor(red: 0.1, green: 0.7, blue: 1.0, alpha: 0.7).cgColor)
                ctx.setLineWidth(1.2)
                ctx.strokePath()

                // Leaping Dolphin Silhouette
                let dolphin = CGMutablePath()
                let leapY = dY + 6.0 + (waveH * 0.8)
                dolphin.move(to: CGPoint(x: dX + 2, y: leapY))
                dolphin.addQuadCurve(to: CGPoint(x: dX + dW - 2, y: leapY + 4), control: CGPoint(x: dX + dW * 0.5, y: leapY + 8))
                dolphin.addLine(to: CGPoint(x: dX + dW, y: leapY + 8)) // Fluke Top
                dolphin.addLine(to: CGPoint(x: dX + dW, y: leapY + 1)) // Fluke Bottom
                dolphin.addQuadCurve(to: CGPoint(x: dX + 2, y: leapY), control: CGPoint(x: dX + dW * 0.5, y: leapY - 2))
                dolphin.closeSubpath()
                
                ctx.addPath(dolphin)
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()
                ctx.addPath(dolphin)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
                ctx.setLineWidth(0.9)
                ctx.strokePath()

            case "Coral Reef Fish 🐠":
                let fX: CGFloat = 4.0, fY: CGFloat = 4.0, fW: CGFloat = 24.0, fH: CGFloat = 12.0
                let finSway = CGFloat(sin(phase * .pi * 4.0)) * 2.0
                
                // Fish Body
                let fish = CGMutablePath()
                fish.move(to: CGPoint(x: fX + fW - 4, y: fY + fH * 0.5))
                fish.addQuadCurve(to: CGPoint(x: fX + 6, y: fY + fH * 0.5), control: CGPoint(x: fX + fW * 0.5, y: fY + fH + 1))
                fish.addLine(to: CGPoint(x: fX, y: fY + fH + finSway)) // Tail Top
                fish.addLine(to: CGPoint(x: fX, y: fY - finSway)) // Tail Bottom
                fish.addLine(to: CGPoint(x: fX + 6, y: fY + fH * 0.5))
                fish.addQuadCurve(to: CGPoint(x: fX + fW - 4, y: fY + fH * 0.5), control: CGPoint(x: fX + fW * 0.5, y: fY - 1))
                fish.closeSubpath()

                ctx.addPath(fish)
                ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                ctx.fillPath()
                ctx.addPath(fish)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
                ctx.setLineWidth(0.9)
                ctx.strokePath()

            case "Tesla Cell Pack":
                let cellCount = 6
                let cellW: CGFloat = 4.2, cellH: CGFloat = 11.0, cellGap: CGFloat = 1.6
                let startX: CGFloat = 4
                for i in 0..<cellCount {
                    let active = CGFloat(i) / CGFloat(cellCount) < pctFloat
                    let r = CGRect(x: startX + CGFloat(i) * (cellW + cellGap), y: (H - cellH) / 2, width: cellW, height: cellH)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(CGFloat(i) / CGFloat(cellCount)).cgColor : NSColor.white.withAlphaComponent(0.12).cgColor)
                    ctx.fillPath()
                }

            case "10 Neon LEDs":
                let ledCount = 10
                let r: CGFloat = 1.8, gap: CGFloat = 1.6
                let startX: CGFloat = 4.0
                let cy = H / 2
                for i in 0..<ledCount {
                    let active = CGFloat(i) / CGFloat(ledCount) < pctFloat
                    let cx = startX + CGFloat(i) * (r * 2 + gap) + r
                    let col = active ? colorForLevel(CGFloat(i) / CGFloat(ledCount), localPhase: CGFloat(i) * 0.15) : NSColor.white.withAlphaComponent(0.12)
                    ctx.setFillColor(col.cgColor)
                    ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
                    if active {
                        ctx.setFillColor(col.withAlphaComponent(0.3).cgColor)
                        ctx.fillEllipse(in: CGRect(x: cx - r - 1.0, y: cy - r - 1.0, width: (r + 1.0) * 2, height: (r + 1.0) * 2))
                    }
                }

            case "Animated Hex":
                let hexCount = 5
                let hexW: CGFloat = 5.2, gap: CGFloat = 1.6
                let startX: CGFloat = 4.0
                let cy = H / 2
                for i in 0..<hexCount {
                    let active = CGFloat(i) / CGFloat(hexCount) < pctFloat
                    let cx = startX + CGFloat(i) * (hexW + gap) + hexW / 2
                    let hexPath = CGMutablePath()
                    for v in 0..<6 {
                        let angle = CGFloat(v) * .pi / 3.0
                        let pt = CGPoint(x: cx + cos(angle) * (hexW / 2), y: cy + sin(angle) * 4.5)
                        if v == 0 { hexPath.move(to: pt) } else { hexPath.addLine(to: pt) }
                    }
                    hexPath.closeSubpath()
                    ctx.addPath(hexPath)
                    let col = active ? colorForLevel(CGFloat(i) / CGFloat(hexCount), localPhase: CGFloat(i) * 0.2) : NSColor.white.withAlphaComponent(0.12)
                    ctx.setFillColor(col.cgColor)
                    ctx.fillPath()
                }

            case "Tachometer Arc":
                let center = CGPoint(x: 13, y: 5)
                let radius: CGFloat = 9.0
                let trackPath = CGMutablePath()
                trackPath.addArc(center: center, radius: radius, startAngle: .pi, endAngle: 0, clockwise: true)
                ctx.addPath(trackPath)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
                ctx.setLineWidth(2.5)
                ctx.strokePath()

                let fillAngle = .pi - (.pi * pctFloat)
                let activePath = CGMutablePath()
                activePath.addArc(center: center, radius: radius, startAngle: .pi, endAngle: fillAngle, clockwise: true)
                ctx.addPath(activePath)
                ctx.setStrokeColor(colorForLevel(pctFloat).cgColor)
                ctx.setLineWidth(2.5)
                ctx.setLineCap(.round)
                ctx.strokePath()

            case "Solar Core":
                let center = CGPoint(x: 12, y: H / 2)
                let r: CGFloat = 5.0
                let pulse = 0.8 + 0.2 * sin(phase * .pi * 4.0)
                let col = colorForLevel(pctFloat)
                for i in 0..<8 {
                    let angle = CGFloat(i) * .pi / 4.0 + phase * .pi
                    let rayR: CGFloat = 6.0 * pctFloat * pulse
                    let p1 = CGPoint(x: center.x + cos(angle) * 4.5, y: center.y + sin(angle) * 4.5)
                    let p2 = CGPoint(x: center.x + cos(angle) * (4.5 + rayR), y: center.y + sin(angle) * (4.5 + rayR))
                    ctx.move(to: p1)
                    ctx.addLine(to: p2)
                    ctx.setStrokeColor(col.withAlphaComponent(0.6).cgColor)
                    ctx.setLineWidth(1.0)
                    ctx.strokePath()
                }
                ctx.setFillColor(col.cgColor)
                ctx.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))

            case "8-Bit Arcade":
                let bx: CGFloat = 4, by: CGFloat = 4, bw: CGFloat = 28, bh: CGFloat = 12
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.6).cgColor)
                ctx.setLineWidth(1.5)
                ctx.stroke(CGRect(x: bx, y: by, width: bw, height: bh))
                let innerW = max(2.0, (bw - 4) * pctFloat)
                let blockW: CGFloat = 3.0
                var curX: CGFloat = bx + 2
                while curX < bx + 2 + innerW {
                    let rw = min(blockW, (bx + 2 + innerW) - curX)
                    ctx.setFillColor(colorForLevel(pctFloat).cgColor)
                    ctx.fill(CGRect(x: curX, y: by + 2, width: rw - 0.5, height: bh - 4))
                    curX += blockW
                }

            case "Prism Pulse":
                let cx: CGFloat = 12, cy: CGFloat = H / 2
                let tri = CGMutablePath()
                tri.move(to: CGPoint(x: cx, y: cy + 7))
                tri.addLine(to: CGPoint(x: cx - 7, y: cy - 6))
                tri.addLine(to: CGPoint(x: cx + 7, y: cy - 6))
                tri.closeSubpath()
                ctx.addPath(tri)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.4).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()
                let beamLen = 14.0 * pctFloat
                for b in 0..<3 {
                    let offset = CGFloat(b) * 2.0 - 2.0
                    let col = colorForLevel(pctFloat, localPhase: CGFloat(b) * 0.3)
                    ctx.move(to: CGPoint(x: cx, y: cy))
                    ctx.addLine(to: CGPoint(x: cx + 7 + beamLen, y: cy + offset + sin(phase * .pi * 3.0) * 2))
                    ctx.setStrokeColor(col.cgColor)
                    ctx.setLineWidth(1.2)
                    ctx.strokePath()
                }

            case "Retro Dot Matrix":
                let cols = 9, rows = 3
                let dotSize: CGFloat = 1.8, gap: CGFloat = 1.2
                let startX: CGFloat = 4, startY: CGFloat = 5
                for c in 0..<cols {
                    let active = CGFloat(c) / CGFloat(cols) < pctFloat
                    for r in 0..<rows {
                        let col = active ? colorForLevel(CGFloat(c) / CGFloat(cols), localPhase: CGFloat(r) * 0.2) : NSColor.white.withAlphaComponent(0.1)
                        ctx.setFillColor(col.cgColor)
                        let rect = CGRect(x: startX + CGFloat(c) * (dotSize + gap), y: startY + CGFloat(r) * (dotSize + gap), width: dotSize, height: dotSize)
                        ctx.fillEllipse(in: rect)
                    }
                }

            case "Digital Clock 7-Segment":
                let digits = "\(pctVal)"
                let digitW: CGFloat = 7.5, digitH: CGFloat = 13.0, gap: CGFloat = 2.0
                let totalDigitsW = CGFloat(digits.count) * (digitW + gap) - gap
                let pctSymbolW: CGFloat = 8.0
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let boltW: CGFloat = (isCharging && showChargingBolt) ? 8.0 : 0
                let totalContentW = totalDigitsW + 3.0 + pctSymbolW + boltW
                var startX: CGFloat = max(2.0, (W - totalContentW) / 2.0)
                let startY: CGFloat = (H - digitH) / 2.0

                if isCharging && showChargingBolt {
                    ctx.saveGState()
                    ctx.setFillColor(NSColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0).cgColor)
                    ctx.setShadow(offset: .zero, blur: 2.0, color: NSColor.yellow.cgColor)
                    let bp = CGMutablePath()
                    bp.move(to: CGPoint(x: startX + 4.5, y: startY + 12))
                    bp.addLine(to: CGPoint(x: startX + 1.0, y: startY + 6.0))
                    bp.addLine(to: CGPoint(x: startX + 4.0, y: startY + 6.0))
                    bp.addLine(to: CGPoint(x: startX + 2.5, y: startY + 1.0))
                    bp.addLine(to: CGPoint(x: startX + 7.0, y: startY + 7.0))
                    bp.addLine(to: CGPoint(x: startX + 4.5, y: startY + 7.0))
                    bp.closeSubpath()
                    ctx.addPath(bp)
                    ctx.fillPath()
                    ctx.restoreGState()
                    startX += boltW
                }

                let activeCol = colorForLevel(pctFloat)
                let dimCol = NSColor.white.withAlphaComponent(0.08)

                let segMap: [Character: Set<Int>] = [
                    "0": [0, 1, 2, 3, 4, 5],
                    "1": [1, 2],
                    "2": [0, 1, 6, 4, 3],
                    "3": [0, 1, 6, 2, 3],
                    "4": [5, 6, 1, 2],
                    "5": [0, 5, 6, 2, 3],
                    "6": [0, 5, 4, 3, 2, 6],
                    "7": [0, 1, 2],
                    "8": [0, 1, 2, 3, 4, 5, 6],
                    "9": [0, 1, 2, 3, 5, 6]
                ]

                let t: CGFloat = 1.3
                let halfH = digitH / 2.0

                for char in digits {
                    let activeSegs = segMap[char] ?? []
                    let dx = startX, dy = startY

                    func drawSeg(segId: Int, rect: CGRect) {
                        let isLit = activeSegs.contains(segId)
                        ctx.saveGState()
                        if isLit {
                            ctx.setFillColor(activeCol.cgColor)
                            ctx.setShadow(offset: .zero, blur: 2.0, color: activeCol.cgColor)
                        } else {
                            ctx.setFillColor(dimCol.cgColor)
                        }
                        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 0.5, cornerHeight: 0.5, transform: nil))
                        ctx.fillPath()
                        ctx.restoreGState()
                    }

                    drawSeg(segId: 0, rect: CGRect(x: dx + t, y: dy + digitH - t, width: digitW - 2 * t, height: t))
                    drawSeg(segId: 1, rect: CGRect(x: dx + digitW - t, y: dy + halfH, width: t, height: halfH - t))
                    drawSeg(segId: 2, rect: CGRect(x: dx + digitW - t, y: dy + t, width: t, height: halfH - t))
                    drawSeg(segId: 3, rect: CGRect(x: dx + t, y: dy, width: digitW - 2 * t, height: t))
                    drawSeg(segId: 4, rect: CGRect(x: dx, y: dy + t, width: t, height: halfH - t))
                    drawSeg(segId: 5, rect: CGRect(x: dx, y: dy + halfH, width: t, height: halfH - t))
                    drawSeg(segId: 6, rect: CGRect(x: dx + t, y: dy + halfH - t / 2, width: digitW - 2 * t, height: t))

                    startX += digitW + gap
                }

                startX += 1.0
                ctx.saveGState()
                ctx.setFillColor(activeCol.cgColor)
                ctx.fillEllipse(in: CGRect(x: startX, y: startY + digitH - 3.5, width: 2.2, height: 2.2))
                ctx.fillEllipse(in: CGRect(x: startX + 3.8, y: startY + 1.5, width: 2.2, height: 2.2))
                ctx.setStrokeColor(activeCol.cgColor)
                ctx.setLineWidth(1.1)
                ctx.move(to: CGPoint(x: startX + 5.0, y: startY + digitH - 1.5))
                ctx.addLine(to: CGPoint(x: startX + 1.0, y: startY + 1.5))
                ctx.strokePath()
                ctx.restoreGState()

            case "Retro LCD Matrix Clock":
                let panelRect = CGRect(x: 2, y: 2.5, width: W - 4, height: 15)
                ctx.saveGState()
                ctx.addPath(CGPath(roundedRect: panelRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil))
                ctx.setFillColor(NSColor(red: 0.10, green: 0.14, blue: 0.10, alpha: 0.90).cgColor)
                ctx.fillPath()
                ctx.addPath(CGPath(roundedRect: panelRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil))
                ctx.setStrokeColor(NSColor(red: 0.25, green: 0.35, blue: 0.25, alpha: 0.80).cgColor)
                ctx.setLineWidth(0.8)
                ctx.strokePath()

                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let lcdFont = NSFont.monospacedDigitSystemFont(ofSize: 9.8, weight: .heavy)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: lcdFont,
                    .foregroundColor: NSColor(red: 0.25, green: 1.0, blue: 0.45, alpha: 1.0)
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = panelRect.midX - (tsz.width / 2.0)
                let ty = panelRect.midY - (tsz.height / 2.0)
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)
                ctx.restoreGState()

            case "Cyber Neon Digits":
                ctx.saveGState()
                let neonCol = NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let font = NSFont.monospacedDigitSystemFont(ofSize: 10.2, weight: .heavy)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: neonCol
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = (W - tsz.width) / 2.0
                let ty = (H - tsz.height) / 2.0

                ctx.setStrokeColor(neonCol.withAlphaComponent(0.85).cgColor)
                ctx.setLineWidth(1.2)
                ctx.setShadow(offset: .zero, blur: 2.5, color: neonCol.cgColor)
                ctx.move(to: CGPoint(x: tx - 2, y: ty + tsz.height))
                ctx.addLine(to: CGPoint(x: tx - 5, y: ty + tsz.height))
                ctx.addLine(to: CGPoint(x: tx - 5, y: ty))
                ctx.addLine(to: CGPoint(x: tx - 2, y: ty))
                ctx.move(to: CGPoint(x: tx + tsz.width + 2, y: ty + tsz.height))
                ctx.addLine(to: CGPoint(x: tx + tsz.width + 5, y: ty + tsz.height))
                ctx.addLine(to: CGPoint(x: tx + tsz.width + 5, y: ty))
                ctx.addLine(to: CGPoint(x: tx + tsz.width + 2, y: ty))
                ctx.strokePath()

                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)
                ctx.restoreGState()

            case "Nixie Tube Digits":
                let tubeRect = CGRect(x: 2, y: 2.5, width: W - 4, height: 15)
                ctx.saveGState()
                ctx.addPath(CGPath(roundedRect: tubeRect, cornerWidth: 4, cornerHeight: 4, transform: nil))
                ctx.setFillColor(NSColor(red: 0.14, green: 0.08, blue: 0.04, alpha: 0.85).cgColor)
                ctx.fillPath()
                ctx.addPath(CGPath(roundedRect: tubeRect, cornerWidth: 4, cornerHeight: 4, transform: nil))
                ctx.setStrokeColor(NSColor(red: 1.0, green: 0.45, blue: 0.10, alpha: 0.45).cgColor)
                ctx.setLineWidth(0.8)
                ctx.strokePath()

                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let font = NSFont.monospacedDigitSystemFont(ofSize: 9.8, weight: .heavy)
                let nixieCol = NSColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 1.0)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: nixieCol
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = tubeRect.midX - (tsz.width / 2.0)
                let ty = tubeRect.midY - (tsz.height / 2.0)
                ctx.setShadow(offset: .zero, blur: 3.5, color: nixieCol.cgColor)
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)
                ctx.restoreGState()

            case "Bold Minimal Digital":
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡ " : "") + "\(pctVal)%"
                let font = NSFont.systemFont(ofSize: 11.5, weight: .heavy)
                let col = colorForLevel(pctFloat)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: col
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = (W - tsz.width) / 2.0
                let ty = (H - tsz.height) / 2.0
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)

            case "Digital LED Dot Matrix":
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let font = NSFont.monospacedDigitSystemFont(ofSize: 10.0, weight: .bold)
                let col = colorForLevel(pctFloat)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: col
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = (W - tsz.width) / 2.0
                let ty = (H - tsz.height) / 2.0
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 2.5, color: col.cgColor)
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)
                ctx.restoreGState()

            case "VisionOS Digital Pill":
                let pillRect = CGRect(x: 2, y: 2.5, width: W - 4, height: 15)
                ctx.saveGState()
                ctx.addPath(CGPath(roundedRect: pillRect, cornerWidth: 7.5, cornerHeight: 7.5, transform: nil))
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
                ctx.fillPath()
                ctx.addPath(CGPath(roundedRect: pillRect, cornerWidth: 7.5, cornerHeight: 7.5, transform: nil))
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.28).cgColor)
                ctx.setLineWidth(0.8)
                ctx.strokePath()

                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let font = NSFont.monospacedDigitSystemFont(ofSize: 9.8, weight: .bold)
                let col = colorForLevel(pctFloat)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: col
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = pillRect.midX - (tsz.width / 2.0)
                let ty = pillRect.midY - (tsz.height / 2.0)
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)
                ctx.restoreGState()

            case "Text Only (% Only)":
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let textStr = (isCharging && showChargingBolt ? "⚡" : "") + "\(pctVal)%"
                let font = NSFont.monospacedDigitSystemFont(ofSize: 10.0, weight: .bold)
                let col = colorForLevel(pctFloat)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: col
                ]
                let tsz = (textStr as NSString).size(withAttributes: attrs)
                let tx = (W - tsz.width) / 2.0
                let ty = (H - tsz.height) / 2.0
                (textStr as NSString).draw(at: NSPoint(x: tx, y: ty), withAttributes: attrs)

            default: // 10-Bar Gauge & others
                let barCount = 10
                let barW: CGFloat = 2.2, gap: CGFloat = 1.4
                let startX: CGFloat = 4, barH: CGFloat = 11
                for i in 0..<barCount {
                    let active = CGFloat(i) / CGFloat(barCount) < pctFloat
                    let r = CGRect(x: startX + CGFloat(i) * (barW + gap), y: (H - barH) / 2, width: barW, height: barH)
                    ctx.addPath(CGPath(roundedRect: r, cornerWidth: 1.1, cornerHeight: 1.1, transform: nil))
                    ctx.setFillColor(active ? colorForLevel(CGFloat(i) / CGFloat(barCount), localPhase: CGFloat(i) * 0.1).cgColor : NSColor.white.withAlphaComponent(0.14).cgColor)
                    ctx.fillPath()
                }
            }

            // Battery % Text (Only drawn for styles that have a separate bar/graphic)
            if showPct && !isDigitalNumberOnly {
                let showChargingBolt = UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
                let s = (isCharging && showChargingBolt) ? "⚡\(pctVal)%" : "\(pctVal)%"
                let font: NSFont
                let textCol: NSColor

                switch numberTheme {
                case "Dynamic Match":
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
                    textCol = colorForLevel(pctFloat)
                case "Matrix Glow":
                    font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .heavy)
                    textCol = NSColor(red: 0.20, green: 1.0, blue: 0.35, alpha: 1.0)
                case "Cyber Neon":
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
                    textCol = NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
                case "Solar Amber":
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
                    textCol = NSColor(red: 1.0, green: 0.80, blue: 0.20, alpha: 1.0)
                case "Electric Violet":
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
                    textCol = NSColor(red: 0.85, green: 0.45, blue: 1.0, alpha: 1.0)
                case "Minimal Thin":
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .medium)
                    textCol = NSColor.white.withAlphaComponent(0.9)
                default: // Classic Mono
                    font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .bold)
                    textCol = isCharging ? (sin(phase * .pi * 4.0) > 0 ? NSColor(red: 1.0, green: 0.90, blue: 0.30, alpha: 1.0) : NSColor.white) : NSColor.white
                }

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textCol,
                ]
                let sz = (s as NSString).size(withAttributes: attrs)
                (s as NSString).draw(at: NSPoint(x: W - sz.width - 4, y: (H - sz.height) / 2), withAttributes: attrs)
            }

            return true
        }
        img.isTemplate = false
        return img
    }

    // MARK: - Glyph Icons (Golden Gate, Neon LEDs, Pixel Heart, etc.)

    private static func renderGlyphIcon(glyph: String, isCharging: Bool) -> NSImage {
        let size: CGFloat = 20
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return true }
            ctx.saveGState()
            defer { ctx.restoreGState() }

            switch glyph {
            case "Golden Gate Arch":
                drawGoldenGateArch(ctx: ctx, size: size, phase: currentPhase)
            case "Neon Golden Glow":
                drawNeonGlow(ctx: ctx, size: size, phase: currentPhase)
            case "Cyberpunk LED":
                drawCyberLED(ctx: ctx, size: size, phase: currentPhase)
            case "Solar Flare":
                drawSolarFlare(ctx: ctx, size: size, phase: currentPhase)
            case "Pixel Heart":
                drawPixelHeart(ctx: ctx, size: size, phase: currentPhase)
            case "Simple Lamp", "Simple Lamp ◐":
                drawSimpleMonoLamp(ctx: ctx, size: size)
            case "Simple Spark", "Simple Spark ✳︎":
                drawSimpleMonoSpark(ctx: ctx, size: size)
            case "Minimal Dot":
                drawMinimalDot(ctx: ctx, size: size, phase: currentPhase)
            case "Radioactive Pulse":
                drawRadioactivePulse(ctx: ctx, size: size, phase: currentPhase)
            default:
                drawGoldenGateArch(ctx: ctx, size: size, phase: currentPhase)
            }
            return true
        }
        img.isTemplate = false
        return img
    }

    // MARK: - Emoji & Symbol Icon Drawings

    private static func drawEmojiIcon(_ emoji: String, size: CGFloat) {
        let font = NSFont.systemFont(ofSize: size * 0.84)
        let attr: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        let str = NSAttributedString(string: emoji, attributes: attr)
        let strSize = str.size()
        let pt = CGPoint(
            x: max(0.0, (size - strSize.width) / 2.0),
            y: max(0.0, (size - strSize.height) / 2.0) - 1.0
        )
        str.draw(at: pt)
    }

    private static func drawSymbolIcon(named name: String, color: NSColor, size: CGFloat) {
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let colorConfig = NSImage.SymbolConfiguration(paletteColors: [color])
            let sizeConfig = NSImage.SymbolConfiguration(pointSize: size * 0.70, weight: .bold)
            let fullConfig = sizeConfig.applying(colorConfig)
            let configured = img.withSymbolConfiguration(fullConfig) ?? img
            let targetRect = CGRect(
                x: max(0.0, (size - configured.size.width) / 2.0),
                y: max(0.0, (size - configured.size.height) / 2.0),
                width: min(size, configured.size.width),
                height: min(size, configured.size.height)
            )
            configured.draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    private static func drawGoldenGateArch(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let towerColor = NSColor(red: 1.0, green: 0.38, blue: 0.12, alpha: 1.0).cgColor
        let cableColor = NSColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 0.85).cgColor

        // Left Tower
        ctx.setFillColor(towerColor)
        ctx.fill(CGRect(x: 3, y: 1, width: 3.2, height: size - 2))
        // Right Tower
        ctx.fill(CGRect(x: size - 6.2, y: 1, width: 3.2, height: size - 2))
        // Main Suspension Cable Arc
        ctx.setStrokeColor(cableColor)
        ctx.setLineWidth(1.4)
        ctx.move(to: CGPoint(x: 4.6, y: size - 3))
        ctx.addQuadCurve(to: CGPoint(x: size - 4.6, y: size - 3), control: CGPoint(x: size / 2, y: 3))
        ctx.strokePath()
    }

    private static func drawNeonGlow(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let pulse = 0.5 + 0.5 * sin(phase * .pi * 2)
        let color = NSColor(red: 1.0, green: 0.80, blue: 0.10 + 0.20 * pulse, alpha: 1.0).cgColor
        ctx.setFillColor(color)
        ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: size - 8, height: size - 8))
    }

    private static func drawCyberLED(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let isCyan = sin(phase * .pi * 3) > 0
        let col = isCyan ? NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0) : NSColor(red: 1.0, green: 0.15, blue: 0.70, alpha: 1.0)
        ctx.setFillColor(col.cgColor)
        ctx.fill(CGRect(x: 4, y: 4, width: size - 8, height: size - 8))
    }

    private static func drawSolarFlare(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let col = NSColor(red: 1.0, green: 0.50, blue: 0.10, alpha: 1.0).cgColor
        ctx.setFillColor(col)
        ctx.fillEllipse(in: CGRect(x: 3, y: 3, width: size - 6, height: size - 6))
    }

    private static func drawPixelHeart(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let col = NSColor(red: 1.0, green: 0.20, blue: 0.40, alpha: 1.0).cgColor
        ctx.setFillColor(col)
        let heart = CGMutablePath()
        heart.move(to: CGPoint(x: size / 2, y: 3))
        heart.addLine(to: CGPoint(x: 2, y: size - 7))
        heart.addArc(center: CGPoint(x: 6, y: size - 5), radius: 4, startAngle: .pi, endAngle: 0, clockwise: false)
        heart.addArc(center: CGPoint(x: size - 6, y: size - 5), radius: 4, startAngle: .pi, endAngle: 0, clockwise: false)
        heart.closeSubpath()
        ctx.addPath(heart)
        ctx.fillPath()
    }

    // MARK: - Simple monochrome glyphs (Claude / OpenAI style menu bar icons)
    // Flat, single-color, no animation. Drawn in labelColor so they follow the menu bar's
    // light/dark appearance exactly like Apple's and third-party template icons.
    private static var simpleMonoColor: CGColor {
        NSColor.labelColor.cgColor
    }

    /// A clean lamp silhouette: rounded body, short spout, lid knob, thin base.
    private static func drawSimpleMonoLamp(ctx: CGContext, size: CGFloat) {
        let s = size
        ctx.setFillColor(simpleMonoColor)
        ctx.setStrokeColor(simpleMonoColor)

        // Body: a squashed rounded capsule sitting on the base
        let body = CGRect(x: s * 0.18, y: s * 0.30, width: s * 0.52, height: s * 0.30)
        ctx.addPath(CGPath(roundedRect: body, cornerWidth: s * 0.15, cornerHeight: s * 0.15, transform: nil))
        ctx.fillPath()

        // Spout: a tapered stroke curving up to the right
        ctx.setLineWidth(max(1.6, s * 0.11))
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: s * 0.66, y: s * 0.46))
        ctx.addQuadCurve(to: CGPoint(x: s * 0.90, y: s * 0.62), control: CGPoint(x: s * 0.84, y: s * 0.44))
        ctx.strokePath()

        // Lid knob
        ctx.fillEllipse(in: CGRect(x: s * 0.38, y: s * 0.60, width: s * 0.12, height: s * 0.12))

        // Base
        let base = CGRect(x: s * 0.28, y: s * 0.20, width: s * 0.32, height: s * 0.07)
        ctx.addPath(CGPath(roundedRect: base, cornerWidth: s * 0.035, cornerHeight: s * 0.035, transform: nil))
        ctx.fillPath()
    }

    /// A six-arm rounded spark, in the spirit of Claude's asterisk mark.
    private static func drawSimpleMonoSpark(ctx: CGContext, size: CGFloat) {
        let s = size
        let c = CGPoint(x: s / 2, y: s / 2)
        ctx.setStrokeColor(simpleMonoColor)
        ctx.setLineWidth(max(1.8, s * 0.13))
        ctx.setLineCap(.round)
        let r = s * 0.36
        for i in 0..<6 {
            let a = CGFloat(i) / 6.0 * 2.0 * .pi + (.pi / 6.0)
            ctx.move(to: CGPoint(x: c.x + cos(a) * r * 0.22, y: c.y + sin(a) * r * 0.22))
            ctx.addLine(to: CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        ctx.strokePath()
    }

    private static func drawMinimalDot(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 7, y: 7, width: 6, height: 6))
    }

    private static func drawRadioactivePulse(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let pulse = 0.5 + 0.5 * sin(phase * .pi * 4)
        let col = NSColor(red: 0.20 + 0.30 * pulse, green: 1.0, blue: 0.20, alpha: 1.0).cgColor
        ctx.setFillColor(col)
        ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: size - 8, height: size - 8))
    }

    private static func drawStarSparkle(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let pulse = 0.6 + 0.4 * sin(phase * .pi * 3.0)
        let col = NSColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0).cgColor
        ctx.setFillColor(col)
        let star = CGMutablePath()
        let cx = size / 2, cy = size / 2
        let rOuter: CGFloat = (size * 0.42) * pulse
        let rInner: CGFloat = (size * 0.16) * pulse
        for i in 0..<8 {
            let angle = (CGFloat(i) / 8.0) * 2.0 * .pi - (.pi / 2.0)
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
            if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
        }
        star.closeSubpath()
        ctx.addPath(star)
        ctx.fillPath()
    }

    private static func drawDiamondFacet(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let col = NSColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 1.0).cgColor
        ctx.setFillColor(col)
        let diamond = CGMutablePath()
        diamond.move(to: CGPoint(x: size / 2, y: 2))
        diamond.addLine(to: CGPoint(x: size - 2, y: size / 2))
        diamond.addLine(to: CGPoint(x: size / 2, y: size - 2))
        diamond.addLine(to: CGPoint(x: 2, y: size / 2))
        diamond.closeSubpath()
        ctx.addPath(diamond)
        ctx.fillPath()
    }

    private static func drawKingPin(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let cx = size / 2
        // Pin Head
        let pinHead = CGMutablePath()
        pinHead.addArc(center: CGPoint(x: cx, y: size - 5.5), radius: 2.5, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        
        // Pin Body
        let body = CGMutablePath()
        body.move(to: CGPoint(x: cx - 1.8, y: size - 6.5))
        body.addQuadCurve(to: CGPoint(x: cx - 4.2, y: 4.5), control: CGPoint(x: cx - 1.2, y: 10))
        body.addQuadCurve(to: CGPoint(x: cx + 4.2, y: 4.5), control: CGPoint(x: cx, y: 2.0))
        body.addQuadCurve(to: CGPoint(x: cx + 1.8, y: size - 6.5), control: CGPoint(x: cx + 1.2, y: 10))
        body.closeSubpath()

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.addPath(pinHead)
        ctx.fillPath()
        ctx.addPath(body)
        ctx.fillPath()

        // Red Neck Stripes
        ctx.setFillColor(NSColor(red: 0.95, green: 0.2, blue: 0.2, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: cx - 2.0, y: size - 9.0, width: 4.0, height: 1.0))
        ctx.fill(CGRect(x: cx - 2.2, y: size - 11.0, width: 4.4, height: 1.0))

        // Gold Crown on King Pin
        let crownPulse = 0.85 + 0.15 * sin(phase * .pi * 3.0)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: crownPulse).cgColor)
        let crown = CGMutablePath()
        crown.move(to: CGPoint(x: cx - 3.2, y: size - 3.0))
        crown.addLine(to: CGPoint(x: cx - 3.2, y: size - 1.2))
        crown.addLine(to: CGPoint(x: cx - 1.6, y: size - 2.2))
        crown.addLine(to: CGPoint(x: cx, y: size - 0.6))
        crown.addLine(to: CGPoint(x: cx + 1.6, y: size - 2.2))
        crown.addLine(to: CGPoint(x: cx + 3.2, y: size - 1.2))
        crown.addLine(to: CGPoint(x: cx + 3.2, y: size - 3.0))
        crown.closeSubpath()
        ctx.addPath(crown)
        ctx.fillPath()
    }

    private static func drawAnimatedLeoMaltese(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let cx = size / 2
        let cy = size / 2
        let wag = sin(phase * .pi * 4.0) * 1.5
        let earBlink = abs(sin(phase * .pi * 2.0)) * 0.8

        // Soft Fluffy Head
        ctx.setFillColor(NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 6.5, y: cy - 4.5, width: 13, height: 11.5))

        // Floppy Left & Right Ears with subtle animated bobbing
        ctx.fillEllipse(in: CGRect(x: cx - 8.5, y: cy + 0.5 + earBlink, width: 4.5, height: 7))
        ctx.fillEllipse(in: CGRect(x: cx + 4.0, y: cy + 0.5 - earBlink, width: 4.5, height: 7))

        // Cute Sparkly Eyes (Boba style)
        ctx.setFillColor(NSColor(red: 0.12, green: 0.10, blue: 0.14, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 4.2, y: cy + 0.5, width: 2.8, height: 3.2))
        ctx.fillEllipse(in: CGRect(x: cx + 1.4, y: cy + 0.5, width: 2.8, height: 3.2))

        // Eye Catchlights
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 3.4, y: cy + 2.0, width: 1.1, height: 1.1))
        ctx.fillEllipse(in: CGRect(x: cx + 2.2, y: cy + 2.0, width: 1.1, height: 1.1))

        // Little Black Button Nose
        ctx.setFillColor(NSColor(red: 0.15, green: 0.12, blue: 0.16, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 1.2, y: cy - 1.8, width: 2.4, height: 1.8))

        // Tiny Pink Smile / Tongue
        ctx.setFillColor(NSColor(red: 1.0, green: 0.45, blue: 0.65, alpha: 0.95).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 1.0, y: cy - 3.8, width: 2.0, height: 1.6))

        // Mint Green Bow Tie with Animated Gold Sparkle
        ctx.setFillColor(NSColor(red: 0.35, green: 0.88, blue: 0.78, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: cx - 3.5 + wag, y: cy - 6.5, width: 7.0, height: 2.4))
        ctx.setFillColor(NSColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 1.0 + wag, y: cy - 6.5, width: 2.0, height: 2.4))
    }

    private static func drawAnimatedGenieLamp(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let cx = size / 2
        let cy = size / 2
        let pulse = 0.5 + 0.5 * sin(phase * .pi * 3.0)

        // Ornate Golden Aladdin Magic Lamp
        // 1. Lamp Pedestal / Base
        ctx.setFillColor(NSColor(red: 0.95, green: 0.72, blue: 0.15, alpha: 1.0).cgColor)
        let baseRect = CGRect(x: cx - 4.5, y: cy - 7.0, width: 9.0, height: 2.2)
        ctx.fillEllipse(in: baseRect)

        // 2. Lamp Body (Curved belly)
        let body = CGMutablePath()
        body.move(to: CGPoint(x: cx - 3.5, y: cy - 5.5))
        body.addCurve(to: CGPoint(x: cx + 4.5, y: cy - 2.5),
                      control1: CGPoint(x: cx - 5.5, y: cy - 2.0),
                      control2: CGPoint(x: cx + 1.0, y: cy - 6.0))
        body.addCurve(to: CGPoint(x: cx + 2.0, y: cy + 0.5),
                      control1: CGPoint(x: cx + 5.5, y: cy + 0.0),
                      control2: CGPoint(x: cx + 4.0, y: cy + 1.5))
        body.addCurve(to: CGPoint(x: cx - 3.5, y: cy - 1.5),
                      control1: CGPoint(x: cx - 1.0, y: cy + 1.0),
                      control2: CGPoint(x: cx - 4.0, y: cy + 0.0))
        body.closeSubpath()
        ctx.setFillColor(NSColor(red: 1.0, green: 0.80, blue: 0.20, alpha: 1.0).cgColor)
        ctx.addPath(body)
        ctx.fillPath()

        // 3. Graceful Upward Spout
        let spout = CGMutablePath()
        spout.move(to: CGPoint(x: cx + 2.5, y: cy - 1.5))
        spout.addQuadCurve(to: CGPoint(x: cx + 7.5, y: cy + 3.0), control: CGPoint(x: cx + 5.5, y: cy - 0.5))
        spout.addLine(to: CGPoint(x: cx + 6.0, y: cy + 3.5))
        spout.addQuadCurve(to: CGPoint(x: cx + 1.5, y: cy + 0.0), control: CGPoint(x: cx + 4.0, y: cy + 1.2))
        spout.closeSubpath()
        ctx.setFillColor(NSColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0).cgColor)
        ctx.addPath(spout)
        ctx.fillPath()

        // 4. Ornate Looped Handle on the left
        let handle = CGMutablePath()
        handle.move(to: CGPoint(x: cx - 3.5, y: cy - 1.5))
        handle.addCurve(to: CGPoint(x: cx - 4.0, y: cy - 5.0),
                        control1: CGPoint(x: cx - 7.5, y: cy + 1.0),
                        control2: CGPoint(x: cx - 7.5, y: cy - 4.5))
        ctx.setStrokeColor(NSColor(red: 0.90, green: 0.70, blue: 0.15, alpha: 1.0).cgColor)
        ctx.setLineWidth(1.3)
        ctx.addPath(handle)
        ctx.strokePath()

        // 5. Ornate Finial / Lid Knob
        ctx.setFillColor(NSColor(red: 1.0, green: 0.90, blue: 0.40, alpha: 1.0).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 1.2, y: cy + 0.8, width: 2.4, height: 2.4))

        // 6. Mystical Cyan/Violet Smoke Drift from spout
        let cyan = NSColor(red: 0.0, green: 0.92, blue: 1.0, alpha: 0.90).cgColor
        let purple = NSColor(red: 0.75, green: 0.35, blue: 1.0, alpha: 0.85).cgColor
        ctx.setFillColor(pulse > 0.5 ? cyan : purple)
        let sx = cx + 6.8 + sin(phase * .pi * 4.0) * 1.0
        let sy = cy + 4.2 + pulse * 1.5
        ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: 2.2 + pulse * 0.8, height: 2.2 + pulse * 0.8))
        ctx.setFillColor(cyan)
        ctx.fillEllipse(in: CGRect(x: sx - 1.5, y: sy + 2.0, width: 1.8, height: 1.8))
    }

    private static func drawAnimatedArcReactor(ctx: CGContext, size: CGFloat, phase: CGFloat) {
        let cx = size / 2, cy = size / 2
        let spin = phase * .pi * 4.0
        let cyan = NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0).cgColor

        // Outer Glow Ring
        ctx.setStrokeColor(cyan)
        ctx.setLineWidth(1.4)
        ctx.strokeEllipse(in: CGRect(x: cx - 7, y: cy - 7, width: 14, height: 14))

        // Center Core Pulse
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5))

        // Rotating Energy Nodes
        for i in 0..<4 {
            let angle = spin + CGFloat(i) * (.pi / 2.0)
            let nodeX = cx + cos(angle) * 5.0
            let nodeY = cy + sin(angle) * 5.0
            ctx.setFillColor(cyan)
            ctx.fillEllipse(in: CGRect(x: nodeX - 1.2, y: nodeY - 1.2, width: 2.4, height: 2.4))
        }
    }

    private static func clampedIconSizeScale() -> CGFloat {
        let scale = UserDefaults.standard.double(forKey: PrefKey.statusIconSizeScale)
        return scale > 0.1 ? CGFloat(scale) : 1.0
    }

    private static func clampedIconSpacingScale() -> CGFloat {
        let scale = UserDefaults.standard.double(forKey: PrefKey.statusIconSpacingScale)
        return scale > 0.1 ? CGFloat(scale) : 1.0
    }
}
