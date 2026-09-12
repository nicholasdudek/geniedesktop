import Foundation
import SwiftUI

// MARK: - Multi-Document Tab Manager (Genie 30B Architecture)
@MainActor
public final class DocumentTabStore: ObservableObject {
    public static let shared = DocumentTabStore()

    @Published public var openFiles: [URL] = []
    @Published public var activeFileURL: URL? = nil

    private init() {}

    public func openFile(_ url: URL) {
        if !openFiles.contains(url) {
            openFiles.append(url)
        }
        activeFileURL = url
        if GenieSettings.shared.enableHaptics {
            MobileHaptics.light()
        }
    }

    public func closeFile(_ url: URL) {
        guard let index = openFiles.firstIndex(of: url) else { return }
        openFiles.remove(at: index)

        if activeFileURL == url {
            if openFiles.indices.contains(index) {
                activeFileURL = openFiles[index]
            } else if !openFiles.isEmpty {
                activeFileURL = openFiles.last
            } else {
                activeFileURL = nil
            }
        }
        if GenieSettings.shared.enableHaptics {
            MobileHaptics.rigid()
        }
    }

    public func closeAll() {
        openFiles.removeAll()
        activeFileURL = nil
    }
}
