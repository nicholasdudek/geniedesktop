import Foundation

// MARK: - 🏷️ macOS Shortcuts Catalog & Tags
public enum MacShortcutTag: String, CaseIterable, Codable, Sendable {
    case spotlight = "shortcut.spotlight"
    case missionControl = "shortcut.mission_control"
    case appExpose = "shortcut.app_expose"
    case launchpad = "shortcut.launchpad"
    case screenshot = "shortcut.screenshot"
    case screenRecord = "shortcut.screen_record"
    case lockScreen = "shortcut.lock_screen"
    case doNotDisturb = "shortcut.do_not_disturb"
    case showDesktop = "shortcut.show_desktop"
    case forceQuit = "shortcut.force_quit"
    case airdrop = "shortcut.airdrop"
    case siri = "shortcut.siri"
    case dictation = "shortcut.dictation"
    case emojiPalette = "shortcut.emoji_palette"
    case quickLook = "shortcut.quick_look"
    case stageManager = "shortcut.stage_manager"
    case appleShortcuts = "shortcut.apple_shortcuts"

    public var keywords: [String] {
        switch self {
        case .spotlight: return ["spotlight", "cmd space", "command space", "quick search"]
        case .missionControl: return ["mission control", "all windows", "expose all", "spaces"]
        case .appExpose: return ["app expose", "application windows", "app windows"]
        case .launchpad: return ["launchpad", "app launcher", "grid of apps"]
        case .screenshot: return ["screenshot", "screen capture", "snapshot", "cmd shift 4", "cmd shift 3", "polaroid", "grab screen", "capture screen"]
        case .screenRecord: return ["record screen", "screen recording", "screen video", "capture video"]
        case .lockScreen: return ["lock screen", "lock mac", "sleep display", "lock computer"]
        case .doNotDisturb: return ["do not disturb", "dnd", "focus mode", "silence notifications"]
        case .showDesktop: return ["show desktop", "minimize all", "clear screen", "f11"]
        case .forceQuit: return ["force quit", "kill app", "task kill", "opt cmd esc"]
        case .airdrop: return ["airdrop", "share file", "send to iphone", "beam file"]
        case .siri: return ["siri", "voice assistant", "ask siri"]
        case .dictation: return ["dictation", "speech to text", "voice typing"]
        case .emojiPalette: return ["emoji", "character viewer", "symbols palette"]
        case .quickLook: return ["quick look", "preview file", "spacebar preview"]
        case .stageManager: return ["stage manager", "organize windows", "window grouping"]
        case .appleShortcuts: return ["run shortcut", "shortcut", "apple shortcut", "workflow automation"]
        }
    }
}

// MARK: - 💻 macOS Programs & System Features Catalog
public enum MacProgramTag: String, CaseIterable, Codable, Sendable {
    case safari = "app.safari"
    case xcode = "app.xcode"
    case terminal = "app.terminal"
    case iterm = "app.iterm"
    case finder = "app.finder"
    case notes = "app.notes"
    case reminders = "app.reminders"
    case messages = "app.messages"
    case mail = "app.mail"
    case music = "app.music"
    case preview = "app.preview"
    case keynote = "app.keynote"
    case pages = "app.pages"
    case numbers = "app.numbers"
    case systemSettings = "app.system_settings"
    case activityMonitor = "app.activity_monitor"
    case photos = "app.photos"
    case calendar = "app.calendar"
    case calculator = "app.calculator"
    case textedit = "app.textedit"
    case console = "app.console"
    case diskUtility = "app.disk_utility"

    public var canonicalName: String {
        switch self {
        case .safari: return "Safari"
        case .xcode: return "Xcode"
        case .terminal: return "Terminal"
        case .iterm: return "iTerm"
        case .finder: return "Finder"
        case .notes: return "Notes"
        case .reminders: return "Reminders"
        case .messages: return "Messages"
        case .mail: return "Mail"
        case .music: return "Music"
        case .preview: return "Preview"
        case .keynote: return "Keynote"
        case .pages: return "Pages"
        case .numbers: return "Numbers"
        case .systemSettings: return "System Settings"
        case .activityMonitor: return "Activity Monitor"
        case .photos: return "Photos"
        case .calendar: return "Calendar"
        case .calculator: return "Calculator"
        case .textedit: return "TextEdit"
        case .console: return "Console"
        case .diskUtility: return "Disk Utility"
        }
    }

