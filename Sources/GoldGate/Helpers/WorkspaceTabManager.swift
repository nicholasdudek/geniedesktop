import AppKit
import SwiftUI

// MARK: - Workspace Tab Type Enum
public enum WorkspaceTabType: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case huggingface = "HuggingFace"
    case github = "GitHub"
    case terminal = "Terminal"
    case evolver = "Evolver"
    case editor = "Editor"
    case vsCodeStudio = "VSCodeStudio"
    case browser = "Browser"
    case macTrainer = "MacTrainer"
    case matrix3x3 = "Matrix3x3"
    case settings = "Settings"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chat: return "Claude & Gemma"
        case .huggingface: return "Hugging Face"
        case .github: return "GitHub"
        case .terminal: return "Terminal"
        case .evolver: return "Codebase Evolver"
        case .editor: return "Editor"
        case .vsCodeStudio: return "VS Code Studio"
        case .browser: return "Browser"
        case .macTrainer: return "Mac Knowledge"
        case .matrix3x3: return "3×3 Program Matrix"
        case .settings: return "Settings"
        }
    }

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .huggingface: return "cube.fill"
        case .github: return "arrow.triangle.branch"
        case .terminal: return "terminal.fill"
        case .evolver: return "wand.and.stars"
        case .editor: return "curlybraces"
        case .vsCodeStudio: return "curlybraces.square.fill"
        case .browser: return "globe"
        case .macTrainer: return "brain.head.profile"
        case .matrix3x3: return "square.grid.3x3.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .chat: return Color(red: 0.85, green: 0.47, blue: 0.36) // Claude Terracotta
        case .huggingface: return .yellow
        case .github: return Color(red: 0.58, green: 0.44, blue: 0.96) // GitHub Violet
        case .terminal: return .green
        case .evolver: return Color(red: 0.95, green: 0.35, blue: 0.65) // Magenta / Rose
        case .editor: return .orange
        case .vsCodeStudio: return Color(red: 0.95, green: 0.45, blue: 0.20)
        case .browser: return .blue
        case .macTrainer: return Color(red: 0.0, green: 0.85, blue: 0.95)
        case .matrix3x3: return .cyan
        case .settings: return .cyan
        }
    }
}

