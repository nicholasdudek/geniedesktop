import AppKit
import SwiftUI

// MARK: - GitHub Desktop Canvas View
public struct GitHubDesktopCanvasView: View {
    @ObservedObject var gitManager = GitRepositoryManager.shared
    @ObservedObject var localModels = LocalModelManager.shared
    @AppStorage(PrefKey.activeGenieTheme) private var activeThemeRaw: String = GenieTheme.defaultTheme.rawValue
    @State private var selectedSubTab: String = "code" // "code", "pulls", "issues", "actions", "copilot", "catalog"
    @State private var searchQuery: String = ""
    @State private var newIssueTitle: String = ""
    @State private var showingNewIssueModal: Bool = false
    @State private var commitMessageInput: String = "Update components and documentation"
    @State private var statusToast: String? = nil
    @State private var catalogCategory: CatalogCategory = .all
    @State private var catalogSearch: String = ""

    public init(initialSubTab: String = "code") {
        _selectedSubTab = State(initialValue: initialSubTab)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── 1. GitHub Repository Header Bar ──
            repoHeaderBar

            Divider().opacity(0.35)

            // ── 2. GitHub Browser Sub-Tabs Bar ──
            githubSubTabBar

            Divider().opacity(0.35)

            // ── 3. Main Body Content Switcher ──
            ZStack {
                switch selectedSubTab {
                case "code":
                    codeExplorerView
                case "pulls":
                    pullRequestsAndDiffView
                case "issues":
                    issuesTrackerView
                case "actions":
                    actionsWorkflowView
                case "copilot":
                    claudeCopilotView
                case "catalog":
                    featureCatalogView
                default:
                    codeExplorerView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            ZStack {
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, state: .active)
                Color(red: 0.07, green: 0.08, blue: 0.11).opacity(0.96)
            }
        )
        .overlay(alignment: .bottom) {
            if let toast = statusToast {
                Text(toast)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - 1. Repository Header Bar
    private var repoHeaderBar: some View {
        HStack(spacing: 12) {
            // Octocat / Git Branch Icon
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(red: 0.58, green: 0.44, blue: 0.96).opacity(0.20))
                    .frame(width: 28, height: 28)
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.70, green: 0.55, blue: 1.0))
            }

            // Repo Owner & Name Breadcrumb
            HStack(spacing: 4) {
                Text(gitManager.repoOwner)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))