    public var keywords: [String] {
        switch self {
        case .safari: return ["safari", "web browser", "browse web", "open website", "surf web"]
        case .xcode: return ["xcode", "ios app", "swift code", "build project", "developer tools"]
        case .terminal: return ["terminal", "command line", "zsh", "bash", "shell", "run command", "cli"]
        case .iterm: return ["iterm", "iterm2"]
        case .finder: return ["finder", "file manager", "show in finder", "documents folder", "desktop folder"]
        case .notes: return ["apple notes", "notes app", "take note", "save note", "jot down", "quick note"]
        case .reminders: return ["reminders", "remind me", "todo", "todo list", "task reminder"]
        case .messages: return ["imessage", "ichat", "messages app", "send text", "send message", "chat with"]
        case .mail: return ["apple mail", "email", "inbox", "send email"]
        case .music: return ["apple music", "play song", "music", "spotify", "pause music", "soundtrack"]
        case .preview: return ["preview app", "open pdf", "view image", "pdf viewer"]
        case .keynote: return ["keynote", "slide deck", "presentation slides", "slides"]
        case .pages: return ["pages app", "word processor", "document editor"]
        case .numbers: return ["numbers app", "spreadsheet", "excel sheet"]
        case .systemSettings: return ["system settings", "system preferences", "preferences", "bluetooth settings", "wifi settings"]
        case .activityMonitor: return ["activity monitor", "task manager", "cpu usage", "ram usage", "kill process"]
        case .photos: return ["photos app", "photo library", "pictures album"]
        case .calendar: return ["calendar", "schedule", "events", "meeting"]
        case .calculator: return ["calculator", "calculate", "math"]
        case .textedit: return ["textedit", "plain text editor", "notepad"]
        case .console: return ["console", "system logs", "log stream"]
        case .diskUtility: return ["disk utility", "format drive", "partitions"]
        }
    }
}

// MARK: - 🎯 Intent Action Tags
public enum IntentActionTag: String, CaseIterable, Codable, Sendable {
    case appLaunch = "action.app_launch"
    case terminalExec = "action.terminal_exec"
    case shortcutRun = "action.shortcut_run"
    case noteCreate = "action.note_create"
    case reminderAdd = "action.reminder_add"
    case messageSend = "action.message_send"
    case screenshotCapture = "action.screenshot_capture"
    case screenRecord = "action.screen_record"
    case presentationBuild = "action.presentation_build"
    case chartRender = "action.chart_render"
    case mermaidRender = "action.mermaid_render"
    case stationSwitch = "action.station_switch"
    case webSearch = "action.web_search"
    case systemControl = "action.system_control"
    case conversational = "action.conversational"

    public var keywords: [String] {
        switch self {
        case .appLaunch: return ["open", "launch", "start", "run app", "boot up", "bring up"]
        case .terminalExec: return ["terminal", "bash", "zsh", "exec", "run script", "curl", "git", "brew", "echo", "ls", "grep"]
        case .shortcutRun: return ["shortcut", "workflow", "run workflow", "trigger shortcut"]
        case .noteCreate: return ["note", "take note", "write note", "save note", "jot", "memo", "document"]
        case .reminderAdd: return ["remind", "reminder", "todo", "task to", "remember to"]
        case .messageSend: return ["message", "imessage", "ichat", "text to", "send text", "notify"]
        case .screenshotCapture: return ["screenshot", "snapshot", "screen capture", "capture screen", "polaroid", "grab screen"]
        case .screenRecord: return ["screen record", "record screen", "capture video", "record desktop"]
        case .presentationBuild: return ["slides", "presentation", "deck", "keynote", "slide deck"]
        case .chartRender: return ["chart", "plot", "graph", "histogram", "bar chart", "line graph"]
        case .mermaidRender: return ["mermaid", "flowchart", "diagram", "architecture diagram", "state diagram"]
        case .stationSwitch: return ["switch station", "workspace station", "switch to chat", "switch to app", "desktop station"]
        case .webSearch: return ["search web", "google", "look up", "browse", "find online"]
        case .systemControl: return ["lock", "sleep", "restart", "shutdown", "mute", "volume", "brightness"]
        case .conversational: return ["hello", "hi", "explain", "why", "how", "what is", "tell me"]
        }
    }
}

// MARK: - 🧩 Tokenized Query Structure
public struct GenieTokenizedQuery: Codable, Sendable {
    public let rawQuery: String
    public let normalizedQuery: String
    public let wordTokens: [String]
    public let characterBigrams: [String]
    public let shortcutTags: [MacShortcutTag]
    public let programTags: [MacProgramTag]
    public let actionTags: [IntentActionTag]
    public let featureVector: [Double] // Fixed 64-dimensional numerical feature vector

    public init(
        rawQuery: String,
        normalizedQuery: String,
        wordTokens: [String],
        characterBigrams: [String],
        shortcutTags: [MacShortcutTag],
        programTags: [MacProgramTag],
        actionTags: [IntentActionTag],
        featureVector: [Double]
    ) {
        self.rawQuery = rawQuery
        self.normalizedQuery = normalizedQuery
        self.wordTokens = wordTokens
        self.characterBigrams = characterBigrams
        self.shortcutTags = shortcutTags
        self.programTags = programTags
        self.actionTags = actionTags
        self.featureVector = featureVector
    }
}

