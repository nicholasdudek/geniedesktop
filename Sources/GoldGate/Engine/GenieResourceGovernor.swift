import AppKit
import Foundation
import Combine

// MARK: - 🛡️ Genie Resource Governor
/// Dynamically detects when resource-intensive applications (such as Google Chrome,
/// Safari, or Final Cut) are in the foreground and immediately yields CPU, GPU,
/// and background animation cycles to ensure zero contention.
@MainActor
public final class GenieResourceGovernor: ObservableObject {
    public static let shared = GenieResourceGovernor()

    @Published public private(set) var isYieldingResources: Bool = false
    @Published public private(set) var frontmostAppName: String = ""
    @Published public private(set) var frontmostBundleID: String = ""

    private var cancellables = Set<AnyCancellable>()
    private let heavyAppBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "org.mozilla.firefox",
        "com.apple.Safari"
    ]

    private init() {
        setupObservers()
        updateFrontmostApp()
    }

    public func start() {
        updateFrontmostApp()
    }

    private func setupObservers() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrontmostApp()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didDeactivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrontmostApp()
            }
            .store(in: &cancellables)
    }

    public func updateFrontmostApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let bid = frontApp.bundleIdentifier ?? ""
        let name = frontApp.localizedName ?? ""

        self.frontmostBundleID = bid
        self.frontmostAppName = name

        // Check if Chrome or other major browser/resource-heavy app is active
        let isHeavy = heavyAppBundleIDs.contains(bid) ||
                      bid.lowercased().contains("chrome") ||
                      name.lowercased().contains("chrome")

        // Also check if Genie itself is frontmost
        let isGenie = (bid == "com.nicholasdudek.genie" || bid == "com.goldengate.Genie")

        let shouldYield = isHeavy && !isGenie
        if self.isYieldingResources != shouldYield {
            self.isYieldingResources = shouldYield
            if shouldYield {
                print("🛡️ [GenieResourceGovernor] Yielding background CPU/GPU cycles to \(name) (\(bid))")
            } else {
                print("⚡️ [GenieResourceGovernor] Resuming full 120 FPS performance (Active: \(name))")
            }
        }
    }
}
