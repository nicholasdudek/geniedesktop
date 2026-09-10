import Foundation
import AppKit
import Darwin

/// UserAccessSummary
/// Represents audited POSIX and macOS directory access metrics for a specific agent or system user.
public struct UserAccessSummary: Codable, Sendable {
    public let username: String
    public let uid: UInt32
    public let gid: UInt32
    public let groups: [String]
    public let homeDirectory: String
    public let isAdmin: Bool
    public let isGenieAgent: Bool
}

/// GenieAdminAccessGovernor (Pillar 1 - System Administrator & Multi-User Access Governor)
///
/// Grants Genie administrative supervision of the macOS computer, allowing it to:
/// 1. Inspect and govern user and sub-agent file access rights.
/// 2. Safely execute administrative system maintenance tasks via authenticated elevation.
/// 3. Maintain an immutable, audited record of every privileged action in `/Users/Shared/Genie/Audit/admin_audit.log`.
@MainActor
public final class GenieAdminAccessGovernor: ObservableObject {
    public static let shared = GenieAdminAccessGovernor()

    @Published public var isAdminAvailable: Bool = false
    @Published public var isPrivilegedExecutionActive: Bool = false
    @Published public var totalPrivilegedCommandsExecuted: Int = 0
    @Published public var lastAdminAuditEntry: String = ""