// MARK: - Workspace Tab Model
public struct WorkspaceTab: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var type: WorkspaceTabType
    public var editorText: String
    public var editorLanguage: String
    public var editorFilePath: String?
    public var terminalHistory: [String]
    public var terminalInput: String
    public var browserURLString: String
    public var repoPath: String
    public var gitBranch: String
    public var selectedFilePath: String?
    public var selectedGitHubSubTab: String

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        type: WorkspaceTabType,
        editorText: String = "// Genie Code Editor\n// Write Swift, Python, HTML, Markdown or shell scripts\n\nfunc helloWorld() {\n    print(\"Hello from Genie Studio! ✨\")\n}\n",
        editorLanguage: String = "Swift",
        editorFilePath: String? = nil,
        terminalHistory: [String] = [
            "Genie Terminal Console v2.0 (macOS zsh)",
            "Type any shell command below and press Return, or run AI terminal tool commands.",
            "--------------------------------------------------"
        ],
        terminalInput: String = "",
        browserURLString: String = "https://www.google.com",
        repoPath: String = "/Users/nicholasdudek/Developer/GoldGate",
        gitBranch: String = "main",
        selectedFilePath: String? = nil,
        selectedGitHubSubTab: String = "code"
    ) {
        self.id = id
        self.type = type
        self.title = title ?? type.displayName
        self.editorText = editorText
        self.editorLanguage = editorLanguage
        self.editorFilePath = editorFilePath
        self.terminalHistory = terminalHistory
        self.terminalInput = terminalInput
        self.browserURLString = browserURLString
        self.repoPath = repoPath
        self.gitBranch = gitBranch
        self.selectedFilePath = selectedFilePath
        self.selectedGitHubSubTab = selectedGitHubSubTab
    }

    public static func == (lhs: WorkspaceTab, rhs: WorkspaceTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Workspace Tab Manager Singleton
@MainActor
public final class WorkspaceTabManager: ObservableObject {
    public static let shared = WorkspaceTabManager()

    @Published public var tabs: [WorkspaceTab] = []
    @Published public var activeTabId: UUID

    private init() {
        let chatTab = WorkspaceTab(title: "Claude & Gemma 💬", type: .chat)
        let githubTab = WorkspaceTab(title: "GitHub 🐙", type: .github)
        let terminalTab = WorkspaceTab(title: "Terminal 💻", type: .terminal)
        let editorTab = WorkspaceTab(title: "Editor 📝", type: .editor)
        let browserTab = WorkspaceTab(title: "Browser 🌐", type: .browser)

        self.tabs = [chatTab, githubTab, terminalTab, editorTab, browserTab]
        self.activeTabId = chatTab.id
    }

    public var activeTab: WorkspaceTab? {
        tabs.first(where: { $0.id == activeTabId }) ?? tabs.first
    }

    public var activeTabIndex: Int {
        tabs.firstIndex(where: { $0.id == activeTabId }) ?? 0
    }

    public func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
            HapticFeedback.selection()
        }
    }

    public func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        activeTabId = tabs[index].id
        HapticFeedback.selection()
    }

    @discardableResult
    public func createTab(type: WorkspaceTabType, title: String? = nil) -> UUID {
        let countOfType = tabs.filter { $0.type == type }.count
        let resolvedTitle: String = {
            if let custom = title { return custom }
            switch type {
            case .chat:
                return countOfType == 0 ? "Claude & Gemma" : "Chat \(countOfType + 1)"
            case .huggingface:
                return countOfType == 0 ? "Hugging Face" : "HF \(countOfType + 1)"
            case .github:
                return countOfType == 0 ? "GitHub" : "GitHub \(countOfType + 1)"
            case .terminal:
                return countOfType == 0 ? "Terminal" : "Terminal \(countOfType + 1)"
            case .evolver:
                return countOfType == 0 ? "Codebase Evolver" : "Evolver \(countOfType + 1)"
            case .editor:
                return countOfType == 0 ? "Editor" : "Editor \(countOfType + 1)"
            case .vsCodeStudio:
                return countOfType == 0 ? "VS Code Studio" : "Studio \(countOfType + 1)"
            case .browser:
                return countOfType == 0 ? "Browser" : "Browser \(countOfType + 1)"
            case .macTrainer:
                return countOfType == 0 ? "Mac Knowledge" : "Mac Knowledge \(countOfType + 1)"
            case .matrix3x3:
                return countOfType == 0 ? "3×3 Program Matrix" : "Matrix \(countOfType + 1)"
            case .settings:
                return countOfType == 0 ? "Settings" : "Settings \(countOfType + 1)"
            }
        }()

        let newTab = WorkspaceTab(title: resolvedTitle, type: type)
        tabs.append(newTab)
        activeTabId = newTab.id
        HapticFeedback.selection()
        return newTab.id
    }

    public func closeTab(id: UUID) {
        // Prevent closing all tabs — maintain at least one active tab
        guard tabs.count > 1 else { return }
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }

        let wasActive = (activeTabId == id)
        tabs.remove(at: idx)

        if wasActive {
            let nextIdx = min(idx, tabs.count - 1)
            activeTabId = tabs[nextIdx].id
        }
        HapticFeedback.tick()
    }

    public func changeTabType(id: UUID, to newType: WorkspaceTabType) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].type = newType
        tabs[idx].title = "\(newType.displayName) \(idx + 1)"
        HapticFeedback.selection()
    }

    public func updateEditorText(id: UUID, text: String) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].editorText = text
    }

    public func updateEditorLanguage(id: UUID, lang: String) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].editorLanguage = lang
    }

    public func updateEditor(content: String, filePath: String? = nil) {
        if let idx = tabs.firstIndex(where: { $0.id == activeTabId }) {
            tabs[idx].editorText = content
            tabs[idx].editorFilePath = filePath
            if let path = filePath {
                let ext = (path as NSString).pathExtension.lowercased()
                switch ext {
                case "swift": tabs[idx].editorLanguage = "Swift"
                case "py": tabs[idx].editorLanguage = "Python"
                case "js", "ts": tabs[idx].editorLanguage = "JavaScript"
                case "html": tabs[idx].editorLanguage = "HTML"
                case "md": tabs[idx].editorLanguage = "Markdown"
                case "json": tabs[idx].editorLanguage = "JSON"
                case "sh", "zsh": tabs[idx].editorLanguage = "Shell"
                default: break
                }
            }
        }
    }
}
