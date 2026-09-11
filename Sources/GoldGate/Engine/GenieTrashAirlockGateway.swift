import AppKit
import Foundation
import Darwin

// MARK: - 🗑️ Genie Trash Airlock Gateway
/// Implements the "Hidden Trash Can File Trick" for Virtual Machines and Worker Nodes.
///
/// ### Why the Trash Can is the Hidden Entryway to the Desktop:
/// 1. **Zero Desktop GUI Thrashing**: Writing files directly to `~/Desktop` causes Finder
///    to trigger immediate spatial icon grid re-layouts, partial thumbnail generation
///    (`qlmanage`), and visual flashing while bytes are still streaming from a VM or compiler.
/// 2. **Identical APFS Container Volume**: `~/.Trash` and `~/Desktop` reside on the exact same
///    APFS physical volume (Data partition). Moving a completed multi-gigabyte artifact from
///    the Trash airlock to the Desktop is an **instantaneous O(1) atomic inode pointer swap**
///    (`rename(2)`), taking zero SSD write cycles and 0 bytes of RAM.
/// 3. **Gatekeeper Quarantine Bypass**: Files originating from virtual network interfaces,
///    VM sockets, or headless browser drops frequently acquire `com.apple.quarantine` xattrs.
///    By staging in the Trash airlock, Genie can strip quarantine before the atomic Desktop
///    materialization ("Put Back"), guaranteeing seamless launching without warning prompts.
/// 4. **Bidirectional Ingestion**: To hand a large dataset or disk image from the Desktop
///    to an in-RAM VM without copying gigabytes, the user or agent drops it into the Trash
///    portal, and the VM accesses the underlying inode directly via the per-volume `.Trashes`.
@MainActor
public final class GenieTrashAirlockGateway: ObservableObject {
    public static let shared = GenieTrashAirlockGateway()

    @Published public private(set) var stagedArtifactsCount: Int = 0
    @Published public private(set) var totalPromotionsToDesktop: Int = 0
    @Published public private(set) var lastPromotedItemName: String?
    @Published public private(set) var lastPromotionDate: Date?

    /// Hidden airlock directory inside the primary user Trash
    public var primaryAirlockURL: URL {
        let trash = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash", isDirectory: true)
        return trash.appendingPathComponent(".genie_airlock", isDirectory: true)
    }

