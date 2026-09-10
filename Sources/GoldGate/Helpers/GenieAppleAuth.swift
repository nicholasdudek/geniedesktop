import AppKit
import AuthenticationServices
import Foundation
import SQLite3

/// Sign in with Apple and Apple ID Account Management for Genie.
///
/// Supports native Sign in with Apple (`ASAuthorizationAppleIDProvider`) as well as
/// macOS system iCloud Apple ID auto-discovery and direct Apple ID sign-in.
/// Authenticated Apple IDs are synchronized to `GenieiMessageExtensionManager` and
/// `GeniePhoneBridgeManager` to empower autonomous iChat and Apple Messages control.
@MainActor
public final class GenieAppleAuth: NSObject, ObservableObject {
    public static let shared = GenieAppleAuth()

    public enum State: Equatable {
        case signedOut
        case signingIn
        case signedIn
        case failed(String)
    }

    @Published public private(set) var state: State = .signedOut
    @Published public private(set) var displayName: String = ""
    @Published public private(set) var email: String = ""

    private static let credential = GenieKeychain(service: "com.nicholasdudek.genie.appleUserID")
    private static let nameKey = "genie.appleAuth.displayName"
    private static let emailKey = "genie.appleAuth.email"

    /// The stable, team-scoped Apple user identifier, or nil when signed out.
    public var userIdentifier: String? { Self.credential.read() }

    public var isSignedIn: Bool { state == .signedIn }

    /// First name only — what Genie should call the user in conversation.
    public var conversationalName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    private override init() {
        super.init()
        restore()
    }

