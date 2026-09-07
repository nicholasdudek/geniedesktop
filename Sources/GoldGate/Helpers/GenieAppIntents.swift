import AppIntents
import Foundation

// MARK: - Ask Genie AI Intent (Siri Voice & Shortcuts)
public struct AskGenieIntent: AppIntent {
    public static var title: LocalizedStringResource = "Ask Genie"
    public static var description = IntentDescription("Ask Genie AI a question or give it a task using your local models or cloud AI.")

    @Parameter(title: "Prompt")
    public var prompt: String

    public init() {}

    public init(prompt: String) {
        self.prompt = prompt
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        LocalModelManager.shared.generate(prompt: prompt)
        return .result(value: "Genie is answering: \(prompt)")
    }
}

// MARK: - Search Internet with Genie Intent
public struct SearchWithGenieIntent: AppIntent {
    public static var title: LocalizedStringResource = "Search with Genie"
    public static var description = IntentDescription("Search the internet using Genie's mini browser and AI web search.")

    @Parameter(title: "Query")
    public var query: String

    public init() {}

    public init(query: String) {
        self.query = query
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        MiniBrowserManager.shared.search(query: query)
        return .result(value: "Searching internet for \(query)")
    }
}

// MARK: - Save Genie Note Intent
public struct SaveGenieNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Save Genie Note"
    public static var description = IntentDescription("Save a rich text note in Genie and open it on screen.")

    @Parameter(title: "Content")
    public var content: String

    public init() {}

    public init(content: String) {
        self.content = content
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let fileURL = DesktopNotePrinter.shared.printNote(content: content, destinationFolder: nil, openInFile: true)
        let name = fileURL?.lastPathComponent ?? "Note"
        return .result(value: "Saved note \(name)")
    }
}

// MARK: - Siri Shortcuts Provider
public struct GenieShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskGenieIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Chat with \(.applicationName)"
            ],
            shortTitle: "Ask Genie",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: SearchWithGenieIntent(),
            phrases: [
                "Search with \(.applicationName)",
                "Internet search in \(.applicationName)"
            ],
            shortTitle: "Search with Genie",
            systemImageName: "globe"
        )
        AppShortcut(
            intent: SaveGenieNoteIntent(),
            phrases: [
                "Take a note with \(.applicationName)",
                "Save a note in \(.applicationName)"
            ],
            shortTitle: "Save Genie Note",
            systemImageName: "doc.text"
        )
    }
}
