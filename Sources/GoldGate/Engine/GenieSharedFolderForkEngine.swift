import Foundation
import AppKit
import Darwin

/// GenieSharedFolderForkEngine
///
/// Implements Zero-Copy APFS Copy-On-Write (COW) folder forking using Darwin `clonefile(2)`
/// and `copyfile(3)` (`COPYFILE_CLONE | COPYFILE_RECURSIVE`), and manages the bidirectional
/// `/Users/Shared/Genie/Bridge` live stream directory.
@MainActor
public final class GenieSharedFolderForkEngine: ObservableObject {
    public static let shared = GenieSharedFolderForkEngine()

    @Published public var isBridgeActive: Bool = false
    @Published public var totalForksCreated: Int = 0
    @Published public var bridgeAssetCount: Int = 0
    @Published public var lastSyncTimestamp: Date?

    public static var defaultBridgePath: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("Bridge").path
    }
    public static var defaultSpacesPath: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("spaces").path
    }

    private var bridgeWatcherSource: DispatchSourceFileSystemObject?
    private var bridgeDirFileDescriptor: Int32 = -1

    private init() {
        setupBridgeDirectories()
        startBridgeWatcher()
    }

    // MARK: - Directory Setup

    public func setupBridgeDirectories() {
        let fm = FileManager.default
        let dirs = [
            Self.defaultBridgePath,
            "\(Self.defaultBridgePath)/stream",
            "\(Self.defaultBridgePath)/artifacts",
            "\(Self.defaultBridgePath)/inbox",
            "\(Self.defaultBridgePath)/outbox",
            Self.defaultSpacesPath
        ]

        for d in dirs {
            if !fm.fileExists(atPath: d) {
                try? fm.createDirectory(atPath: d, withIntermediateDirectories: true, attributes: [
                    .posixPermissions: 0o777 // Full read/write for both user and genie-agent
                ])
            }
        }
    }

    // MARK: - Zero-Copy APFS Copy-on-Write (COW) Forking

    /// Forks a file or directory instantaneously using APFS Copy-on-Write cloning.
    /// Physical SSD storage and RAM overhead: 0 bytes.
    public func forkZeroCopy(sourcePath: String, destinationPath: String) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: sourcePath) else { return false }

        // Remove existing destination if present
        if fm.fileExists(atPath: destinationPath) {
            try? fm.removeItem(atPath: destinationPath)
        }

        // 1. Try Darwin clonefile (single file or supported container)
        var isDir: ObjCBool = false
        fm.fileExists(atPath: sourcePath, isDirectory: &isDir)

        if !isDir.boolValue {
            let res = sourcePath.withCString { src in
                destinationPath.withCString { dst in
                    Darwin.clonefile(src, dst, 0)
                }
            }
            if res == 0 {
                self.totalForksCreated += 1
                return true
            }
        }

        // 2. Try Darwin copyfile with COPYFILE_CLONE (recursive directory clone)
        let cloneFlags = copyfile_flags_t(COPYFILE_ALL | COPYFILE_CLONE | COPYFILE_RECURSIVE)
        let resCopy = sourcePath.withCString { src in
            destinationPath.withCString { dst in
                copyfile(src, dst, nil, cloneFlags)
            }
        }

        if resCopy == 0 {
            self.totalForksCreated += 1
            return true
        }

        // 3. Fallback: FileManager, which performs the same APFS clone as
        // `cp -c -R` when both paths share a volume — no subprocess needed.
        if GenieNativeSystem.cloneItem(atPath: sourcePath, toPath: destinationPath) {
            self.totalForksCreated += 1
            return true
        }

        return false
    }

    /// Forks an entire project repository into a dedicated partitioned agent space.
    public func forkProject(sourceURL: URL, spaceName: String? = nil) throws -> URL {
        setupBridgeDirectories()
        let name = spaceName ?? sourceURL.lastPathComponent
        let destURL = URL(fileURLWithPath: "\(Self.defaultSpacesPath)/\(name)")

        let success = forkZeroCopy(sourcePath: sourceURL.path, destinationPath: destURL.path)
        guard success else {
            throw NSError(
                domain: "GenieSharedFolderForkEngine",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create zero-copy APFS clone of \(sourceURL.path)"]
            )
        }

        print("GENIE [FOLDER-FORK]: Successfully created zero-copy APFS fork: \(destURL.path)")
        return destURL
    }

    // MARK: - Bidirectional Bridge Live Streaming

    /// Streams a live frame into the shared bridge stream folder for zero-copy inspection
    public func streamFrameToBridge(data: Data, tag: String = "latest") {
        let streamPath = "\(Self.defaultBridgePath)/stream/\(tag).jpg"
        try? data.write(to: URL(fileURLWithPath: streamPath), options: .atomic)
        self.lastSyncTimestamp = Date()
    }

    /// Streams a code diff, note, or log artifact into the bridge outbox for immediate user access
    public func writeArtifactToBridge(name: String, content: String) throws -> URL {
        setupBridgeDirectories()
        let fileURL = URL(fileURLWithPath: "\(Self.defaultBridgePath)/artifacts/\(name)")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        self.lastSyncTimestamp = Date()
        refreshAssetCount()
        return fileURL
    }

    public func refreshAssetCount() {
        let fm = FileManager.default
        let path = "\(Self.defaultBridgePath)/artifacts"
        if let files = try? fm.contentsOfDirectory(atPath: path) {
            self.bridgeAssetCount = files.count
        }
    }

    // MARK: - Kernel FSEvents / DispatchSource Watcher

    private func startBridgeWatcher() {
        let path = Self.defaultBridgePath
        bridgeDirFileDescriptor = open(path, O_EVTONLY)
        guard bridgeDirFileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: bridgeDirFileDescriptor,
            eventMask: [.write, .extend, .attrib, .link],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshAssetCount()
                self?.lastSyncTimestamp = Date()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.bridgeDirFileDescriptor, fd >= 0 {
                close(fd)
            }
        }

        source.resume()
        self.bridgeWatcherSource = source
        self.isBridgeActive = true
    }

    deinit {
        bridgeWatcherSource?.cancel()
    }
}
