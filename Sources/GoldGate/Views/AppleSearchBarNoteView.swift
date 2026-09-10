import AppKit
import SwiftUI
import ScreenCaptureKit

// MARK: - Bar Modes: Chat 💬, Search 🌐, Note 📄, Terminal 💻 & Polaroid 📸
public enum BarMode: String, CaseIterable {
    case chat = "chat"
    case search = "search"
    case apps = "apps"
    case file = "file"
    case terminal = "terminal"
    case polaroid = "polaroid"
    case screenMirror = "screenMirror"
    case vision = "vision"
    case settings = "settings"

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .search: return "globe"
        case .apps: return "square.grid.2x2.fill"
        case .file: return "doc.text.fill"
        case .terminal: return "terminal.fill"
        case .polaroid: return "camera.fill"
        case .screenMirror: return "iphone.gen3"
        case .vision: return "viewfinder.circle.fill"
        case .settings: return "slider.horizontal.3"
        }
    }

    public var iconColor: Color {
        switch self {
        case .chat: return Color(red: 0.0, green: 0.88, blue: 1.0)
        case .search: return Color(red: 0.15, green: 0.75, blue: 1.0)
        case .apps: return Color(red: 1.0, green: 0.60, blue: 0.20)
        case .file: return Color(red: 0.40, green: 0.90, blue: 0.65)
        case .terminal: return Color(red: 0.35, green: 0.90, blue: 0.45)
        case .polaroid: return Color(red: 1.0, green: 0.65, blue: 0.30)
        case .screenMirror: return Color(red: 0.20, green: 0.75, blue: 1.0)
        case .vision: return Color(red: 0.72, green: 0.45, blue: 1.0)
        case .settings: return Color(red: 0.95, green: 0.75, blue: 0.20)
        }
    }

    public var placeholder: String {
        switch self {
        case .chat: return "Converse with Executive Intelligence..."
        case .search: return "Query Global Knowledge & Web Index..."
        case .apps: return "Filter or launch installed applications..."
        case .file: return "Inscribe executive memorandum or draught..."
        case .terminal: return "Dispatch system shell directive (zsh)..."
        case .polaroid: return "Annotate visual capture & commit to Chrono-Record..."
        case .screenMirror: return "Query device telemetry or orchestrate Continuity Mirror..."
        case .vision: return "Extract screen text (OCR), or query visual AI..."
        case .settings: return "Search Genie preferences, intelligence, or appearance..."
        }
    }

    public var helpText: String {
        switch self {
        case .chat: return "Dialogue Studio — Neural Executive Assistant"
        case .search: return "Global Knowledge & Web Index Ingress"
        case .apps: return "Applications Viewer Box — Quick Launch 🪟"
        case .file: return "Executive Memorandum Portfolio"
        case .terminal: return "Precision System Directive Console"
        case .polaroid: return "High-Fidelity Optical Screen Record"
        case .screenMirror: return "Continuity Mirror — Device Synchronicity"
        case .vision: return "Optical Screen Vision & Neural OCR Engine"
        case .settings: return "Genie Consolidated Settings & Studio Inspector ⚙️"
        }
    }

    public var title: String {
        switch self {
        case .chat: return "Dialogue"
        case .search: return "Omni-Search"
        case .apps: return "Applications"
        case .file: return "Memorandum"
        case .terminal: return "Console"
        case .polaroid: return "Chrono-Capture"
        case .screenMirror: return "Continuity"
        case .vision: return "Vision OCR"
        case .settings: return "Settings"
        }
    }

    public func next() -> BarMode {
        switch self {
        case .chat: return .search
        case .search: return .apps
        case .apps: return .file
        case .file: return .terminal
        case .terminal: return .polaroid
        case .polaroid: return .screenMirror
        case .screenMirror: return .vision
        case .vision: return .settings
        case .settings: return .chat
        }
    }
}

// MARK: - Native Search & Note Text Field (Guaranteed Blinking Cursor & Key Handling)

final class FocusableSearchNSTextField: NSTextField {
    var onSubmit: (() -> Void)?
    var onEscape: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    static func roundedFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        if let desc = base.fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: desc, size: size) ?? base
        }
        return base
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let win = window else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: win
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            self?.forceBlinkingCursorFocus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.forceBlinkingCursorFocus()
        }
    }

    @objc private func windowDidBecomeKey() {
        forceBlinkingCursorFocus()
    }

    func forceBlinkingCursorFocus() {
        guard let win = self.window else { return }
        NSApp.activate(ignoringOtherApps: true)
        win.makeKey()
        win.makeFirstResponder(self)
        if let editor = win.fieldEditor(true, for: self) as? NSTextView {
            editor.insertionPointColor = .white
            let len = self.stringValue.utf16.count
            editor.setSelectedRange(NSRange(location: len, length: 0))
        }
        onFocusChanged?(true)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: true)
    }

    override func mouseDown(with event: NSEvent) {
        if let win = self.window {
            NSApp.activate(ignoringOtherApps: true)
            win.makeKey()
            win.makeFirstResponder(self)
        }
        super.mouseDown(with: event)
        if let win = self.window, let editor = win.fieldEditor(false, for: self) as? NSTextView {
            editor.insertionPointColor = .white
        }
        onFocusChanged?(true)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: true)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            if let win = self.window, let editor = win.fieldEditor(true, for: self) as? NSTextView {
                editor.insertionPointColor = .white
            }
            onFocusChanged?(true)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: true)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            onFocusChanged?(false)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: false)
        }
        return result
    }

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        if let editor = self.window?.fieldEditor(false, for: self) as? NSTextView {
            editor.insertionPointColor = .white
        }
    }
}

