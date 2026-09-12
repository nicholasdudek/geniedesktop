import Foundation

// MARK: - 🎨 Genie Web Asset Resolver & Theme Styler
// Resolves WebKit base URLs for live previews, and provides embedded Apple 2028
// theme stylesheets so HTML previews and standalone cards render with beautiful
// glassmorphic CSS under any environment without missing asset errors.
public enum GenieWebAssetResolver {

    /// Finds the directory containing `assets/css` for WKWebView baseURL resolution
    public static var webBaseURL: URL {
        let fm = FileManager.default

        // 1. App Bundle web subdirectory
        if let bundleWeb = Bundle.main.resourceURL?.appendingPathComponent("web"),
           fm.fileExists(atPath: bundleWeb.appendingPathComponent("assets").path) {
            return bundleWeb
        }

        // 2. App Bundle root Resources directory
        if let bundleRes = Bundle.main.resourceURL,
           fm.fileExists(atPath: bundleRes.appendingPathComponent("assets").path) {
            return bundleRes
        }

        // 3. Local GoldGate development repository web path
        let devWeb = fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Genie/GoldGate/web")
        if fm.fileExists(atPath: devWeb.appendingPathComponent("assets").path) {
            return devWeb
        }

        // 4. Default user Desktop
        return fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    /// Determines the optimal base URL for an artifact, prioritizing any local assets folder
    public static func effectiveBaseURL(for candidate: URL?) -> URL {
        if let candidate = candidate {
            let folder = candidate.hasDirectoryPath ? candidate : candidate.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent("assets").path) {
                return folder
            }
        }
        return webBaseURL
    }

