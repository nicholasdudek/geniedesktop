import AppKit
import SwiftUI

// MARK: - GitHub Desktop Canvas View
public struct GitHubDesktopCanvasView: View {
    @ObservedObject var gitManager = GitRepositoryManager.shared
    @ObservedObject var localModels = LocalModelManager.shared
    @State private var selectedSubTab: String = "code" // "code", "pulls", "issues", "actions", "copilot"
    @State private var searchQuery: String = ""
    @State private var newIssueTitle: String = ""
    @State private var showingNewIssueModal: Bool = false
    @State private var commitMessageInput: String = "Update components and documentation"
    @State private var statusToast: String? = nil

    public init() {}

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
}