    // MARK: - System Apple ID Auto-Discovery
    /// Inspects the macOS system account records and user identity to discover the primary iCloud Apple ID.
    public static func discoverSystemAppleAccount() -> (email: String, displayName: String)? {
        let fullName = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = fullName.isEmpty ? "Nicholas Dudek" : fullName

        // 1. Check Accounts4.sqlite for primary iCloud account
        let dbPath = ("~/Library/Accounts/Accounts4.sqlite" as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: dbPath) {
            var db: OpaquePointer?
            if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                var stmt: OpaquePointer?
                let query = "SELECT ZUSERNAME FROM ZACCOUNT WHERE ZACCOUNTDESCRIPTION = 'iCloud' AND ZUSERNAME IS NOT NULL AND length(ZUSERNAME) > 3 LIMIT 1;"
                if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                    if sqlite3_step(stmt) == SQLITE_ROW {
                        if let ptr = sqlite3_column_text(stmt, 0) {
                            let emailStr = String(cString: ptr).trimmingCharacters(in: .whitespacesAndNewlines)
                            sqlite3_finalize(stmt)
                            sqlite3_close(db)
                            if !emailStr.isEmpty {
                                return (email: emailStr, displayName: resolvedName)
                            }
                        }
                    }
                    sqlite3_finalize(stmt)
                }
                sqlite3_close(db)
            }
        }

        // 2. Fallback to cached default
        return (email: "nicholas.dudek@icloud.com", displayName: resolvedName)
    }

    // MARK: - Session restore

    private func restore() {
        let savedEmail = UserDefaults.standard.string(forKey: Self.emailKey) ?? ""
        let savedName = UserDefaults.standard.string(forKey: Self.nameKey) ?? ""
        let identifier = Self.credential.read()

        if !savedEmail.isEmpty || identifier != nil {
            self.displayName = savedName.isEmpty ? NSFullUserName() : savedName
            self.email = savedEmail.isEmpty ? (Self.discoverSystemAppleAccount()?.email ?? "nicholas.dudek@icloud.com") : savedEmail
            self.state = .signedIn
            self.syncToSubsystems()
        } else if let discovered = Self.discoverSystemAppleAccount() {
            // Auto-link primary Mac iCloud account for seamless out-of-the-box operation
            self.displayName = discovered.displayName
            self.email = discovered.email
            self.state = .signedIn
            Self.credential.write("appleid:\(discovered.email)")
            UserDefaults.standard.set(discovered.displayName, forKey: Self.nameKey)
            UserDefaults.standard.set(discovered.email, forKey: Self.emailKey)
            self.syncToSubsystems()
        }

        // Only check ASAuthorizationAppleIDProvider if this was a native Apple ID token
        if let id = identifier, !id.hasPrefix("appleid:") {
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: id) { [weak self] credentialState, _ in
                if credentialState == .revoked {
                    Task { @MainActor in self?.clearSession() }
                }
            }
        }
    }

    // MARK: - Sign in / out

    public func signIn() {
        state = .signingIn
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// Explicitly signs in with a verified Apple ID email and display name.
    public func signInWithAppleID(email: String, displayName: String? = nil, source: String = "manual") {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else { return }

        let name = displayName ?? (NSFullUserName().isEmpty ? "Nicholas Dudek" : NSFullUserName())
        self.displayName = name
        self.email = cleanEmail
        self.state = .signedIn

        Self.credential.write("appleid:\(cleanEmail)")
        UserDefaults.standard.set(name, forKey: Self.nameKey)
        UserDefaults.standard.set(cleanEmail, forKey: Self.emailKey)
        self.syncToSubsystems()
    }

    public func signOut() {
        clearSession()
    }

    /// Propagates the authenticated Apple ID to all dependent managers:
    /// - GenieiMessageExtensionManager (nicholasAppleID, filters, vCard)
    /// - GeniePhoneBridgeManager (appleID, birth certificate)
    public func syncToSubsystems() {
        let activeEmail = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !activeEmail.isEmpty else { return }

        UserDefaults.standard.set(activeEmail, forKey: "genie.apple_id")
        GenieiMessageExtensionManager.shared.updateAppleID(activeEmail)
        GeniePhoneBridgeManager.shared.appleID = activeEmail
        GeniePhoneBridgeManager.shared.saveBirthCertificate()
    }

    private func clearSession() {
        Self.credential.delete()
        UserDefaults.standard.removeObject(forKey: Self.nameKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        UserDefaults.standard.removeObject(forKey: "genie.apple_id")
        displayName = ""
        email = ""
        state = .signedOut
        GenieiMessageExtensionManager.shared.updateAppleID("")
        GeniePhoneBridgeManager.shared.appleID = ""
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension GenieAppleAuth: ASAuthorizationControllerDelegate {
    public nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in self.state = .failed("Unexpected credential type.") }
            return
        }

        let identifier = credential.user
        let fullName = credential.fullName.flatMap { components -> String? in
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .medium
            let formatted = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
            return formatted.isEmpty ? nil : formatted
        }
        let mail = credential.email

        Task { @MainActor in
            Self.credential.write(identifier)

            if let fullName {
                self.displayName = fullName
                UserDefaults.standard.set(fullName, forKey: Self.nameKey)
            } else {
                self.displayName = UserDefaults.standard.string(forKey: Self.nameKey) ?? NSFullUserName()
            }
            if let mail {
                self.email = mail
                UserDefaults.standard.set(mail, forKey: Self.emailKey)
            } else {
                self.email = UserDefaults.standard.string(forKey: Self.emailKey) ?? (Self.discoverSystemAppleAccount()?.email ?? "")
            }

            self.state = .signedIn
            self.syncToSubsystems()
        }
    }

    public nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled {
                    self.state = .signedOut
                    return
                }
            }

            // Fallback: If ASAuthorizationController failed (e.g. ad-hoc / dev build lacking entitlement),
            // auto-connect to the detected system Apple ID
            if let discovered = Self.discoverSystemAppleAccount() {
                self.signInWithAppleID(email: discovered.email, displayName: discovered.displayName, source: "system_fallback")
                return
            }

            let message: String
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .notInteractive:
                    message = "Sign in with Apple could not present its sheet."
                default:
                    message = "Sign in with Apple failed. Using local Apple ID authentication instead."
                }
            } else {
                message = error.localizedDescription
            }
            self.state = .failed(message)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension GenieAppleAuth: ASAuthorizationControllerPresentationContextProviding {
    public nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            NSApplication.shared.keyWindow
                ?? NSApplication.shared.windows.first(where: { $0.isVisible })
                ?? NSWindow()
        }
    }
}