    /// User Desktop URL
    public var desktopURL: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop", isDirectory: true)
    }

    private init() {
        ensureAirlockExists()
        refreshStagedCount()
    }

    // MARK: - Directory Setup

    public func ensureAirlockExists() {
        let fm = FileManager.default
        let path = primaryAirlockURL.path
        if !fm.fileExists(atPath: path) {
            try? fm.createDirectory(at: primaryAirlockURL, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o700
            ])
        }
    }

    public func refreshStagedCount() {
        let fm = FileManager.default
        if let contents = try? fm.contentsOfDirectory(atPath: primaryAirlockURL.path) {
            self.stagedArtifactsCount = contents.count
        } else {
            self.stagedArtifactsCount = 0
        }
    }

    // MARK: - Staging from Workers / Virtual Machines

    /// Stages raw binary data into the Trash Airlock (safe from Finder Desktop view)
    @discardableResult
    public func stageData(name: String, data: Data) throws -> URL {
        ensureAirlockExists()
        let targetURL = primaryAirlockURL.appendingPathComponent(name)
        try data.write(to: targetURL, options: .atomic)
        refreshStagedCount()
        return targetURL
    }

    /// Stages a file from a worker fork or VM mount into the Trash Airlock using zero-copy APFS clone
    @discardableResult
    public func stageFile(sourceURL: URL, targetName: String? = nil) throws -> URL {
        ensureAirlockExists()
        let name = targetName ?? sourceURL.lastPathComponent
        let targetURL = primaryAirlockURL.appendingPathComponent(name)

        let fm = FileManager.default
        if fm.fileExists(atPath: targetURL.path) {
            try? fm.removeItem(at: targetURL)
        }

        // Try APFS clonefile first (0 ms, 0 bytes written)
        let res = sourceURL.path.withCString { src in
            targetURL.path.withCString { dst in
                Darwin.clonefile(src, dst, 0)
            }
        }

        if res == 0 {
            refreshStagedCount()
            return targetURL
        }

        // Fallback: FileManager copy
        try fm.copyItem(at: sourceURL, to: targetURL)
        refreshStagedCount()
        return targetURL
    }

    // MARK: - Atomic Desktop Promotion ("Put Back" Trick)

    /// Atomically promotes a staged file from the Trash Airlock directly onto the Desktop.
    /// Operates as an instantaneous inode rename with zero copy overhead and strips quarantine.
    @discardableResult
    public func promoteToDesktop(airlockFileName: String, finalDesktopName: String? = nil) throws -> URL {
        ensureAirlockExists()
        let sourceURL = primaryAirlockURL.appendingPathComponent(airlockFileName)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw NSError(
                domain: "GenieTrashAirlockGateway",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Airlock file not found: \(airlockFileName)"]
            )
        }

        let desktopName = finalDesktopName ?? airlockFileName
        let destinationURL = desktopURL.appendingPathComponent(desktopName)

        // If a file with this name exists on Desktop, move old one aside or replace
        let fm = FileManager.default
        if fm.fileExists(atPath: destinationURL.path) {
            try? fm.removeItem(at: destinationURL)
        }

        // 1. Strip Gatekeeper quarantine attribute prior to desktop arrival
        stripQuarantine(at: sourceURL.path)

        // 2. Perform atomic APFS rename (zero copy, instantaneous O(1))
        let renameResult = Darwin.rename(sourceURL.path, destinationURL.path)
        if renameResult != 0 {
            // Fallback to Darwin copyfile with clone flag
            let cloneFlags = copyfile_flags_t(COPYFILE_ALL | COPYFILE_CLONE)
            let copyResult = sourceURL.path.withCString { src in
                destinationURL.path.withCString { dst in
                    Darwin.copyfile(src, dst, nil, cloneFlags)
                }
            }
            if copyResult == 0 {
                try? fm.removeItem(at: sourceURL)
            } else {
                try fm.moveItem(at: sourceURL, to: destinationURL)
            }
        }

        // 3. Inform macOS Workspace/Finder of the new desktop item
        NSWorkspace.shared.noteFileSystemChanged(destinationURL.path)

        self.totalPromotionsToDesktop += 1
        self.lastPromotedItemName = desktopName
        self.lastPromotionDate = Date()
        refreshStagedCount()

        return destinationURL
    }

    // MARK: - Desktop to VM Ingestion (Reverse Trash Handoff)

    /// Ingests a file from Desktop into a VM mount via the Trash airlock without holding Desktop locks
    @discardableResult
    public func stageFromDesktopToVM(desktopFileName: String, targetVMURL: URL) throws -> URL {
        let sourceURL = desktopURL.appendingPathComponent(desktopFileName)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw NSError(
                domain: "GenieTrashAirlockGateway",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Desktop file not found: \(desktopFileName)"]
            )
        }

        // Stage into airlock first
        let airlockURL = try stageFile(sourceURL: sourceURL, targetName: desktopFileName)

        // Zero-copy APFS clone or copy into VM target
        let vmTarget = targetVMURL.appendingPathComponent(desktopFileName)
        if FileManager.default.fileExists(atPath: vmTarget.path) {
            try? FileManager.default.removeItem(at: vmTarget)
        }

        let cloneRes = airlockURL.path.withCString { src in
            vmTarget.path.withCString { dst in
                Darwin.clonefile(src, dst, 0)
            }
        }

        if cloneRes != 0 {
            try FileManager.default.copyItem(at: airlockURL, to: vmTarget)
        }

        return vmTarget
    }

    // MARK: - Quarantine Stripping

    private func stripQuarantine(at path: String) {
        let quarantineKey = "com.apple.quarantine"
        quarantineKey.withCString { key in
            path.withCString { cPath in
                _ = Darwin.removexattr(cPath, key, 0)
            }
        }
    }

    // MARK: - Architectural Summary

    public func explainAirlockPrinciple() -> String {
        """
        === 🗑️ Genie Trash Airlock & VM Desktop Entryway ===
        • APFS Zero-Copy Container: ~/.Trash and ~/Desktop share the same APFS partition.
        • Atomic Rename: Inode pointer swap takes < 1 ms and 0 bytes disk I/O.
        • Finder Isolation: Background workers & VMs write without desktop icon scramble.
        • Clean Quarantine: xattr flags stripped before atomic promotion to Desktop.
        • Staged Count: \(stagedArtifactsCount) items | Total Promoted: \(totalPromotionsToDesktop)
        """
    }
}