    /// Embedded Apple 2028 Themes CSS bundle for self-contained HTML cards & previews
    public static let embeddedThemeCSS: String = """
    /* 🪔 GENIE APPLE 2028 UNIFIED THEMES (EMBEDDED SUITE) */
    :root {
      --genie-bg: #050a14;
      --genie-bg-gradient: radial-gradient(circle at 50% -10%, #0d2847 0%, #061122 45%, #02060d 100%);
      --genie-glass-card: rgba(10, 20, 38, 0.72);
      --genie-glass-blur: blur(32px) saturate(210%);
      --genie-border-liquid: linear-gradient(135deg, rgba(255, 255, 255, 0.65) 0%, rgba(0, 240, 255, 0.55) 35%, rgba(0, 128, 255, 0.20) 70%, rgba(255, 255, 255, 0.35) 100%);
      --genie-border-subtle: rgba(0, 240, 255, 0.18);
      --genie-caustic-cyan: #00f0ff;
      --genie-caustic-blue: #0080ff;
      --genie-caustic-teal: #00e5a3;
      --genie-caustic-purple: #9d4edd;
      --genie-text-primary: #f0f9ff;
      --genie-text-secondary: #93c5fd;
      --genie-text-muted: #64748b;
      --genie-code-bg: rgba(3, 7, 18, 0.85);
      --genie-glow-spread: 0 20px 50px rgba(0, 240, 255, 0.12), 0 0 35px rgba(0, 128, 255, 0.10);
    }

    /* 💧 Apple 2028 Living Liquid Water */
    [data-theme="apple-2028-liquid"], body.theme-apple-2028-liquid, :root[data-theme="apple-2028-liquid"] {
      --genie-bg: #050a14;
      --genie-bg-gradient: radial-gradient(circle at 50% -10%, #0d2847 0%, #061122 45%, #02060d 100%);
      --genie-glass-card: rgba(10, 20, 38, 0.72);
      --genie-glass-blur: blur(32px) saturate(210%);
      --genie-border-liquid: linear-gradient(135deg, rgba(255, 255, 255, 0.65) 0%, rgba(0, 240, 255, 0.55) 35%, rgba(0, 128, 255, 0.20) 70%, rgba(255, 255, 255, 0.35) 100%);
      --genie-border-subtle: rgba(0, 240, 255, 0.18);
      --genie-caustic-cyan: #00f0ff;
      --genie-caustic-blue: #0080ff;
      --genie-caustic-teal: #00e5a3;
      --genie-caustic-purple: #9d4edd;
      --genie-text-primary: #f0f9ff;
      --genie-text-secondary: #93c5fd;
      --genie-text-muted: #64748b;
      --genie-code-bg: rgba(3, 7, 18, 0.85);
      --genie-glow-spread: 0 20px 50px rgba(0, 240, 255, 0.12), 0 0 35px rgba(0, 128, 255, 0.10);
    }

    /* ⏱️ Apple 2028 OLED Blackout Pillow */
    [data-theme="apple-2028-oled-pillow"], body.theme-apple-2028-oled-pillow, :root[data-theme="apple-2028-oled-pillow"] {
      --genie-bg: #000000;
      --genie-bg-gradient: radial-gradient(circle at 50% 0%, #0d0f17 0%, #050608 50%, #000000 100%);
      --genie-glass-card: rgba(12, 14, 20, 0.88);
      --genie-glass-blur: blur(36px) saturate(180%);
      --genie-border-rim: linear-gradient(135deg, rgba(255, 255, 255, 0.38) 0%, rgba(255, 255, 255, 0.06) 40%, rgba(56, 189, 248, 0.25) 100%);
      --genie-border-subtle: rgba(255, 255, 255, 0.08);
      --genie-accent-gold: #f4c375;
      --genie-accent-cyan: #38bdf8;
      --genie-accent-white: #ffffff;
      --genie-text-primary: #ffffff;
      --genie-text-secondary: #94a3b8;
      --genie-text-muted: #52525b;
      --genie-code-bg: #030305;
      --genie-pillow-shadow: 0 24px 60px rgba(0, 0, 0, 0.85), inset 0 1px 0 rgba(255, 255, 255, 0.18);
    }

    /* ✨ Apple 2028 Quantum Titanium Glass */
    [data-theme="apple-2028-quantum"], body.theme-apple-2028-quantum, :root[data-theme="apple-2028-quantum"] {
      --genie-bg: #030712;
      --genie-bg-gradient: radial-gradient(circle at 50% -10%, #1e1b4b 0%, #09090b 65%, #020204 100%);
      --genie-glass-card: rgba(15, 17, 28, 0.82);
      --genie-glass-blur: blur(30px) saturate(200%);
      --genie-border-quantum: linear-gradient(135deg, rgba(255, 255, 255, 0.5) 0%, rgba(192, 132, 252, 0.5) 45%, rgba(56, 189, 248, 0.3) 80%, rgba(255, 255, 255, 0.2) 100%);
      --genie-accent-purple: #c084fc;
      --genie-accent-cyan: #38bdf8;
      --genie-text-primary: #f8fafc;
      --genie-text-secondary: #cbd5e1;
      --genie-text-muted: #64748b;
      --genie-code-bg: #02040a;
      --genie-glow-spread: 0 24px 64px rgba(0, 0, 0, 0.8), 0 0 45px rgba(192, 132, 252, 0.18);
    }

    /* ☀️ Apple 2028 Frosted Alabaster Light */
    [data-theme="apple-2028-frosted-light"], body.theme-apple-2028-frosted-light, :root[data-theme="apple-2028-frosted-light"] {
      --genie-bg: #f8fafc;
      --genie-bg-gradient: radial-gradient(circle at 50% 0%, #ffffff 0%, #f1f5f9 60%, #e2e8f0 100%);
      --genie-glass-card: rgba(255, 255, 255, 0.82);
      --genie-glass-blur: blur(28px) saturate(160%);
      --genie-border-rim: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(226, 232, 240, 0.6) 50%, rgba(203, 213, 225, 0.4) 100%);
      --genie-accent-orange: #f97316;
      --genie-accent-blue: #0284c7;
      --genie-text-primary: #0f172a;
      --genie-text-secondary: #475569;
      --genie-text-muted: #94a3b8;
      --genie-code-bg: #f1f5f9;
      --genie-card-shadow: 0 20px 45px rgba(15, 23, 42, 0.08), 0 0 1px rgba(0, 0, 0, 0.1);
    }

    /* Common Card Utility Styles */
    .genie-2028-liquid-card, .genie-oled-pillow-card, .genie-quantum-card, .genie-light-card {
      position: relative;
      background: var(--genie-glass-card);
      -webkit-backdrop-filter: var(--genie-glass-blur);
      backdrop-filter: var(--genie-glass-blur);
      border-radius: 24px;
      overflow: hidden;
      transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
    }
    """
}