    public static var auditDirectoryPath: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("Audit", isDirectory: true).path
    }
    public static var auditLogPath: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("Audit/admin_audit.log", isDirectory: false).path
    }

    private init() {
        ensureAuditDirectoryExists()
        self.isAdminAvailable = checkAdminStatus()
    }

    public func ensureAuditDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: Self.auditDirectoryPath) {
            try? fm.createDirectory(atPath: Self.auditDirectoryPath, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o755
            ])
        }
        if !fm.fileExists(atPath: Self.auditLogPath) {
            let header = "=== GENIE SYSTEM ADMINISTRATOR AUDIT TRAIL ===\nCreated: \(Date())\n\n"
            try? header.write(toFile: Self.auditLogPath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Admin Verification

    /// Determines if the current macOS host user is a member of the local 'admin' group.
    ///
    /// This used to spawn `/usr/sbin/dseditgroup` and fall back to `getgroups`.
    /// The fallback is the whole answer: this only ever asks about the *current*
    /// user, and the process's own group list is authoritative for that — so the
    /// subprocess is gone and this works identically in both builds.
    public func checkAdminStatus() -> Bool {
        if getuid() == 0 { return true }

        let ngroups = getgroups(0, nil)
        guard ngroups > 0 else { return false }
        var groups = [gid_t](repeating: 0, count: Int(ngroups))
        guard getgroups(ngroups, &groups) > 0 else { return false }
        // gid 80 is the local `admin` group on macOS.
        return groups.contains(80) || groups.contains(0)
    }

    // MARK: - Multi-User Access Inspection

    /// Inspects and treats access permissions for any system user or sub-agent.
    /// Looks the user up through the C library rather than parsing `id -Gn`.
    /// This also fixes a real bug in the old version: it reported the *calling*
    /// process's uid and gid no matter which username was passed in.
    public func inspectUserAccess(username: String = NSUserName()) -> UserAccessSummary {
        let isAgent = username.contains("agent") || username.contains("genie")
        let homeDir = NSHomeDirectoryForUser(username) ?? "/Users/\(username)"

        var uid = getuid()
        var gid = getgid()
        var groupList: [String] = []

        if let entry = getpwnam(username) {
            uid = entry.pointee.pw_uid
            gid = entry.pointee.pw_gid
        }

        // Resolve the user's full group list, then map each gid to its name.
        var ngroups: Int32 = 64
        var rawGIDs = [Int32](repeating: 0, count: Int(ngroups))
        let listed = username.withCString { name in
            getgrouplist(name, Int32(bitPattern: gid), &rawGIDs, &ngroups)
        }
        if listed >= 0 {
            for raw in rawGIDs.prefix(Int(ngroups)) {
                if let group = getgrgid(gid_t(bitPattern: raw)) {
                    groupList.append(String(cString: group.pointee.gr_name))
                }
            }
        }

        let isAdmin = uid == 0 || groupList.contains("admin")

        return UserAccessSummary(
            username: username,
            uid: uid,
            gid: gid,
            groups: groupList,
            homeDirectory: homeDir,
            isAdmin: isAdmin,
            isGenieAgent: isAgent
        )
    }

    /// Sets POSIX permissions and directory isolation for a sub-agent's workspace.
    public func configureAgentPermissions(directoryPath: String, readOnlyForOtherAgents: Bool = true) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directoryPath) else { return false }

        let permissions: NSNumber = readOnlyForOtherAgents ? 0o750 : 0o770
        do {
            try fm.setAttributes([.posixPermissions: permissions], ofItemAtPath: directoryPath)
            writeAuditLog(command: "chmod \(permissions) \(directoryPath)", exitCode: 0, reason: "Agent isolation permissions configured")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Governed Administrative Execution

    /// Executes a system-level administrator command with screening and immutable audit logging.
    public func executeWithAdminPrivileges(
        command: String,
        reason: String
    ) async -> (output: String, exitCode: Int32) {
        let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return ("Empty command.", 0)
        }

        // 0. Distribution gate. Privilege escalation is banned outright by
        //    App Store Review Guideline 2.4.5(iv), and there is no sandbox-legal
        //    equivalent, so the App Store build refuses before doing anything.
        guard GenieCapabilities.canElevatePrivileges else {
            let blocked = GenieCapabilities.unavailableMessage("Administrator commands")
            writeAuditLog(command: clean, exitCode: 126,
                          reason: "BLOCKED: unavailable in App Store build")
            return (blocked, 126)
        }

        // 1. Safety Screening: Destructive root commands are rejected even in admin mode
        let screening = GenieSandboxedExecutionEngine.shared.screenCommand(command: clean)
        guard screening.isSafe else {
            let warning = "🛑 Safety Governor: Admin command rejected: \(screening.reason ?? "Blocked")"
            writeAuditLog(command: clean, exitCode: 1, reason: "REJECTED by safety governor: \(reason)")
            return (warning, 1)
        }

        // 2. Check if admin privileges are enabled in preferences
        let adminEnabled = UserDefaults.standard.bool(forKey: PrefKey.agentAdminPrivilegesEnabled)
        guard adminEnabled else {
            let blocked = "🛑 Admin Privileges Disabled: Enable Admin Mode in Genie Settings."
            writeAuditLog(command: clean, exitCode: 126, reason: "BLOCKED: Admin mode disabled")
            return (blocked, 126)
        }

        // 3. Execute via AppleScript administrator elevation
        isPrivilegedExecutionActive = true
        defer { isPrivilegedExecutionActive = false }

        let escaped = clean.replacingOccurrences(of: "\\", with: "\\\\")
                           .replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = "do shell script \"\(escaped)\" with administrator privileges"

        var exitCode: Int32 = 0
        var outputText = ""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        let pipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
            exitCode = process.terminationStatus

            let outData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(decoding: outData, as: UTF8.self)
            let stderr = String(decoding: errData, as: UTF8.self)
            outputText = exitCode == 0 ? stdout : (stderr.isEmpty ? stdout : stderr)
        } catch {
            exitCode = 1
            outputText = "Execution failed: \(error.localizedDescription)"
        }

        totalPrivilegedCommandsExecuted += 1
        writeAuditLog(command: clean, exitCode: exitCode, reason: reason)
        return (outputText, exitCode)
    }

    // MARK: - Audit Trail

    private func writeAuditLog(command: String, exitCode: Int32, reason: String) {
        ensureAuditDirectoryExists()
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [UID:\(getuid())] [EXIT:\(exitCode)] [REASON: \(reason)] CMD: \(command)\n"
        self.lastAdminAuditEntry = logLine

        if let handle = FileHandle(forWritingAtPath: Self.auditLogPath) {
            handle.seekToEndOfFile()
            if let data = logLine.data(using: .utf8) {
                handle.write(data)
            }
            try? handle.close()
        }
    }
}
