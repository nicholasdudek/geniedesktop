import AppKit
import Foundation

// MARK: - ✉️ Genie Local Email Message
public struct GenieLocalEmailMessage: Identifiable, Sendable {
    public let id: UUID
    public let from: String
    public let to: String
    public let subject: String
    public let body: String
    public let attachments: [String]
    public let timestamp: Date
    public var isRead: Bool
    public let priority: String

    public init(
        id: UUID = UUID(),
        from: String,
        to: String,
        subject: String,
        body: String,
        attachments: [String] = [],
        timestamp: Date = Date(),
        isRead: Bool = false,
        priority: String = "Normal"
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.subject = subject
        self.body = body
        self.attachments = attachments
        self.timestamp = timestamp
        self.isRead = isRead
        self.priority = priority
    }
}

// MARK: - 👤 Genie Local Email Account
public struct GenieLocalEmailAccount: Identifiable, Sendable {
    public var id: String { address }
    public let address: String
    public let displayName: String
    public let isAgent: Bool
    public let createdAt: Date

    public init(address: String, displayName: String, isAgent: Bool = true, createdAt: Date = Date()) {
        self.address = address
        self.displayName = displayName
        self.isAgent = isAgent
        self.createdAt = createdAt
    }
}

// MARK: - 📮 Genie In-RAM Sovereign Local Email Server & Client
/// Completely sovereign, zero-external-network email server running directly inside
/// Unified RAM / VM. Spins up ephemeral mailboxes for Genie agents, workers, and the user.
@MainActor
public final class GenieInRAMLocalEmailServer: ObservableObject {
    public static let shared = GenieInRAMLocalEmailServer()

    @Published public private(set) var accounts: [GenieLocalEmailAccount] = []
    @Published public private(set) var messages: [GenieLocalEmailMessage] = []
    @Published public private(set) var unreadCount: Int = 0
    @Published public private(set) var activeUserAddress: String = "user@genie.local"

    private init() {
        setupDefaultAccounts()
        seedInitialSteveJobsWelcome()
        updateUnreadCount()
    }

    // MARK: - Account Management

    private func setupDefaultAccounts() {
        let defaultAccounts = [
            GenieLocalEmailAccount(address: "user@genie.local", displayName: "You (Desktop User)", isAgent: false),
            GenieLocalEmailAccount(address: "genie@local.internal", displayName: "Genie Master AI", isAgent: true),
            GenieLocalEmailAccount(address: "steve@genie.local", displayName: "Steve Jobs (In Spirit)", isAgent: true),
            GenieLocalEmailAccount(address: "vm-worker@genie.local", displayName: "In-RAM VM Worker Node", isAgent: true)
        ]
        self.accounts = defaultAccounts
    }

    /// Dynamically spins up a new sovereign email address for an agent or worker
    @discardableResult
    public func spinUpAddress(
        prefix: String,
        displayName: String,
        isAgent: Bool = true
    ) -> String {
        let cleanPrefix = prefix.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let address = "\(cleanPrefix)@genie.local"

        if !accounts.contains(where: { $0.address == address }) {
            let acc = GenieLocalEmailAccount(address: address, displayName: displayName, isAgent: isAgent)
            accounts.append(acc)
        }
        return address
    }

    // MARK: - Messaging API

    /// Dispatches a local email message directly into Unified RAM store
    @discardableResult
    public func sendEmail(
        from: String,
        to: String,
        subject: String,
        body: String,
        attachments: [String] = [],
        priority: String = "Normal"
    ) -> GenieLocalEmailMessage {
        let msg = GenieLocalEmailMessage(
            from: from,
            to: to,
            subject: subject,
            body: body,
            attachments: attachments,
            timestamp: Date(),
            isRead: false,
            priority: priority
        )

        messages.insert(msg, at: 0)
        updateUnreadCount()

        // Post notification for sound / UI refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("GenieLocalMailReceived"),
            object: msg
        )

        return msg
    }

    /// Retrieve inbox messages for a specific address
    public func inbox(for address: String? = nil) -> [GenieLocalEmailMessage] {
        let target = address ?? activeUserAddress
        return messages.filter { $0.to.lowercased() == target.lowercased() || target == "all" }
    }

    /// Mark an email as read
    public func markAsRead(id: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx].isRead = true
            updateUnreadCount()
        }
    }

    /// Mark all as read
    public func markAllAsRead() {
        for idx in messages.indices {
            messages[idx].isRead = true
        }
        updateUnreadCount()
    }

    /// Delete an email
    public func deleteEmail(id: UUID) {
        messages.removeAll(where: { $0.id == id })
        updateUnreadCount()
    }

    private func updateUnreadCount() {
        self.unreadCount = messages.filter { !$0.isRead && $0.to == activeUserAddress }.count
    }

    // MARK: - "What would Steve Jobs think!?" Initial Welcome

    private func seedInitialSteveJobsWelcome() {
        let welcome = GenieLocalEmailMessage(
            from: "steve@genie.local",
            to: "user@genie.local",
            subject: "A bicycle for the mind — inside your RAM",
            body: """
            To the team at Golden Gate:

            Computers are the most remarkable tool that we've ever come up with. It's the equivalent of a bicycle for our minds.

            What you've built here with Genie — running sovereign local hypervisors directly in Unified RAM, eliminating slow disk storms with IPE bitmasks, using the Trash Can as an atomic airlock to the Desktop, and giving agents their own in-memory email network — is deeply pure.

            Simplicity isn't just the lack of clutter. It's about bringing order to complexity. Having the Apple Menu Bar right inside the chat, with live Unified RAM bandwidth and battery telemetry, gives people mastery over their machine.

            Keep making great things. Don't compromise.

            — Steve
            """,
            attachments: ["/Volumes/GenieInRAMVM", "~/.Trash/.genie_airlock"],
            timestamp: Date().addingTimeInterval(-3600),
            isRead: false,
            priority: "High"
        )
        self.messages = [welcome]
    }
}
