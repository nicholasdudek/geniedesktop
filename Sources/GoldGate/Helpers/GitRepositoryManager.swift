import Foundation
import Combine

@MainActor
class GitRepositoryManager: ObservableObject {
    static let shared = GitRepositoryManager()

    // MARK: - Repository Metadata
    @Published public var currentRepoPath: String = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/Genie/GoldGate").path
    @Published public var currentFolderPath: String = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/Genie/GoldGate").path
    @Published public var remoteOriginURL: String = ""
    @Published public var currentBranch: String = "main"
    @Published public var branches: [String] = ["main", "develop"]
    @Published public var repoOwner: String = "Genie"
    @Published public var repoName: String = "GoldGate"
    @Published public var repoDescription: String = ""
    @Published public var starCount: Int = 0
    @Published public var forkCount: Int = 0
    @Published public var watchCount: Int = 0
    @Published public var isStarActive: Bool = false

    // MARK: - Commits
    @Published public var commits: [GitCommit] = []

    // MARK: - File Items
    @Published public var fileItems: [GitFileItem] = []
    @Published public var selectedFilePath: String? = nil
    @Published public var selectedFileContent: String = ""
    @Published public var readmeContent: String = ""

    // MARK: - Pull Requests
    @Published public var pullRequests: [GitPullRequest] = []
    @Published public var diffOutput: String = ""

    // MARK: - Issues
    @Published public var issues: [GitIssueItem] = []

    // MARK: - Workflows / Actions
    @Published public var isWorkflowRunning: Bool = false
    @Published public var workflowStatus: String = "Passing"
    @Published public var workflowLogs: [String] = []

    private init() {}

    // MARK: - Actions

    func loadRepository(at path: String? = nil) {
        let targetPath = path ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/Genie/GoldGate").path
        currentRepoPath = targetPath
        currentFolderPath = targetPath
        refreshRepositoryData()
    }

    func refreshRepositoryData() {
        // Placeholder: real impl would shell out to git
    }

    func selectFile(_ item: GitFileItem) {
        selectedFilePath = item.path
        if !item.isDirectory {
            selectedFileContent = (try? String(contentsOfFile: item.path, encoding: .utf8)) ?? ""
        }
    }

    func navigateUp() {
        let parent = (currentFolderPath as NSString).deletingLastPathComponent
        if !parent.isEmpty {
            currentFolderPath = parent
        }
    }

    func toggleStar() {
        isStarActive.toggle()
        starCount += isStarActive ? 1 : -1
    }

    func runWorkflow() {
        guard !isWorkflowRunning else { return }
        isWorkflowRunning = true
        workflowLogs = ["[genie-ci] Starting workflow..."]
        workflowStatus = "Running"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.workflowLogs.append("[genie-ci] Build complete ✓")
            self?.isWorkflowRunning = false
            self?.workflowStatus = "Passing"
        }
    }
}

// MARK: - Supporting Models

struct GitCommit: Identifiable {
    let id: String
    let sha: String
    var hash: String { String(sha.prefix(7)) }
    let message: String
    let author: String
    let date: Date
    var filesChanged: Int = 0
    var additions: Int = 0
    var deletions: Int = 0

    var timeAgo: String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval/60))m ago" }
        if interval < 86400 { return "\(Int(interval/3600))h ago" }
        return "\(Int(interval/86400))d ago"
    }
}

struct GitFileItem: Identifiable {
    let id: String
    let path: String
    let name: String
    let isDirectory: Bool
    var statusFlag: FileStatus = .unmodified
    var sizeBytes: Int64 = 0
    var modifiedDate: Date = Date()

    enum FileStatus {
        case unmodified, added, modified, deleted, untracked
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":   return "swift"
        case "py":      return "ant"
        case "md":      return "doc.text"
        case "json":    return "curlybraces"
        case "png", "jpg", "jpeg": return "photo"
        default:        return "doc"
        }
    }

    var iconColor: SwiftUI.Color {
        if isDirectory { return .cyan }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":  return .orange
        case "py":     return .yellow
        case "md":     return .white
        default:       return .secondary
        }
    }

    var size: String {
        if isDirectory { return "" }
        if sizeBytes < 1024 { return "\(sizeBytes) B" }
        if sizeBytes < 1_048_576 { return "\(sizeBytes / 1024) KB" }
        return "\(sizeBytes / 1_048_576) MB"
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(modifiedDate)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval/60))m" }
        if interval < 86400 { return "\(Int(interval/3600))h" }
        return "\(Int(interval/86400))d"
    }
}

struct GitPullRequest: Identifiable {
    let id: Int
    let title: String
    let body: String
    let author: String
    let branch: String
    var sourceBranch: String { branch }
    let targetBranch: String
    let state: State
    let createdAt: Date
    var commentsCount: Int = 0
    var additions: Int = 0
    var deletions: Int = 0
    var checksPassing: Bool = true

    enum State: String {
        case open, closed, merged, draft
    }
}

struct GitIssueItem: Identifiable {
    let id: Int
    let title: String
    var body: String = ""
    let author: String
    var labels: [String] = []
    var state: State = .open
    var commentsCount: Int = 0
    let createdAt: Date = Date()

    enum State: String {
        case open, closed
    }
}

struct GitWorkflow: Identifiable {
    let id: Int
    let name: String
    let path: String
    var state: String = "active"
}

struct GitWorkflowRun: Identifiable {
    let id: Int
    let workflowName: String
    let status: Status
    let conclusion: Conclusion?
    let createdAt: Date
    var duration: TimeInterval = 0

    enum Status: String {
        case queued, inProgress = "in_progress", completed, waiting
    }
    enum Conclusion: String {
        case success, failure, cancelled, skipped, timedOut = "timed_out"
    }
}

// SwiftUI Color import for GitFileItem.iconColor
import SwiftUI