// MARK: - 🔬 Feature Tokenizer & Tagging Engine
public final class GenieFeatureTokenizer: Sendable {
    public static let shared = GenieFeatureTokenizer()

    public static let featureDimension = 64

    private init() {}

    // MARK: - Core Tokenization & Tagging
    public func tokenize(prompt: String) -> GenieTokenizedQuery {
        let normalized = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Extract words
        let rawTokens = normalized.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        // 2. Extract character bigrams for subword matching
        var bigrams: [String] = []
        if normalized.count >= 2 {
            let chars = Array(normalized)
            for i in 0..<(chars.count - 1) {
                if chars[i] != " " && chars[i+1] != " " {
                    bigrams.append(String([chars[i], chars[i+1]]))
                }
            }
        }

        // 3. Match Mac Shortcuts
        var matchedShortcuts: [MacShortcutTag] = []
        for shortcut in MacShortcutTag.allCases {
            if shortcut.keywords.contains(where: { normalized.contains($0) }) {
                matchedShortcuts.append(shortcut)
            }
        }

        // 4. Match Mac Programs & Features
        var matchedPrograms: [MacProgramTag] = []
        for program in MacProgramTag.allCases {
            if program.keywords.contains(where: { normalized.contains($0) }) {
                matchedPrograms.append(program)
            }
        }

        // 5. Match Intent Actions
        var matchedActions: [IntentActionTag] = []
        for action in IntentActionTag.allCases {
            if action.keywords.contains(where: { normalized.contains($0) }) {
                matchedActions.append(action)
            }
        }

        // 6. Build 64-Dimensional Numeric Feature Vector
        let vector = computeFeatureVector(
            normalized: normalized,
            words: rawTokens,
            shortcuts: matchedShortcuts,
            programs: matchedPrograms,
            actions: matchedActions
        )

        return GenieTokenizedQuery(
            rawQuery: prompt,
            normalizedQuery: normalized,
            wordTokens: rawTokens,
            characterBigrams: Array(Set(bigrams)),
            shortcutTags: matchedShortcuts,
            programTags: matchedPrograms,
            actionTags: matchedActions,
            featureVector: vector
        )
    }

    // MARK: - 64-Dimensional Feature Vector Construction
    /// Computes a standardized numerical vector representing:
    /// - [0..16]: Mac Shortcut Tag Activations (17 features)
    /// - [17..38]: Mac Program Tag Activations (22 features)
    /// - [39..53]: Intent Action Tag Activations (15 features)
    /// - [54]: Query length (normalized)
    /// - [55]: Word count (normalized)
    /// - [56]: Has question indicator (0.0 or 1.0)
    /// - [57]: Has imperative verb indicator (0.0 or 1.0)
    /// - [58]: Has code / syntax markers (0.0 or 1.0)
    /// - [59]: Has digits (0.0 or 1.0)
    /// - [60]: Has punctuation / exclamation (0.0 or 1.0)
    /// - [61..63]: Reserved / Padding for future expansion (0.0)
    private func computeFeatureVector(
        normalized: String,
        words: [String],
        shortcuts: [MacShortcutTag],
        programs: [MacProgramTag],
        actions: [IntentActionTag]
    ) -> [Double] {
        var vec = [Double](repeating: 0.0, count: GenieFeatureTokenizer.featureDimension)

        // Shortcuts: indices 0..16
        for (i, shortcut) in MacShortcutTag.allCases.enumerated() {
            if shortcuts.contains(shortcut) {
                vec[i] = 1.0
            }
        }

        // Programs: indices 17..38
        for (i, program) in MacProgramTag.allCases.enumerated() {
            if programs.contains(program) {
                vec[17 + i] = 1.0
            }
        }

        // Actions: indices 39..53
        for (i, action) in IntentActionTag.allCases.enumerated() {
            if actions.contains(action) {
                vec[39 + i] = 1.0
            }
        }

        // Structural and lexical signals
        vec[54] = min(1.0, Double(normalized.count) / 100.0)
        vec[55] = min(1.0, Double(words.count) / 20.0)
        
        let questionWords = ["what", "why", "how", "where", "who", "when", "?"]
        vec[56] = questionWords.contains(where: { normalized.contains($0) }) ? 1.0 : 0.0

        let imperativeWords = ["open", "run", "launch", "make", "create", "start", "take", "send", "show", "switch"]
        vec[57] = imperativeWords.contains(where: { words.contains($0) }) ? 1.0 : 0.0

        vec[58] = (normalized.contains("```") || normalized.contains("`") || normalized.contains("/") || normalized.contains("-")) ? 1.0 : 0.0
        vec[59] = normalized.rangeOfCharacter(from: .decimalDigits) != nil ? 1.0 : 0.0
        vec[60] = (normalized.contains("!") || normalized.contains(";")) ? 1.0 : 0.0

        return vec
    }
}