struct NativeSearchTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var onCommandSubmit: (() -> Void)? = nil
    var onEscape: () -> Void
    var onFocusChanged: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> FocusableSearchNSTextField {
        let tf = FocusableSearchNSTextField()
        tf.isBordered = false
        tf.drawsBackground = false
        tf.backgroundColor = .clear
        tf.textColor = .white
        tf.font = FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .regular)
        tf.focusRingType = .none
        tf.isBezeled = false
        tf.delegate = context.coordinator
        tf.lineBreakMode = .byTruncatingTail
        tf.maximumNumberOfLines = 1
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true

        let attrString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.40),
                .font: FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .medium)
            ]
        )
        tf.placeholderAttributedString = attrString
        context.coordinator.textField = tf

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleFocusNotification),
            name: NSNotification.Name("NexusFocusGenieSearchBar"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleAppendNotification(_:)),
            name: NSNotification.Name("NexusSearchBarAppendText"),
            object: nil
        )

        return tf
    }

    func updateNSView(_ nsView: FocusableSearchNSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusSearchBarTextDidChange"),
                object: text
            )
        }
        let attrString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.40),
                .font: FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .medium)
            ]
        )
        nsView.placeholderAttributedString = attrString
        nsView.onSubmit = onSubmit
        nsView.onEscape = onEscape
        nsView.onFocusChanged = onFocusChanged
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeSearchTextField
        weak var textField: FocusableSearchNSTextField?

        init(_ parent: NativeSearchTextField) {
            self.parent = parent
        }

        @objc func handleFocusNotification() {
            DispatchQueue.main.async { [weak self] in
                self?.textField?.forceBlinkingCursorFocus()
            }
        }

        @objc func handleAppendNotification(_ notif: Notification) {
            guard let str = notif.object as? String, self.textField != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let tf = self.textField else { return }
                if tf.stringValue.isEmpty {
                    tf.stringValue = str
                } else if !tf.stringValue.hasSuffix(str) {
                    tf.stringValue += str
                }
                self.parent.text = tf.stringValue
                tf.forceBlinkingCursorFocus()
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
            HapticFeedback.playTypingSound()
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusSearchBarTextDidChange"),
                object: tf.stringValue
            )
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            let currentEvent = NSApp.currentEvent
            let hasCommand = currentEvent?.modifierFlags.contains(.command) ?? false
            let hasShift = currentEvent?.modifierFlags.contains(.shift) ?? false

            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if hasCommand {
                    HapticFeedback.heavy()
                    parent.onCommandSubmit?() ?? parent.onSubmit()
                    return true
                } else if hasShift {
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    parent.onSubmit()
                    return true
                }
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }
}


// MARK: - Interactive Terminal Tool Runner Card
struct TerminalToolCardView: View {
    let command: String
    @State private var isExecuting: Bool = false
    @State private var output: String? = nil
    @State private var exitCode: Int32? = nil
    @State private var showCopied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header bar
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.yellow.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.green.opacity(0.85)).frame(width: 7, height: 7)
                }

                Image(systemName: "terminal.fill")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.green)

                Text("Terminal Tool")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if let code = exitCode {
                    Text(code == 0 ? "Exit 0 ✓" : "Exit \(code) ⚠️")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(code == 0 ? .green : .red)
                }

                // Copy Command
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    HapticFeedback.selection()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(showCopied ? .green : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Copy command")

                // Open in Terminal.app
                Button(action: {
                    LocalModelManager.shared.openInTerminalApp(command: command)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Terminal.app")
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Open and run in macOS Terminal.app")

                // Run Live Button
                Button(action: {
                    runCommand()
                }) {
                    HStack(spacing: 3) {
                        if isExecuting {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isExecuting ? "Running..." : "Run ⚡️")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green))
                }
                .buttonStyle(.plain)
                .disabled(isExecuting)
            }

            // Command display
            Text("$ \(command)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.95))
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.55)))

            // Live execution output (if run)
            if let out = output {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Execution Output:")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(out.isEmpty ? "(Process finished with no output)" : out)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.70)))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.green.opacity(0.35), lineWidth: 0.75)
        )
    }

    private func runCommand() {
        isExecuting = true
        HapticFeedback.selection()
        Task {
            let res = await LocalModelManager.shared.executeTerminalCommand(command)
            await MainActor.run {
                self.output = res.output
                self.exitCode = res.exitCode
                self.isExecuting = false
                if res.exitCode == 0 {
                    HapticFeedback.selection()
                } else {
                    HapticFeedback.heavy()
                }
            }
        }
    }
}
