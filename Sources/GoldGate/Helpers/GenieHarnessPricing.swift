import CryptoKit
import Foundation

// MARK: - 💰 Harness Pricing
// Genie's harness is the billable surface, not the models. Three tiers:
//
//   • BYOK            — the caller supplies the provider's own API key. Always free.
//                       We move their bytes; we never touch their quota or their bill.
//   • Managed online  — the caller rides Genie's own connection to a third-party
//                       provider. That connection is the product, so it needs an
//                       unlock: $5/mo, or $25 once for a key that never expires.
//   • Local metered   — Ollama on this machine. No API bill exists, but the harness
//                       burns real wall-clock time on the user's hardware, so it is
//                       billed per hour with the developer markup applied on top.

// MARK: Access Tier

public enum HarnessAccessTier: String, Codable, Sendable {
    case bringYourOwnKey
    case managedConnection
    case localMetered

    public var displayName: String {
        switch self {
        case .bringYourOwnKey: return "Bring Your Own Key"
        case .managedConnection: return "Genie Connection"
        case .localMetered: return "Local (Metered)"
        }
    }

    /// BYOK and local never hit the paywall — only Genie's own connection does.
    public var requiresUnlock: Bool { self == .managedConnection }
}

// MARK: Unlock State

public enum HarnessUnlock: Equatable, Sendable {
    case locked
    /// $5/mo. `renews` is when the current period lapses.
    case monthly(renews: Date)
    /// $25 once. Never expires, survives reinstall via key redemption.
    case forever

    public func isActive(asOf now: Date = Date()) -> Bool {
        switch self {
        case .locked: return false
        case .forever: return true
        case .monthly(let renews): return renews > now
        }
    }
}

// MARK: Rate Card

public struct HarnessRateCard: Equatable, Sendable {
    /// Recurring fee to keep Genie's own connection online.
    public var monthlyConnectionFee: Double
    /// One-time price of the forever unlock key.
    public var foreverUnlockPrice: Double
    /// What an hour of this machine's compute costs to run (power + amortization).
    public var computeHourlyRate: Double
    /// The developer's cut on metered harness time, as a percentage on top of cost.
    public var markupPercent: Double

    public static let standard = HarnessRateCard(
        monthlyConnectionFee: 5.00,
        foreverUnlockPrice: 25.00,
        computeHourlyRate: 0.45,
        markupPercent: 30.0
    )

    public init(monthlyConnectionFee: Double, foreverUnlockPrice: Double,
                computeHourlyRate: Double, markupPercent: Double) {
        self.monthlyConnectionFee = monthlyConnectionFee
        self.foreverUnlockPrice = foreverUnlockPrice
        self.computeHourlyRate = computeHourlyRate
        self.markupPercent = markupPercent
    }

    /// Months of subscription before the forever key pays for itself.
    public var foreverBreakEvenMonths: Double {
        guard monthlyConnectionFee > 0 else { return .infinity }
        return foreverUnlockPrice / monthlyConnectionFee
    }

    /// Metered harness time -> what the user owes. Negative durations bill nothing.
    public func localCharge(seconds: TimeInterval) -> Double {
        guard seconds > 0 else { return 0 }
        let base = (seconds / 3600.0) * computeHourlyRate
        return base * (1.0 + markupPercent / 100.0)
    }

    /// The markup portion alone — the developer's revenue on a metered run.
    public func developerCut(seconds: TimeInterval) -> Double {
        guard seconds > 0 else { return 0 }
        return (seconds / 3600.0) * computeHourlyRate * (markupPercent / 100.0)
    }
}

// MARK: Tier Resolution

public enum GenieHarnessPricing {
    /// Which tier a request falls into. A caller-supplied key always wins: if you
    /// brought your own credential you are on the free path regardless of provider.
    public static func tier(for provider: AIModelProvider, hasOwnKey: Bool) -> HarnessAccessTier {
        if provider == .local { return .localMetered }
        return hasOwnKey ? .bringYourOwnKey : .managedConnection
    }

    // MARK: Forever key
    //
    // Offline-verifiable so a redeemed key keeps working with no network. The
    // checksum stops typos and casual sharing of made-up keys — it is obfuscation,
    // not cryptography: the salt ships in the binary, so anyone willing to read it
    // can mint keys. Real enforcement is the StoreKit receipt; this is the
    // convenience path for direct sales and support-issued replacements.
    private static let keySalt = "genie.harness.forever.v1"
    private static let keyPrefix = "GENIE"

    public static func foreverKey(for seed: String) -> String {
        let body = Self.group(from: seed.uppercased(), length: 8)
        let check = Self.group(from: body + keySalt, length: 4)
        return "\(keyPrefix)-\(body.prefix(4))-\(body.suffix(4))-\(check)"
    }

    public static func isValidForeverKey(_ raw: String) -> Bool {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 4, parts[0] == keyPrefix,
              parts[1].count == 4, parts[2].count == 4, parts[3].count == 4 else { return false }
        let body = String(parts[1] + parts[2])
        return Self.group(from: body + keySalt, length: 4) == String(parts[3])
    }

    /// Deterministic base32-ish group, ambiguous glyphs (I/O/0/1) removed.
    private static func group(from input: String, length: Int) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let digest = Array(SHA256.hash(data: Data(input.utf8)))
        return String((0..<length).map { alphabet[Int(digest[$0]) % alphabet.count] })
    }
}
