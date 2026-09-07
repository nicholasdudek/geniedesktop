import AppKit
import Foundation

// MARK: - Live Real-Time Trash Monitor
@MainActor
public final class TrashMonitor: ObservableObject {
    public static let shared = TrashMonitor()

    @Published public private(set) var isTrashFull: Bool = false
    @Published public private(set) var trashItemCount: Int = 0

    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var timer: Timer?

    private init() {
        checkTrashNow()
        startFileSystemMonitor()
    }

    isolated deinit {
        stopFileSystemMonitor()
    }

    public func checkTrashNow() {
        let trashPath = NSHomeDirectory() + "/.Trash"
        var totalCount = 0

        // 1. Check Primary User Trash directory
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: trashPath) {
            let visible = contents.filter { !$0.hasPrefix(".") }
            totalCount += visible.count
        }

        // 2. Check Mounted Volumes Trashes if accessible
        if let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            let uid = getuid()
            for vol in volumes {
                let volTrash = vol.appendingPathComponent(".Trashes/\(uid)").path
                if let volContents = try? FileManager.default.contentsOfDirectory(atPath: volTrash) {
                    let visible = volContents.filter { !$0.hasPrefix(".") }
                    totalCount += visible.count
                }
            }
        }

        let full = totalCount > 0
        if self.isTrashFull != full || self.trashItemCount != totalCount {
            self.isTrashFull = full
            self.trashItemCount = totalCount
            objectWillChange.send()
        }
    }

    private func startFileSystemMonitor() {
        let trashPath = NSHomeDirectory() + "/.Trash"
        let fd = open(trashPath, O_EVTONLY)
        if fd >= 0 {
            self.fileDescriptor = fd
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .link, .delete, .extend, .attrib],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                self?.checkTrashNow()
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            self.dispatchSource = source
        }

        // Periodic heartbeat poll (every 1.0s) to catch external volume changes or Finder empties
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkTrashNow()
            }
        }
    }

    private func stopFileSystemMonitor() {
        dispatchSource?.cancel()
        dispatchSource = nil
        timer?.invalidate()
        timer = nil
    }
}