                Text("/")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.40))

                Text(gitManager.repoName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text("Public")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }

            Spacer()

            // Repo Switcher / Open Folder
            Button(action: {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.prompt = "Open Repository"
                if panel.runModal() == .OK, let url = panel.url {
                    gitManager.loadRepository(at: url.path)
                    triggerToast("Opened \(url.lastPathComponent) 📂")
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                    Text("Open Folder...")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)

            // Star Button (Interactive)
            Button(action: {
                gitManager.toggleStar()
                triggerToast(gitManager.isStarActive ? "Starred repository! ⭐" : "Unstarred repository")
            }) {
                HStack(spacing: 4) {
                    Image(systemName: gitManager.isStarActive ? "star.fill" : "star")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(gitManager.isStarActive ? .yellow : .white.opacity(0.8))
                    Text("Star")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(gitManager.starCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.10)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            // Fork Button
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.pull")
                    .font(.system(size: 10))
                Text("Fork")
                    .font(.system(size: 11, weight: .medium))
                Text("\(gitManager.forkCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))

            // Watch Button
            HStack(spacing: 4) {
                Image(systemName: "eye")
                    .font(.system(size: 10))
                Text("Watch")
                    .font(.system(size: 11, weight: .medium))
                Text("\(gitManager.watchCount)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
    }

    // MARK: - 2. Sub-Tabs Bar (<> Code, ⑂ Pull Requests, ⊙ Issues, ▶ Actions, ✳️ Copilot)
    private var githubSubTabBar: some View {
        HStack(spacing: 4) {
            subTabButton(id: "code", title: "Code", icon: "curlybraces")
            subTabButton(id: "pulls", title: "Pull Requests", icon: "arrow.triangle.pull", count: gitManager.pullRequests.count)
            subTabButton(id: "issues", title: "Issues", icon: "circle.circle", count: gitManager.issues.count)
            subTabButton(id: "actions", title: "Actions", icon: "play.circle", badgeDot: true)
            subTabButton(id: "copilot", title: "Claude & Gemma", icon: "sparkles")
            subTabButton(id: "catalog", title: "Feature Catalog", icon: "square.grid.3x3.fill", badgeDot: true)

            Spacer()

            // Branch Indicator in Sub-bar
            Menu {
                ForEach(gitManager.branches, id: \.self) { br in
                    Button(action: {
                        gitManager.currentBranch = br
                        triggerToast("Switched to branch '\(br)'")
                    }) {
                        HStack {
                            Text(br)
                            if gitManager.currentBranch == br {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 9.5))
                    Text(gitManager.currentBranch)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.15))
    }

    private func subTabButton(id: String, title: String, icon: String, count: Int? = nil, badgeDot: Bool = false) -> some View {
        let isSel = (selectedSubTab == id)
        return Button(action: {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                selectedSubTab = id
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: isSel ? .bold : .medium))

                Text(title)
                    .font(.system(size: 11, weight: isSel ? .bold : .medium))

                if let c = count {
                    Text("\(c)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(isSel ? Color.white.opacity(0.25) : Color.white.opacity(0.10)))
                }

                if badgeDot {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
            }
            .foregroundColor(isSel ? .white : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSel ? Color.white.opacity(0.14) : Color.clear)
            )
            .overlay(
                VStack {
                    Spacer()
                    if isSel {
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.47, blue: 0.36))
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3A. Code Explorer View
    private var codeExplorerView: some View {
        VStack(spacing: 0) {
            // Latest Commit Card (The quintessential GitHub commit banner)
            if let latest = gitManager.commits.first {
                HStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                        .overlay(Text(latest.author.prefix(1)).font(.system(size: 9.5, weight: .bold)).foregroundColor(.white))

                    Text(latest.author)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)

                    Text(latest.message)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Text(latest.hash)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))

                    Text(latest.timeAgo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Button(action: {
                        gitManager.refreshRepositoryData()
                        triggerToast("Repository refreshed 🔄")
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh git files & commits")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
            }

            Divider().opacity(0.2)

            // Breadcrumb path bar
            HStack(spacing: 6) {
                Button(action: {
                    gitManager.navigateUp()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                        Text("..")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Navigate up to parent folder")

                Text(displayFolderPath)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)

                Spacer()

                Text("\(gitManager.fileItems.count) items")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.2))

            Divider().opacity(0.2)

            // Split: File Tree (Left) + Code Inspector or README (Right)
            HSplitView {
                // File List Table
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(gitManager.fileItems) { item in
                            Button(action: {
                                gitManager.selectFile(item)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 11))
                                        .foregroundColor(item.iconColor)
                                        .frame(width: 16)

                                    Text(item.name)
                                        .font(.system(size: 11.5, weight: item.isDirectory ? .semibold : .regular))
                                        .foregroundColor(item.isDirectory ? .white : .white.opacity(0.88))
                                        .lineLimit(1)

                                    Spacer()

                                    Text(item.size)
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.7))

                                    Text(item.timeAgo)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(gitManager.selectedFilePath == item.path ? Color.accentColor.opacity(0.22) : Color.clear)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().opacity(0.12)
                        }
                    }
                }
                .frame(minWidth: 220, maxWidth: 360)

                // Code / README Preview
                VStack(spacing: 0) {
                    if let sel = gitManager.selectedFilePath {
                        // File Preview Header
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)

                            Text((sel as NSString).lastPathComponent)
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)

                            Spacer()

                            Button("Copy Code") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(gitManager.selectedFileContent, forType: .string)
                                triggerToast("Code copied to clipboard! 📋")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.10)))

                            Button("Open in Editor 📝") {
                                let tabMgr = WorkspaceTabManager.shared
                                if let edTab = tabMgr.tabs.first(where: { $0.type == .editor }) {
                                    tabMgr.selectTab(id: edTab.id)
                                    tabMgr.updateEditor(content: gitManager.selectedFileContent, filePath: sel)
                                } else {
                                    _ = tabMgr.createTab(type: .editor, title: (sel as NSString).lastPathComponent)
                                    tabMgr.updateEditor(content: gitManager.selectedFileContent, filePath: sel)
                                }
                                triggerToast("Opened in Code Editor tab 📝")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.20)))
                            .foregroundColor(.orange)

                            Button("Ask Claude ✳️") {
                                let prompt = "Explain what this file does and suggest any improvements:\n\nFile: \((sel as NSString).lastPathComponent)\n```\n\(gitManager.selectedFileContent.prefix(2000))\n```"
                                selectedSubTab = "copilot"
                                localModels.generate(prompt: prompt)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.85, green: 0.47, blue: 0.36).opacity(0.22)))
                            .foregroundColor(Color(red: 0.95, green: 0.60, blue: 0.50))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))

                        Divider().opacity(0.25)

                        ScrollView([.horizontal, .vertical]) {
                            Text(gitManager.selectedFileContent)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(12)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        // Render README.md Viewer
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("README.md")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.05))

                            Divider().opacity(0.2)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(gitManager.readmeContent)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.92))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(16)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3B. Pull Requests & Diff View
    private var pullRequestsAndDiffView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Open Pull Requests")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button("+ New Pull Request") {
                    triggerToast("Created PR from branch '\(gitManager.currentBranch)'! ⑂")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(gitManager.pullRequests) { pr in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.pull")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)

                                Text(pr.title)
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("+\(pr.additions)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.green)
                                    Text("-\(pr.deletions)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red)
                                }
                            }

                            HStack(spacing: 6) {
                                Text("#\(pr.id) by \(pr.author)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                Text("•")
                                    .foregroundColor(.secondary)

                                Text("into main from \(pr.branch)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.cyan)

                                Spacer()

                                if pr.checksPassing {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Checks passed")
                                            .foregroundColor(.green)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                }
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 16)

                // Live Working Tree Diff
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORKING DIRECTORY STATUS & DIFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.top, 10)

                    Text(gitManager.diffOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.4)))
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 3C. Issues Tracker View
    private var issuesTrackerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Repository Issues")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button("+ New Issue") {
                    showingNewIssueModal = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if showingNewIssueModal {
                HStack(spacing: 8) {
                    TextField("Issue title...", text: $newIssueTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))

                    Button("Submit Issue") {
                        if !newIssueTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            let nextId = (gitManager.issues.map { $0.id }.max() ?? 0) + 1
                            gitManager.issues.insert(GitIssueItem(id: nextId, title: newIssueTitle, author: gitManager.repoOwner, labels: ["task", "studio"]), at: 0)
                            newIssueTitle = ""
                            showingNewIssueModal = false
                            triggerToast("Issue #\(nextId) created! ⊙")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Cancel") {
                        showingNewIssueModal = false
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(gitManager.issues) { issue in
                        HStack(spacing: 8) {
                            Image(systemName: "circle.circle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(issue.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)

                                HStack(spacing: 6) {
                                    Text("#\(issue.id) opened by \(issue.author)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    ForEach(issue.labels, id: \.self) { label in
                                        Text(label)
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(.cyan)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                                    }
                                }
                            }

                            Spacer()

                            Button(action: {
                                gitManager.issues.removeAll(where: { $0.id == issue.id })
                                triggerToast("Issue #\(issue.id) closed! ✓")
                            }) {
                                Text("Close")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 3D. Actions CI-CD Workflow View
    private var actionsWorkflowView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workflows & Builds")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Continuous verification for Genie macOS target")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    gitManager.runWorkflow()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: gitManager.isWorkflowRunning ? "gearshape.arrow.triangle.2.circlepath" : "play.fill")
                            .font(.system(size: 10))
                        Text(gitManager.isWorkflowRunning ? "Building..." : "Run Workflow")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(gitManager.isWorkflowRunning)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Status Card
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Release Build (macOS 14+ arm64)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("Branch: \(gitManager.currentBranch) • Commit \(gitManager.commits.first?.hash ?? "3a81f0b")")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(gitManager.workflowStatus)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
            .padding(.horizontal, 16)

            // Console Log Terminal
            VStack(alignment: .leading, spacing: 4) {
                Text("CONSOLE OUTPUT")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(gitManager.workflowLogs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(log.contains("error") ? .red : (log.contains("complete") ? .green : .white.opacity(0.85)))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.55)))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 3E. Claude & Gemma Copilot Workspace View
    private var claudeCopilotView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.47, blue: 0.36))

                Text("Claude & Gemini Repository Copilot")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("Model: \(localModels.selectedModelDisplayName)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.50))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color(red: 0.85, green: 0.47, blue: 0.36).opacity(0.20)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.25))

            Divider().opacity(0.25)

            // Embedded Compact Chat Stream View
            CompactChatStreamView(emotion: .mystical)
        }
    }

    private var displayFolderPath: String {
        let home = NSHomeDirectory()
        let path = gitManager.currentFolderPath
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func triggerToast(_ msg: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            statusToast = msg
        }
        HapticFeedback.selection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                if statusToast == msg { statusToast = nil }
            }
        }
    }

    // MARK: - 3F. Feature Catalog View with Sidebar & Interactive Glass Cards
    private var featureCatalogView: some View {
        HStack(spacing: 0) {
            // Left Category Navigation Sidebar
            catalogSidebar
                .frame(width: 230)
                .background(Color.black.opacity(0.35))

            Divider().opacity(0.35)

            // Right Feature Grid & Search Explorer
            catalogMainArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.85))
        }
    }

    // MARK: - Catalog Sidebar
    private var catalogSidebar: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("FEATURE CATALOG")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))

                Spacer()

                Text("\(allCatalogFeatures.count)")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider().opacity(0.25)

            // Categories List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(CatalogCategory.allCases) { cat in
                        let isSel = (catalogCategory == cat)
                        let count = countForCategory(cat)
                        Button(action: {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                catalogCategory = cat
                            }
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isSel ? .cyan : .white.opacity(0.65))
                                    .frame(width: 18)

                                Text(cat.rawValue)
                                    .font(.system(size: 11.5, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : .white.opacity(0.80))
                                    .lineLimit(1)

                                Spacer()

                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(isSel ? .cyan : .white.opacity(0.40))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(Capsule().fill(isSel ? Color.cyan.opacity(0.20) : Color.white.opacity(0.06)))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSel ? Color.white.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(isSel ? Color.cyan.opacity(0.35) : Color.clear, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }

            Divider().opacity(0.25)

            // Living Atmosphere Quick Theme Switcher in Sidebar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.purple)
                    Text("ATMOSPHERE THEMES")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.60))
                    Spacer()
                    let currentTheme = GenieTheme(rawValue: activeThemeRaw) ?? .defaultTheme
                    Circle()
                        .fill(currentTheme.accentColor)
                        .frame(width: 6, height: 6)
                }

                // 8 themes compact pills
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(GenieTheme.allCases) { theme in
                        let isCurrent = (activeThemeRaw == theme.rawValue)
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                activeThemeRaw = theme.rawValue
                            }
                            triggerToast("Theme: \(theme.shortTitle)")
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: theme.icon)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(theme.accentColor)
                                Text(theme.shortTitle.split(separator: " ").first.map(String.init) ?? "")
                                    .font(.system(size: 9.5, weight: isCurrent ? .bold : .medium))
                                    .foregroundColor(isCurrent ? .white : .white.opacity(0.70))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(isCurrent ? theme.accentColor.opacity(0.25) : Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isCurrent ? theme.accentColor.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.20))
        }
    }

    // MARK: - Catalog Main Area
    private var catalogMainArea: some View {
        VStack(spacing: 0) {
            // Main Top Bar (Search + Title)
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: catalogCategory.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(catalogCategory.rawValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(filteredCatalogFeatures.count) capabilities available in Genie")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.50))
                    }
                }

                Spacer()

                // Search Box
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.50))

                    TextField("Search features, shortcuts, tags...", text: $catalogSearch)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.white)

                    if !catalogSearch.isEmpty {
                        Button(action: { catalogSearch = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.50))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                .frame(width: 260)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.25))

            Divider().opacity(0.30)

            // Features Grid
            ScrollView(.vertical, showsIndicators: true) {
                if filteredCatalogFeatures.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.30))
                            .padding(.top, 60)
                        Text("No features matched '\(catalogSearch)'")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.60))
                        Button("Clear Search") {
                            catalogSearch = ""
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 330, maximum: 540), spacing: 14)], spacing: 14) {
                        ForEach(filteredCatalogFeatures) { item in
                            featureCard(item)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Feature Card
    private func featureCard(_ item: CatalogFeatureItem) -> some View {
        let isTheme = item.themeTarget != nil
        let isCurrentTheme = isTheme && (activeThemeRaw == item.themeTarget?.rawValue)

        return VStack(alignment: .leading, spacing: 10) {
            // Header Row: Icon + Title + Category + Badge
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.badgeColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(item.badgeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(item.category.rawValue)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.50))
                }

                Spacer()

                // Status Badge
                Text(item.badge)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(item.badgeColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(item.badgeColor.opacity(0.18)))
                    .overlay(Capsule().stroke(item.badgeColor.opacity(0.35), lineWidth: 0.5))
            }

            // Shortcut Pill (if present)
            if let shortcut = item.shortcut {
                HStack(spacing: 5) {
                    Image(systemName: "command")
                        .font(.system(size: 9, weight: .bold))
                    Text(shortcut)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Color.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.25), lineWidth: 0.5))
            }

            // Description
            Text(item.description)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Tag Chips
            if !item.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                }
            }

            Divider().opacity(0.20)

            // Footer Action Row
            HStack {
                if let theme = item.themeTarget {
                    if isCurrentTheme {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("Active Theme")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.green)
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                activeThemeRaw = theme.rawValue
                            }
                            triggerToast("Switched to \(theme.shortTitle) 🎨")
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 10))
                                Text("Switch to Theme")
                                    .font(.system(size: 10.5, weight: .bold))
                            }
                            .foregroundColor(theme.accentColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(theme.accentColor.opacity(0.16)))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.accentColor.opacity(0.35), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                } else if let tab = item.tabTarget {
                    Button(action: {
                        FinderChatWindowManager.shared.openTab(FinderWindowTab(kind: tab))
                        triggerToast("Opened \(tab) tab ⚡")
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                            Text(item.actionLabel ?? "Open Tab")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.16)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                } else if let shortcut = item.shortcut {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(shortcut, forType: .string)
                        triggerToast("Copied shortcut '\(shortcut)' 📋")
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                            Text("Copy Shortcut")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.70))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(item.badgeColor == .green ? "Locked 120 FPS" : "Verified Ready")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrentTheme ? item.badgeColor.opacity(0.10) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrentTheme ? item.badgeColor.opacity(0.50) : Color.white.opacity(0.10), lineWidth: isCurrentTheme ? 1.2 : 0.6)
        )
    }

    private func countForCategory(_ cat: CatalogCategory) -> Int {
        if cat == .all {
            return allCatalogFeatures.count
        }
        return allCatalogFeatures.filter { $0.category == cat }.count
    }

    private var filteredCatalogFeatures: [CatalogFeatureItem] {
        allCatalogFeatures.filter { item in
            let matchesCategory = (catalogCategory == .all || item.category == catalogCategory)
            if !matchesCategory { return false }
            if catalogSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            let query = catalogSearch.lowercased()
            return item.title.lowercased().contains(query) ||
                   item.description.lowercased().contains(query) ||
                   (item.shortcut?.lowercased().contains(query) == true) ||
                   item.tags.contains { $0.lowercased().contains(query) }
        }
    }

    // MARK: - Comprehensive Catalog Database
    private var allCatalogFeatures: [CatalogFeatureItem] {
        [
            // ── AI & Models ──
            CatalogFeatureItem(
                id: "ai-claude",
                title: "Claude 3.5 Sonnet & Claude 3 Opus",
                category: .aiModels,
                icon: "sparkles",
                badge: "Anthropic Cloud",
                badgeColor: Color(red: 0.85, green: 0.47, blue: 0.36),
                description: "Deep reasoning, code generation, and streaming multi-turn chat powered by Anthropic's flagship models.",
                tags: ["#Claude", "#CloudAI", "#Streaming"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "ai-local-gemma-llama",
                title: "Gemma 2 & Llama 3.3 On-Device",
                category: .aiModels,
                icon: "cpu",
                badge: "Local Metal",
                badgeColor: .purple,
                description: "100% private, offline neural inference running locally on Apple Silicon unified memory via llama.cpp.",
                tags: ["#LocalAI", "#Metal", "#llama.cpp"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "ai-ram-monitor",
                title: "RAM Usage & Quantization Monitor",
                category: .aiModels,
                icon: "memorychip",
                badge: "Live Telemetry",
                badgeColor: .cyan,
                description: "Real-time unified memory consumption meter showing active model footprints (e.g. Q4_K_M, 4.2 GB / 16 GB) in the chat dock.",
                tags: ["#RAM", "#Q4_K_M", "#AppleSilicon"],
                tabTarget: .chat,
                actionLabel: "View RAM Bar"
            ),
            CatalogFeatureItem(
                id: "ai-copy-paste-chat",
                title: "Whole-Chat Copy & Paste Transcripts",
                category: .aiModels,
                icon: "doc.on.doc.fill",
                badge: "Transcript Engine",
                badgeColor: .green,
                shortcut: "⌘⇧C / ⌘⇧V / /copy",
                description: "Export the full chat history to clipboard as structured JSON and readable markdown, or paste transcripts to seamlessly restore conversations.",
                tags: ["#CopyPaste", "#JSON", "#Markdown"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "ai-copilot",
                title: "Claude & Gemma Git Copilot",
                category: .aiModels,
                icon: "arrow.triangle.branch",
                badge: "Repository AI",
                badgeColor: .indigo,
                description: "Context-aware git companion for automated PR code reviews, commit message drafts, and codebase diff explanations.",
                tags: ["#Copilot", "#GitReview", "#DiffExplainer"],
                tabTarget: .github,
                actionLabel: "Open Copilot"
            ),
            CatalogFeatureItem(
                id: "ai-whisper",
                title: "Whisper Speech-to-Text Dictation",
                category: .aiModels,
                icon: "mic.fill",
                badge: "Voice Engine",
                badgeColor: .orange,
                description: "Local neural voice dictation powered by Whisper with live real-time audio waveform visualizers.",
                tags: ["#Whisper", "#SpeechToText", "#Waveform"],
                tabTarget: .chat,
                actionLabel: "Open Voice"
            ),
            CatalogFeatureItem(
                id: "ai-attention-sink",
                title: "Attention-Sink Ring Buffer",
                category: .aiModels,
                icon: "arrow.triangle.2.circlepath",
                badge: "Zero Memory Leaks",
                badgeColor: .teal,
                description: "Nicholas Dudek's attention sink architecture: keeps initial system anchors, evicts oldest sliding items, and compacts digests to prevent OOM growth.",
                tags: ["#AttentionSink", "#RingBuffer", "#ZeroLeak"],
                tabTarget: nil,
                actionLabel: nil
            ),

            // ── Apple 2028 Themes ──
            CatalogFeatureItem(
                id: "theme-liquid-water",
                title: "Apple 2028 Living Liquid Water",
                category: .themes,
                icon: "drop.fill",
                badge: "Flagship 2028",
                badgeColor: Color(red: 0.10, green: 0.85, blue: 0.95),
                description: "Photorealistic refractive caustics, dynamic fluid wave propagation, and liquid glass refraction locked at 120 FPS.",
                tags: ["#LiquidWater", "#Caustics", "#120FPS"],
                themeTarget: .apple2028LiquidWater
            ),
            CatalogFeatureItem(
                id: "theme-oled-pillow",
                title: "Apple 2028 OLED Blackout Pillow",
                category: .themes,
                icon: "clock.fill",
                badge: "Flagship 2028",
                badgeColor: Color(white: 0.92),
                description: "Pure #000000 blackout card architecture, specular rim lighting gradients, haute horology watch dials, and maximum battery savings.",
                tags: ["#OLED", "#BatterySaver", "#PureBlack"],
                themeTarget: .apple2028OledPillow
            ),
            CatalogFeatureItem(
                id: "theme-quantum-glass",
                title: "Apple 2028 Quantum Titanium Glass",
                category: .themes,
                icon: "sparkles",
                badge: "Flagship 2028",
                badgeColor: Color(red: 0.70, green: 0.45, blue: 1.0),
                description: "Dual-layer frosted silica glass refraction with cosmic violet-cyan titanium edge bevels and sub-pixel edge glows.",
                tags: ["#Quantum", "#Titanium", "#FrostedGlass"],
                themeTarget: .apple2028QuantumGlass
            ),
            CatalogFeatureItem(
                id: "theme-frosted-light",
                title: "Apple 2028 Frosted Alabaster Light",
                category: .themes,
                icon: "sun.max.fill",
                badge: "Flagship 2028",
                badgeColor: Color(red: 0.98, green: 0.55, blue: 0.15),
                description: "Luminous daylight vitreous alabaster glass with sunlit warmth, azure accents, and crisp high-contrast dark typography.",
                tags: ["#HighKey", "#Alabaster", "#LightMode"],
                themeTarget: .apple2028FrostedLight
            ),
            CatalogFeatureItem(
                id: "theme-mystical-aurora",
                title: "Living Atmosphere: Mystical Aurora",
                category: .themes,
                icon: "wand.and.stars",
                badge: "Living Atmosphere",
                badgeColor: Color(red: 0.65, green: 0.40, blue: 1.0),
                description: "Deep nebula violet and spectral emerald ribbons with starlight particle drift and breathing ambient smoke dynamics.",
                tags: ["#Aurora", "#Nebula", "#ParticleDrift"],
                themeTarget: .mysticalAurora
            ),
            CatalogFeatureItem(
                id: "theme-contemplative-ocean",
                title: "Living Atmosphere: Contemplative Ocean",
                category: .themes,
                icon: "water.waves",
                badge: "Living Atmosphere",
                badgeColor: Color(red: 0.20, green: 0.65, blue: 0.98),
                description: "Deep oceanic blue pelagic currents with calming ambient swells, abyssal wave motion, and bioluminescent pulses.",
                tags: ["#Ocean", "#Pelagic", "#Bioluminescence"],
                themeTarget: .contemplativeOcean
            ),
            CatalogFeatureItem(
                id: "theme-energetic-amber",
                title: "Living Atmosphere: Energetic Amber",
                category: .themes,
                icon: "bolt.fill",
                badge: "Living Atmosphere",
                badgeColor: Color(red: 1.0, green: 0.72, blue: 0.20),
                description: "Warm golden solar flare radiation with ember caustics, energetic plasma pulses, and radiant atmospheric bloom.",
                tags: ["#Amber", "#SolarFlare", "#RadiantBloom"],
                themeTarget: .energeticAmber
            ),
            CatalogFeatureItem(
                id: "theme-playful-emerald",
                title: "Living Atmosphere: Playful Emerald",
                category: .themes,
                icon: "leaf.fill",
                badge: "Living Atmosphere",
                badgeColor: Color(red: 0.20, green: 0.85, blue: 0.55),
                description: "Bamboo jade vitality, refreshing botanical vibrancy, and spring sunlight with breezy organic animations.",
                tags: ["#Emerald", "#Botanical", "#SpringVitality"],
                themeTarget: .playfulEmerald
            ),
            CatalogFeatureItem(
                id: "theme-live-preview",
                title: "Interactive Atmosphere Live Preview",
                category: .themes,
                icon: "gauge.with.dots.needle.bottom.50percent",
                badge: "Metal 120 FPS",
                badgeColor: .cyan,
                shortcut: "⌘,",
                description: "Live Metal and TimelineView atmosphere card in Settings rendering caustics, pillows, glass, and living smoke shaders in real time.",
                tags: ["#LivePreview", "#Settings", "#Metal120FPS"],
                tabTarget: .settings,
                actionLabel: "Open Settings"
            ),

            // ── Genio Studio IDE ──
            CatalogFeatureItem(
                id: "ide-vscode-studio",
                title: "Genio Embedded VS Code Studio",
                category: .ideEditor,
                icon: "macwindow",
                badge: "IDE Core",
                badgeColor: .blue,
                shortcut: "⌘E / /editor",
                description: "Full integrated development environment powered by VS Code web engine with Language Server Protocol (LSP) and syntax highlighting.",
                tags: ["#VSCode", "#SyntaxHighlight", "#LSP"],
                tabTarget: .editor,
                actionLabel: "Open Editor"
            ),
            CatalogFeatureItem(
                id: "ide-file-tree",
                title: "Finder-Style File Tree Browser",
                category: .ideEditor,
                icon: "folder.fill",
                badge: "File System",
                badgeColor: .teal,
                shortcut: "⌘F / /files",
                description: "Directory tree explorer with staged file chips, folder navigation, inline file renaming, and quick reveal in macOS Finder.",
                tags: ["#FileBrowser", "#DirectoryTree", "#Staging"],
                tabTarget: .files,
                actionLabel: "Open Files"
            ),
            CatalogFeatureItem(
                id: "ide-smart-viewer",
                title: "Smart Multi-Format File Viewer",
                category: .ideEditor,
                icon: "doc.text.magnifyingglass",
                badge: "Auto-Routing",
                badgeColor: .purple,
                description: "Automatic format detection routing code to Monaco/VSCode, markdown to formatted preview, images to Metal viewer, and JSON/plist to structured tree.",
                tags: ["#AutoRouting", "#Markdown", "#JSON", "#Images"],
                tabTarget: .files,
                actionLabel: "Open Files"
            ),
            CatalogFeatureItem(
                id: "ide-git-diff",
                title: "Side-by-Side Git Diff Viewer",
                category: .ideEditor,
                icon: "square.split.2x1.fill",
                badge: "Patch Analysis",
                badgeColor: .indigo,
                description: "Side-by-side and unified patch inspector with line-by-line additions, deletions, hunk navigation, and commit staging.",
                tags: ["#DiffReview", "#ColorCoded", "#Staging"],
                tabTarget: .github,
                actionLabel: "View Diff"
            ),
            CatalogFeatureItem(
                id: "ide-quick-creator",
                title: "Instant Project & File Creator",
                category: .ideEditor,
                icon: "plus.rectangle.fill.on.rectangle.fill",
                badge: "Scaffolding",
                badgeColor: .yellow,
                shortcut: "⌘N / /new",
                description: "Quick modal sheet for generating new files and project scaffolding for Swift, Python, HTML/CSS, TypeScript, Rust, and Shell.",
                tags: ["#Scaffolding", "#Templates", "#QuickCreate"],
                tabTarget: .files,
                actionLabel: "Open Creator"
            ),

            // ── Media & Images ──
            CatalogFeatureItem(
                id: "media-jpg-metal",
                title: "Native JPG & JPEG Rendering Engine",
                category: .media,
                icon: "photo.fill",
                badge: "Hardware Metal",
                badgeColor: .orange,
                description: "High-speed hardware-accelerated Metal image decoder with automatic EXIF orientation normalization and sub-pixel edge anti-aliasing.",
                tags: ["#JPEG", "#EXIFAutoRotate", "#Metal"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "media-gif-player",
                title: "Animated GIF Player with Loop Engine",
                category: .media,
                icon: "film.fill",
                badge: "Frame Timing",
                badgeColor: .pink,
                description: "Native frame timing accumulator, dynamic play/pause controls, frame scrubbing, and infinite loop playback.",
                tags: ["#GIF", "#FrameAccumulator", "#Playback"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "media-universal-formats",
                title: "Universal Formats (PNG, WebP, SVG, ICNS)",
                category: .media,
                icon: "photo.stack.fill",
                badge: "Universal Loader",
                badgeColor: .teal,
                description: "Auto-detecting media engine supporting lossless WebP, vector SVG rasterization, PNG alpha channels, and macOS ICNS icons.",
                tags: ["#WebP", "#SVG", "#PNG", "#ICNS"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "media-drag-drop",
                title: "Drag & Drop Image Attachment",
                category: .media,
                icon: "arrow.down.doc.fill",
                badge: "Chat Attachment",
                badgeColor: .cyan,
                description: "Drop images directly into the chat input drawer to inspect, thumbnail, and include with your prompts to multimodal LLMs.",
                tags: ["#DragAndDrop", "#Multimodal", "#Thumbnails"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "media-quicklook",
                title: "Fullscreen QuickLook Modal Inspector",
                category: .media,
                icon: "arrow.up.left.and.arrow.down.right",
                badge: "Interactive Zoom",
                badgeColor: .purple,
                description: "Full-resolution photo viewer modal with smooth gestures, pinch-to-zoom, pan, and clipboard copy.",
                tags: ["#QuickLook", "#FullRes", "#ZoomPan"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),

            // ── Glass Chat & Dock ──
            CatalogFeatureItem(
                id: "chat-pinned-drawer",
                title: "Slideable Pinned Input Drawer",
                category: .glassChat,
                icon: "rectangle.split.2x1",
                badge: "Terminal-Style",
                badgeColor: .blue,
                shortcut: "⌘\\",
                description: "Slideable split bar keeping chat input and history locked in place on screen while files or code editor are navigated side-by-side.",
                tags: ["#PinnedDrawer", "#SlideableSplit", "#SplitLock"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "chat-zoom-stepper",
                title: "Dynamic Chat Text Zoom Stepper",
                category: .glassChat,
                icon: "textformat.size",
                badge: "Zoom Engine",
                badgeColor: .cyan,
                shortcut: "⌘+ / ⌘- / ⌘0",
                description: "Fluid text scaling from 50% to 200% across all chat bubbles and input areas with automatic persistent state saving.",
                tags: ["#TextZoom", "#Accessibility", "#50to200Percent"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "chat-pillow-white-font",
                title: "Pillow White 13pt Bold Typography",
                category: .glassChat,
                icon: "character.textbox",
                badge: "High-Contrast",
                badgeColor: .white,
                description: "High-legibility bold 13pt typography in pure pillow white (#FFFFFF) with ambient soft shadow for maximum readability on any background.",
                tags: ["#PillowWhite", "#Bold13pt", "#HighLegibility"],
                tabTarget: .chat,
                actionLabel: "Open Chat"
            ),
            CatalogFeatureItem(
                id: "chat-terminal-cookbook",
                title: "Genie Terminal Studio & Cookbook",
                category: .glassChat,
                icon: "terminal.fill",
                badge: "Terminal Studio",
                badgeColor: .green,
                shortcut: "⌘T / /terminal",
                description: "Built-in zsh command-line terminal with tab support, interactive command cookbooks, script runner, and live execution streaming.",
                tags: ["#Terminal", "#Zsh", "#Cookbook"],
                tabTarget: .terminal,
                actionLabel: "Open Terminal"
            ),
            CatalogFeatureItem(
                id: "chat-browser-cradle",
                title: "Live WebKit Browser Cradle",
                category: .glassChat,
                icon: "globe",
                badge: "Browser",
                badgeColor: .teal,
                shortcut: "/browser",
                description: "Embedded WebKit browser with address navigation, developer tools, page inspection, and direct DOM interactions.",
                tags: ["#Browser", "#WebKit", "#DevTools"],
                tabTarget: .browser,
                actionLabel: "Open Browser"
            ),

            // ── GitHub Studio ──
            CatalogFeatureItem(
                id: "git-desktop-canvas",
                title: "GitHub Desktop Studio Canvas",
                category: .githubStudio,
                icon: "arrow.triangle.branch",
                badge: "GitHub Engine",
                badgeColor: Color(red: 0.58, green: 0.44, blue: 0.96),
                shortcut: "/github",
                description: "Native macOS GitHub desktop companion providing seamless repository navigation, commit tracking, and branch switching.",
                tags: ["#GitHubStudio", "#RepoViewer", "#GitBranches"],
                tabTarget: .github,
                actionLabel: "Open GitHub"
            ),
            CatalogFeatureItem(
                id: "git-branch-graph",
                title: "Interactive Branch Switcher & Commit Log",
                category: .githubStudio,
                icon: "arrow.triangle.swap",
                badge: "Branch Manager",
                badgeColor: .purple,
                description: "Instant branch switching menu, commit history tree, and working tree modification status badges.",
                tags: ["#BranchSwitcher", "#CommitLogs", "#GitTree"],
                tabTarget: .github,
                actionLabel: "Switch Branch"
            ),
            CatalogFeatureItem(
                id: "git-pr-hub",
                title: "Pull Request Review & Approvals Hub",
                category: .githubStudio,
                icon: "arrow.triangle.pull",
                badge: "PR Manager",
                badgeColor: .green,
                description: "Explore open pull requests, review changesets, verify CI status checks, and approve code reviews.",
                tags: ["#PullRequests", "#PRReview", "#StatusChecks"],
                tabTarget: .github,
                actionLabel: "View PRs"
            ),
            CatalogFeatureItem(
                id: "git-issues-tracker",
                title: "Issues Tracker & Issue Creator Modal",
                category: .githubStudio,
                icon: "circle.circle",
                badge: "Issue Tracker",
                badgeColor: .orange,
                description: "Track bug reports, feature requests, filter by labels, and draft new issues directly with modal composer.",
                tags: ["#Issues", "#IssueComposer", "#Labels"],
                tabTarget: .github,
                actionLabel: "View Issues"
            ),
            CatalogFeatureItem(
                id: "git-actions-cicd",
                title: "GitHub Actions CI/CD Workflow Monitor",
                category: .githubStudio,
                icon: "play.circle.fill",
                badge: "Workflows",
                badgeColor: .yellow,
                description: "Live workflow execution telemetry, run triggers, test statuses, build artifacts, and job step logs.",
                tags: ["#GitHubActions", "#Workflows", "#BuildLogs"],
                tabTarget: .github,
                actionLabel: "View Actions"
            ),
            CatalogFeatureItem(
                id: "git-feature-catalog",
                title: "GitHub Feature Catalog Tab & Sidebar",
                category: .githubStudio,
                icon: "square.grid.3x3.fill",
                badge: "Catalog Hub",
                badgeColor: .cyan,
                shortcut: "/catalog / /features",
                description: "Complete categorized encyclopedia of all Genie capabilities, shortcuts, themes, and engines with quick-jump action cards.",
                tags: ["#Catalog", "#Sidebar", "#Capabilities"],
                tabTarget: .github,
                actionLabel: "View Catalog"
            ),

            // ── AI Stations & VMs ──
            CatalogFeatureItem(
                id: "vms-dashboard",
                title: "AI Stations & Virtual Machines Dashboard",
                category: .vms,
                icon: "server.rack",
                badge: "Infrastructure",
                badgeColor: .teal,
                description: "Manage local and remote AI workstation virtual machines, containerized agent sandboxes, and cloud GPU clusters.",
                tags: ["#AIStations", "#RemoteVMs", "#Sandboxes"],
                tabTarget: .virtualMachines,
                actionLabel: "Open Stations"
            ),
            CatalogFeatureItem(
                id: "vms-vram-telemetry",
                title: "GPU Memory & VRAM Allocation Telemetry",
                category: .vms,
                icon: "gauge.with.dots.needle.67percent",
                badge: "VRAM Monitor",
                badgeColor: .blue,
                description: "Hardware telemetry monitoring dedicated VRAM allocation, temperature, compute bandwidth, and PCIe bus throughput.",
                tags: ["#VRAM", "#GPUAllocation", "#HardwareTelemetry"],
                tabTarget: .virtualMachines,
                actionLabel: "View Telemetry"
            ),

            // ── Sound & FX ──
            CatalogFeatureItem(
                id: "fx-spatial-audio",
                title: "Spatial Audio & Typewriter Chimes",
                category: .soundAndEffects,
                icon: "speaker.wave.2.fill",
                badge: "Haptic Audio",
                badgeColor: .pink,
                description: "Tactile mechanical keyboard typewriter audio feedback, subtle completion chimes, and spatial audio positioning.",
                tags: ["#SpatialAudio", "#MechanicalKeys", "#Chimes"],
                tabTarget: .soundAndEffects,
                actionLabel: "Open Audio"
            ),
            CatalogFeatureItem(
                id: "fx-living-smoke",
                title: "Living Smoke Particle Shaders",
                category: .soundAndEffects,
                icon: "smoke.fill",
                badge: "Metal Particles",
                badgeColor: .purple,
                description: "Billowing fluid smoke dynamics and ambient atmospheric particle drift running at locked 120 FPS on Apple Silicon.",
                tags: ["#SmokeDynamics", "#AmbientParticles", "#MetalShader"],
                tabTarget: .soundAndEffects,
                actionLabel: "Configure FX"
            ),

            // ── 120 FPS Performance ──
            CatalogFeatureItem(
                id: "perf-120fps-locked",
                title: "120 FPS ProMotion Locked Engine",
                category: .performance,
                icon: "bolt.fill",
                badge: "120 FPS Locked",
                badgeColor: .green,
                description: "DisplayLink and TimelineView synchronized continuous rendering pipeline designed specifically for Apple ProMotion displays.",
                tags: ["#ProMotion", "#120FPS", "#DisplayLink"],
                tabTarget: nil,
                actionLabel: nil
            ),
            CatalogFeatureItem(
                id: "perf-ipe-bitmask",
                title: "IPE Bitmask Prefilter Search Engine",
                category: .performance,
                icon: "line.3.horizontal.decrease.circle.fill",
                badge: "< 10 Microseconds",
                badgeColor: .yellow,
                description: "Nicholas Dudek's 64-bit character bitmask signature prefilter eliminating >90% of candidates in microseconds with zero false negatives.",
                tags: ["#IPEBitmask", "#MicrosecondSearch", "#ZeroFalseNegatives"],
                tabTarget: nil,
                actionLabel: nil
            )
        ]
    }
}

// MARK: - Catalog Models & Enums
public enum CatalogCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All Features"
    case aiModels = "AI & Models"
    case themes = "Apple 2028 Themes"
    case ideEditor = "Genio Studio IDE"
    case media = "Media & Images"
    case glassChat = "Glass Chat & Dock"
    case githubStudio = "GitHub Studio"
    case vms = "AI Stations"
    case soundAndEffects = "Sound & FX"
    case performance = "120 FPS Performance"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .aiModels: return "brain.head.profile"
        case .themes: return "paintpalette.fill"
        case .ideEditor: return "macwindow"
        case .media: return "photo.on.rectangle.angled"
        case .glassChat: return "bubble.left.and.bubble.right.fill"
        case .githubStudio: return "arrow.triangle.branch"
        case .vms: return "server.rack"
        case .soundAndEffects: return "speaker.wave.2.fill"
        case .performance: return "bolt.fill"
        }
    }
}

public struct CatalogFeatureItem: Identifiable {
    public let id: String
    public let title: String
    public let category: CatalogCategory
    public let icon: String
    public let badge: String
    public let badgeColor: Color
    public let shortcut: String?
    public let description: String
    public let tags: [String]
    public let themeTarget: GenieTheme?
    public let tabTarget: FinderWindowTab.TabKind?
    public let actionLabel: String?

    public init(
        id: String,
        title: String,
        category: CatalogCategory,
        icon: String,
        badge: String,
        badgeColor: Color,
        shortcut: String? = nil,
        description: String,
        tags: [String] = [],
        themeTarget: GenieTheme? = nil,
        tabTarget: FinderWindowTab.TabKind? = nil,
        actionLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.icon = icon
        self.badge = badge
        self.badgeColor = badgeColor
        self.shortcut = shortcut
        self.description = description
        self.tags = tags
        self.themeTarget = themeTarget
        self.tabTarget = tabTarget
        self.actionLabel = actionLabel
    }
}
