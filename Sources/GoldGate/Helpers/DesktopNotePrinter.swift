import AppKit
import Foundation
import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Desktop Sticky Note Model & Manager

public struct DesktopStickyNote: Identifiable, Codable, Equatable {
    public var id: UUID
    public var content: String
    public var date: Date
    public var colorName: String // "Yellow", "Mint", "Rose", "Sky", "Lavender"
    public var posX: CGFloat
    public var posY: CGFloat
    public var isFolded: Bool
    public var isPolaroid: Bool
    public var photoPath: String?
    public var targetAppID: String?
    public var targetAppName: String?

    public init(
        id: UUID = UUID(),
        content: String,
        date: Date = Date(),
        colorName: String = "Yellow",
        posX: CGFloat = 80,
        posY: CGFloat = 120,
        isFolded: Bool = false,
        isPolaroid: Bool = false,
        photoPath: String? = nil,
        targetAppID: String? = nil,
        targetAppName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.colorName = colorName
        self.posX = posX
        self.posY = posY
        self.isFolded = isFolded
        self.isPolaroid = isPolaroid
        self.photoPath = photoPath
        self.targetAppID = targetAppID
        self.targetAppName = targetAppName
    }

    enum CodingKeys: String, CodingKey {
        case id, content, date, colorName, posX, posY, isFolded, isPolaroid, photoPath, targetAppID, targetAppName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        colorName = try c.decodeIfPresent(String.self, forKey: .colorName) ?? "Yellow"
        posX = try c.decodeIfPresent(CGFloat.self, forKey: .posX) ?? 80
        posY = try c.decodeIfPresent(CGFloat.self, forKey: .posY) ?? 120
        isFolded = try c.decodeIfPresent(Bool.self, forKey: .isFolded) ?? false
        isPolaroid = try c.decodeIfPresent(Bool.self, forKey: .isPolaroid) ?? false
        photoPath = try c.decodeIfPresent(String.self, forKey: .photoPath)
        targetAppID = try c.decodeIfPresent(String.self, forKey: .targetAppID)
        targetAppName = try c.decodeIfPresent(String.self, forKey: .targetAppName)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(content, forKey: .content)
        try c.encode(date, forKey: .date)
        try c.encode(colorName, forKey: .colorName)
        try c.encode(posX, forKey: .posX)
        try c.encode(posY, forKey: .posY)
        try c.encode(isFolded, forKey: .isFolded)
        try c.encode(isPolaroid, forKey: .isPolaroid)
        try c.encodeIfPresent(photoPath, forKey: .photoPath)
        try c.encodeIfPresent(targetAppID, forKey: .targetAppID)
        try c.encodeIfPresent(targetAppName, forKey: .targetAppName)
    }

    public var backgroundColor: Color {
        switch colorName {
        case "Mint": return Color(red: 0.80, green: 0.96, blue: 0.82)
        case "Rose": return Color(red: 0.98, green: 0.80, blue: 0.82)
        case "Sky": return Color(red: 0.80, green: 0.92, blue: 0.98)
        case "Lavender": return Color(red: 0.91, green: 0.83, blue: 0.98)
        default: return Color(red: 1.0, green: 0.95, blue: 0.65) // Classic Yellow
        }
    }

    public var headerColor: Color {
        switch colorName {
        case "Mint": return Color(red: 0.70, green: 0.90, blue: 0.72)
        case "Rose": return Color(red: 0.92, green: 0.70, blue: 0.72)
        case "Sky": return Color(red: 0.70, green: 0.85, blue: 0.92)
        case "Lavender": return Color(red: 0.83, green: 0.73, blue: 0.92)
        default: return Color(red: 0.95, green: 0.88, blue: 0.50)
        }
    }
}

// MARK: - Genie Document (.genie) Model
public struct GenieDocument: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var rawContent: String
    public var author: String
    public var createdAt: Date
    public var theme: String
    public var slides: [String]

    public init(
        id: UUID = UUID(),
        title: String,
        rawContent: String,
        author: String = "",
        createdAt: Date = Date(),
        theme: String = "Apple Glass",
        slides: [String] = []
    ) {
        self.id = id
        self.title = title
        self.rawContent = rawContent
        self.author = author
        self.createdAt = createdAt
        self.theme = theme
        self.slides = slides.isEmpty ? [rawContent] : slides
    }
}

public final class DesktopStickyManager: ObservableObject {
    public static let shared = DesktopStickyManager()

    private let storageKey = PrefKey.desktopStickyNotes

    @Published public var notes: [DesktopStickyNote] = [] {
        didSet {
            save()
        }
    }

    private init() {
        load()
    }

    public func addNote(
        content: String,
        colorName: String = "Yellow",
        at position: CGPoint? = nil,
        isPolaroid: Bool = false,
        photoPath: String? = nil
    ) {
        let staggerOffset = CGFloat(notes.count % 8) * 28.0
        let targetPos = position ?? CGPoint(x: 100 + staggerOffset, y: 130 + staggerOffset)
        let newNote = DesktopStickyNote(
            content: content,
            date: Date(),
            colorName: colorName,
            posX: targetPos.x,
            posY: targetPos.y,
            isPolaroid: isPolaroid,
            photoPath: photoPath
        )
        notes.append(newNote)
    }

    public func note(forAppID appID: String) -> DesktopStickyNote? {
        notes.first { $0.targetAppID == appID }
    }

    @MainActor
    public func setAppNote(appID: String, appName: String, content: String, colorName: String = "Yellow") {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let idx = notes.firstIndex(where: { $0.targetAppID == appID }) {
            if trimmed.isEmpty {
                notes.remove(at: idx)
            } else {
                notes[idx].content = trimmed
                notes[idx].colorName = colorName
                notes[idx].date = Date()
            }
        } else if !trimmed.isEmpty {
            let note = DesktopStickyNote(
                content: trimmed,
                date: Date(),
                colorName: colorName,
                targetAppID: appID,
                targetAppName: appName
            )
            notes.append(note)
        }
        save()
    }

    @MainActor
    public func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    @MainActor
    public func updateContent(id: UUID, newContent: String) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].content = newContent
        }
    }

    @MainActor
    public func updatePhoto(id: UUID, photoPath: String?) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].photoPath = photoPath
            notes[idx].isPolaroid = (photoPath != nil)
        }
    }

    public func updatePosition(id: UUID, newX: CGFloat, newY: CGFloat) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].posX = newX
            notes[idx].posY = newY
        }
    }

    public func toggleFold(id: UUID) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].isFolded.toggle()
        }
    }

    @MainActor
    public func clearAll() {
        notes.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DesktopStickyNote].self, from: data) {
            self.notes = decoded
        }
    }
}

// MARK: - Desktop Note Formats (Picture vs Simple vs Web)

public enum NoteOutputDestination: String, CaseIterable, Identifiable {
    // 📸 Picture Formats
    case polaroidPng = "Polaroid Photo (.png)"
    case glassCardPng = "Modern Card (.png)"

    // 📄 Simple & Document Formats
    case markdownMd = "Markdown Note (.md)"
    case webCardHtml = "Web Page (.html)"
    case desktopTxt = "Notepad Receipt (.txt)"
    case stickyNote = "Sticky Note"
    case allFormats = "All Formats"

    public var id: String { rawValue }

    public var isPictureFormat: Bool {
        switch self {
        case .polaroidPng, .glassCardPng: return true
        default: return false
        }
    }

    public var shortLabel: String {
        switch self {
        case .polaroidPng: return "Polaroid"
        case .glassCardPng: return "Card"
        case .markdownMd: return "Markdown"
        case .webCardHtml: return "HTML"
        case .desktopTxt: return "Text"
        case .stickyNote: return "Sticky"
        case .allFormats: return "All"
        }
    }

    public var icon: String {
        switch self {
        case .polaroidPng: return "camera.metering.spot"
        case .glassCardPng: return "photo.on.rectangle.angled"
        case .markdownMd: return "text.badge.star"
        case .webCardHtml: return "globe"
        case .desktopTxt: return "doc.text.fill"
        case .stickyNote: return "note.text"
        case .allFormats: return "sparkles.rectangle.stack.fill"
        }
    }

    public var actionButtonTitle: String {
        switch self {
        case .polaroidPng: return "Snapshot"
        case .glassCardPng: return "Snap Card"
        case .markdownMd: return "Save .md"
        case .webCardHtml: return "Export HTML"
        case .desktopTxt: return "Print"
        case .stickyNote: return "Sticky"
        case .allFormats: return "Capture All"
        }
    }

    public var actionButtonIcon: String {
        switch self {
        case .polaroidPng: return "camera.fill"
        case .glassCardPng: return "photo.fill"
        case .markdownMd: return "arrow.down.doc.fill"
        case .webCardHtml: return "network"
        case .desktopTxt: return "printer.fill"
        case .stickyNote: return "note.text.badge.plus"
        case .allFormats: return "sparkles"
        }
    }
}

// MARK: - Curated Note Templates & Frame Styles

public enum NoteTemplateStyle: String, CaseIterable, Identifiable {
    case classicDouble = "Classic Double Frame (╔═╗)"
    case starburst = "Vintage Starburst (★─★)"
    case decoOrnamental = "Art Deco Luxury (✦─✦)"
    case cyberTerminal = "Cyber Terminal ([▓▓])"
    case modernExecutive = "Executive Markdown (.md)"
    case developerScratch = "Developer Scratchpad (.md)"
    case interactiveWeb = "Glassmorphic Web Page (.html)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .classicDouble: return "square.grid.3x3.topleft.filled"
        case .starburst: return "sparkle"
        case .decoOrnamental: return "suit.diamond.fill"
        case .cyberTerminal: return "terminal.fill"
        case .modernExecutive: return "doc.richtext"
        case .developerScratch: return "curlybraces.square.fill"
        case .interactiveWeb: return "globe"
        }
    }
}

// MARK: - Standard Genie Install Directory Architecture ("make a standard install directory where it all goes")
public struct GenieStandardDirectories {
    public static var rootURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let genieRoot = appSupport.appendingPathComponent("Genie")
        try? FileManager.default.createDirectory(at: genieRoot, withIntermediateDirectories: true)
        return genieRoot
    }

    public static var notesURL: URL {
        let url = rootURL.appendingPathComponent("Notes")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var polaroidsURL: URL {
        let url = rootURL.appendingPathComponent("Polaroids")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var chatsURL: URL {
        let url = rootURL.appendingPathComponent("Chats")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var presentationsURL: URL {
        let url = rootURL.appendingPathComponent("Presentations")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var documentsURL: URL {
        let url = rootURL.appendingPathComponent("Documents")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var scriptsURL: URL {
        let url = rootURL.appendingPathComponent("Scripts")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var recordingsURL: URL {
        let url = rootURL.appendingPathComponent("Recordings")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static func chatSessionFolderURL(sessionId: UUID, title: String? = nil) -> (root: URL, documents: URL, presentations: URL, images: URL, notes: URL) {
        let cleanTitle: String
        if let title = title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let filtered = title.components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "_")
            cleanTitle = filtered.isEmpty ? "Chat" : String(filtered.prefix(32))
        } else {
            cleanTitle = "Chat"
        }
        let shortId = String(sessionId.uuidString.prefix(8))
        let folderName = "\(cleanTitle)_\(shortId)"
        let sessionRoot = chatsURL.appendingPathComponent(folderName, isDirectory: true)

        let documentsDir = sessionRoot.appendingPathComponent("documents", isDirectory: true)
        let presentationsDir = sessionRoot.appendingPathComponent("presentations", isDirectory: true)
        let imagesDir = sessionRoot.appendingPathComponent("images", isDirectory: true)
        let notesDir = sessionRoot.appendingPathComponent("notes", isDirectory: true)

        try? FileManager.default.createDirectory(at: sessionRoot, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: documentsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: presentationsDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)

        return (root: sessionRoot, documents: documentsDir, presentations: presentationsDir, images: imagesDir, notes: notesDir)
    }
}

public final class DesktopNotePrinter {
    public static let shared = DesktopNotePrinter()

    private init() {}

    public static var notesFolderURL: URL {
        if let customPath = UserDefaults.standard.string(forKey: PrefKey.notesFolderPath),
           !customPath.isEmpty {
            let url = URL(fileURLWithPath: customPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return GenieStandardDirectories.notesURL
    }

    @MainActor
    public static func promptForNotesLocationIfNeeded(completion: @escaping (URL) -> Void) {
        let hasChosen = UserDefaults.standard.bool(forKey: PrefKey.hasChosenNotesLocation)
        if hasChosen, let customPath = UserDefaults.standard.string(forKey: PrefKey.notesFolderPath), !customPath.isEmpty {
            let url = URL(fileURLWithPath: customPath)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            completion(url)
            return
        }

        // First time choosing location! Default to ~/Desktop/Genie Notes
        let defaultFolder = notesFolderURL
        try? FileManager.default.createDirectory(at: defaultFolder, withIntermediateDirectories: true)

        let panel = NSOpenPanel()
        panel.title = "Choose Location for Genie Notes"
        panel.message = "Choose where Genie should save your Documents & Notes (Default: Desktop/Genie Notes)"
        panel.prompt = "Save Notes Here"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = defaultFolder

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            let chosenURL: URL
            if response == .OK, let selected = panel.url {
                chosenURL = selected
            } else {
                chosenURL = defaultFolder
            }
            UserDefaults.standard.set(chosenURL.path, forKey: PrefKey.notesFolderPath)
            UserDefaults.standard.set(true, forKey: PrefKey.hasChosenNotesLocation)
            try? FileManager.default.createDirectory(at: chosenURL, withIntermediateDirectories: true)
            completion(chosenURL)
        }
    }

    /// Builds a beautiful native Apple Rich Text document with typography and metadata
    public func buildRichTextDocument(content: String, title: String) -> NSAttributedString {
        let titleFont = NSFont.systemFont(ofSize: 18, weight: .bold)
        let metaFont = NSFont.systemFont(ofSize: 11, weight: .regular)
        let bodyFont = NSFont.systemFont(ofSize: 13, weight: .regular)
        let secondaryColor = NSColor.secondaryLabelColor
        let primaryColor = NSColor.labelColor

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .full
        displayFormatter.timeStyle = .short
        let dateString = displayFormatter.string(from: Date())

        let userName = NSFullUserName().isEmpty ? (NSUserName().isEmpty ? "macOS User" : NSUserName()) : NSFullUserName()

        let result = NSMutableAttributedString()

        // Document Title
        result.append(NSAttributedString(string: "\(title)\n", attributes: [
            .font: titleFont,
            .foregroundColor: primaryColor
        ]))

        // Metadata Header
        result.append(NSAttributedString(string: "\(dateString)  •  \(userName)  •  Genie Document\n\n", attributes: [
            .font: metaFont,
            .foregroundColor: secondaryColor
        ]))

        // Body Content with clean paragraph spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.paragraphSpacing = 8.0
        result.append(NSAttributedString(string: "\(content)\n", attributes: [
            .font: bodyFont,
            .foregroundColor: primaryColor,
            .paragraphStyle: paragraphStyle
        ]))

        return result
    }

    /// Formats note content and writes a native Apple Rich Text (.rtf) and Genie Document (.genie) file to Genie Notes
    @discardableResult
    public func printNote(content: String, destinationFolder: URL? = nil, openInFile: Bool = true) -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let targetFolderURL = destinationFolder ?? Self.notesFolderURL
        try? FileManager.default.createDirectory(at: targetFolderURL, withIntermediateDirectories: true)

        let firstLine = trimmed.components(separatedBy: .newlines).first ?? "QuickNote"
        let sanitizedTitle = sanitizeFilename(firstLine)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        // 1. Save Apple Native Rich Text Format (.rtf) for Instant QuickLook / TextEdit / Pages
        let rtfFilename = "Note - \(sanitizedTitle) - \(timestamp).rtf"
        let rtfTargetURL = targetFolderURL.appendingPathComponent(rtfFilename)
        let attrStr = buildRichTextDocument(content: trimmed, title: sanitizedTitle)
        if let rtfData = try? attrStr.data(from: NSRange(location: 0, length: attrStr.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            try? rtfData.write(to: rtfTargetURL, options: .atomic)
        }

        // 2. Save Native Genie Document (.genie) containing slides, word features, and metadata
        let slidesList = trimmed.components(separatedBy: "\n---\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let genieDoc = GenieDocument(
            title: sanitizedTitle,
            rawContent: trimmed,
            author: NSFullUserName().isEmpty ? NSUserName() : NSFullUserName(),
            slides: slidesList
        )
        let genieFilename = "Note - \(sanitizedTitle) - \(timestamp).genie"
        let genieTargetURL = targetFolderURL.appendingPathComponent(genieFilename)
        if let data = try? JSONEncoder().encode(genieDoc) {
            try? data.write(to: genieTargetURL, options: .atomic)
        }

        // 3. Pop it up on the screen in the file (TextEdit / native rich text viewer)
        if openInFile {
            DispatchQueue.main.async {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.open(rtfTargetURL, configuration: config) { _, error in
                    if error != nil {
                        NSWorkspace.shared.open(rtfTargetURL)
                    }
                }
            }
        }

        return rtfTargetURL
    }

    @discardableResult
    public func printNoteToDesktop(content: String, openInFile: Bool = true) -> URL? {
        return printNote(content: content, destinationFolder: nil, openInFile: openInFile)
    }

    /// Sends note directly to Apple's native macOS Stickies.app
    public func saveToStickies(content: String, color: String = "Yellow", isPolaroid: Bool = false, photoPath: String? = nil) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        openStickiesApp(content: trimmed.isEmpty ? nil : trimmed)
    }

    // MARK: - 📸 Picture Formats: Polaroid Snapshot & Modern Card

    /// Renders an authentic vintage Polaroid photo and saves it to the chosen destination folder or Genie Polaroids directory
    @discardableResult
    public func savePolaroidToDesktop(content: String, destinationFolder: URL? = nil, photoPath: String? = nil, photoImage: NSImage? = nil, fontName: String = "SF Rounded", themeName: String = "Apple Glass") -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveContent = trimmed.isEmpty ? (photoPath != nil || photoImage != nil ? "Snapshot" : "Quick Note") : trimmed

        let image = generatePolaroidImage(content: effectiveContent, photoPath: photoPath, photoImage: photoImage, fontName: fontName, themeName: themeName)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let targetFolder = destinationFolder ?? GenieStandardDirectories.polaroidsURL
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        let firstLine = effectiveContent.components(separatedBy: .newlines).first ?? "Polaroid"
        let sanitizedTitle = sanitizeFilename(firstLine)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "Polaroid - \(sanitizedTitle) - \(timestamp).png"
        let targetURL = targetFolder.appendingPathComponent(filename)

        do {
            try pngData.write(to: targetURL, options: .atomic)
            HapticFeedback.heavy()
            HapticFeedback.playPrinterSound()
            return targetURL
        } catch {
            print("DesktopNotePrinter savePolaroidToDesktop error: \(error)")
            return nil
        }
    }

    /// Generates high-res authentic vintage Polaroid NSImage (supporting custom uploaded photos)
    public func generatePolaroidImage(content: String, photoPath: String? = nil, photoImage: NSImage? = nil, fontName: String = "SF Rounded", themeName: String = "Apple Glass") -> NSImage {
        let cardW: CGFloat = 560
        let cardH: CGFloat = 680
        let image = NSImage(size: NSSize(width: cardW, height: cardH))
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        // 1. Polaroid Cream Card Base
        let cardRect = CGRect(x: 0, y: 0, width: cardW, height: cardH)
        let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.saveGState()
        ctx.addPath(cardPath)
        ctx.setFillColor(CGColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0))
        ctx.fillPath()

        // Subtle vintage paper card stroke
        ctx.addPath(cardPath)
        ctx.setStrokeColor(CGColor(red: 0.86, green: 0.84, blue: 0.80, alpha: 0.85))
        ctx.setLineWidth(1.5)
        ctx.strokePath()
        ctx.restoreGState()

        // 2. Photo Area (Polaroid format: side/top 36px margins, tall bottom 136px chin)
        let sideMargin: CGFloat = 36
        let topMargin: CGFloat = 36
        let bottomChin: CGFloat = 136
        let photoW = cardW - (sideMargin * 2)
        let photoH = cardH - topMargin - bottomChin
        let photoRect = CGRect(x: sideMargin, y: bottomChin, width: photoW, height: photoH)

        let photoPathShape = CGPath(roundedRect: photoRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.saveGState()
        ctx.addPath(photoPathShape)
        ctx.clip()

        // Check if an uploaded photo or in-memory camera photo is provided
        var didDrawUserPhoto = false
        if let directImg = photoImage {
            directImg.draw(in: photoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            didDrawUserPhoto = true
        } else if let p = photoPath, FileManager.default.fileExists(atPath: p), let userImg = NSImage(contentsOfFile: p) {
            userImg.draw(in: photoRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            didDrawUserPhoto = true
        }

        let theme = themeColorsFor(theme: themeName)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        if !didDrawUserPhoto {
            // Theme-responsive photo background gradient
            let cgColors = [
                CGColor(red: theme.bgColors[0].r, green: theme.bgColors[0].g, blue: theme.bgColors[0].b, alpha: 1.0),
                CGColor(red: theme.bgColors[1].r, green: theme.bgColors[1].g, blue: theme.bgColors[1].b, alpha: 1.0)
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0.0, 1.0]) {
                ctx.drawLinearGradient(gradient, start: CGPoint(x: photoRect.midX, y: photoRect.maxY), end: CGPoint(x: photoRect.midX, y: photoRect.minY), options: [])
            }

            // Draw Note Content Text in chosen typography
            let fontSize: CGFloat = content.count < 80 ? 24 : (content.count < 180 ? 20 : 16)
            let font = resolveNSFont(name: fontName, size: fontSize)
            let textColor = NSColor(red: theme.textR, green: theme.textG, blue: theme.textB, alpha: 1.0)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineSpacing = 4
            paragraphStyle.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]

            let textInsetRect = photoRect.insetBy(dx: 28, dy: 24)
            let attrString = NSAttributedString(string: content, attributes: attributes)
            attrString.draw(with: textInsetRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        } else if !content.isEmpty && content != "Snapshot" {
            // Semi-translucent caption chip over bottom of photo
            let chipH: CGFloat = 54
            let chipRect = CGRect(x: photoRect.minX, y: photoRect.minY, width: photoRect.width, height: chipH)
            ctx.setFillColor(CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.55))
            ctx.fill(chipRect)

            let font = NSFont.systemFont(ofSize: 14, weight: .medium)
            let para = NSMutableParagraphStyle()
            para.alignment = .left
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .paragraphStyle: para
            ]
            let textRect = chipRect.insetBy(dx: 14, dy: 8)
            let attrStr = NSAttributedString(string: content, attributes: attrs)
            attrStr.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        }

        // Glossy film reflection highlight
        let glossColors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.10),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        ] as CFArray
        if let glossGrad = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(glossGrad, start: CGPoint(x: photoRect.minX, y: photoRect.maxY), end: CGPoint(x: photoRect.maxX, y: photoRect.midY), options: [])
        }
        ctx.restoreGState()

        // 3. Photo frame inner bevel
        ctx.saveGState()
        ctx.addPath(photoPathShape)
        ctx.setStrokeColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.20))
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        ctx.restoreGState()

        // 4. Handwritten Caption on the Bottom Chin
        let captionDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let captionFont = resolveNSFont(name: "Bradley Hand", size: 17)
        let captionColor = NSColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 0.85)

        let captionPara = NSMutableParagraphStyle()
        captionPara.alignment = .center
        let captionAttrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: captionColor,
            .paragraphStyle: captionPara
        ]

        let captionRect = CGRect(x: sideMargin, y: 38, width: photoW, height: 46)
        let captionStr = NSAttributedString(string: "\(captionDate) • 📷 INSTANT MEMO", attributes: captionAttrs)
        captionStr.draw(in: captionRect)

        // Polaroid emblem mark
        let markFont = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
        let markAttrs: [NSAttributedString.Key: Any] = [
            .font: markFont,
            .foregroundColor: NSColor.black.withAlphaComponent(0.35),
            .paragraphStyle: captionPara
        ]
        let markRect = CGRect(x: sideMargin, y: 14, width: photoW, height: 18)
        let markStr = NSAttributedString(string: "GENIE POLAROID 600 • HIGH FIDELITY", attributes: markAttrs)
        markStr.draw(in: markRect)

        image.unlockFocus()
        return image
    }

    /// Renders a modern Apple-style frosted glass card and saves it to chosen destination folder or Genie Notes
    @discardableResult
    public func saveModernCardToDesktop(content: String, destinationFolder: URL? = nil, fontName: String = "SF Rounded", themeName: String = "Apple Glass") -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let cardW: CGFloat = 640
        let cardH: CGFloat = 380
        let image = NSImage(size: NSSize(width: cardW, height: cardH))
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        let theme = themeColorsFor(theme: themeName)
        let rect = CGRect(x: 0, y: 0, width: cardW, height: cardH)
        let path = CGPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerWidth: 20, cornerHeight: 20, transform: nil)

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = [
            CGColor(red: theme.bgColors[0].r, green: theme.bgColors[0].g, blue: theme.bgColors[0].b, alpha: 0.95),
            CGColor(red: theme.bgColors[1].r, green: theme.bgColors[1].g, blue: theme.bgColors[1].b, alpha: 0.98)
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        }

        let fontSize: CGFloat = content.count < 80 ? 24 : (content.count < 180 ? 20 : 16)
        let font = resolveNSFont(name: fontName, size: fontSize)
        let textColor = NSColor(red: theme.textR, green: theme.textG, blue: theme.textB, alpha: 1.0)

        let para = NSMutableParagraphStyle()
        para.alignment = .left
        para.lineSpacing = 5

        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: para
        ]

        let textRect = rect.insetBy(dx: 40, dy: 60)
        let attrStr = NSAttributedString(string: content, attributes: textAttrs)
        attrStr.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])

        // Top badge
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let badgeFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: NSColor(red: theme.accentR, green: theme.accentG, blue: theme.accentB, alpha: 0.9)
        ]
        let badgeStr = NSAttributedString(string: "GENIE DESKTOP NOTE • \(dateStr)", attributes: badgeAttrs)
        badgeStr.draw(at: CGPoint(x: 40, y: cardH - 42))

        ctx.restoreGState()

        // Border stroke
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setStrokeColor(CGColor(red: theme.accentR, green: theme.accentG, blue: theme.accentB, alpha: 0.45))
        ctx.setLineWidth(2.0)
        ctx.strokePath()
        ctx.restoreGState()

        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let targetFolder = destinationFolder ?? GenieStandardDirectories.notesURL
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? "Card"
        let sanitizedTitle = sanitizeFilename(firstLine)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let targetURL = targetFolder.appendingPathComponent("Card - \(sanitizedTitle) - \(timestamp).png")
        do {
            try pngData.write(to: targetURL, options: .atomic)
            return targetURL
        } catch {
            return nil
        }
    }

    // MARK: - 📄 Simple Formats: Markdown Note & Classic Notepad

    /// Formats note content and writes a rich .md Markdown file to the chosen destination folder
    @discardableResult
    public func saveMarkdownToDesktop(content: String, destinationFolder: URL? = nil) -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let targetFolder = destinationFolder ?? GenieStandardDirectories.notesURL
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        let firstLine = trimmed.components(separatedBy: .newlines).first ?? "QuickNote"
        let sanitizedTitle = sanitizeFilename(firstLine)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "Note - \(sanitizedTitle) - \(timestamp).md"
        let targetURL = targetFolder.appendingPathComponent(filename)

        let displayDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short)

        let mdContent = """
        ---
        title: "\(sanitizedTitle)"
        date: "\(displayDate)"
        generator: "Genie Desktop Notebook • macOS"
        format: "markdown"
        ---

        # \(sanitizedTitle)

        > *Captured on \(displayDate)*

        ---

        \(trimmed)

        ---
        *Created with Genie Desktop Notebook*
        """

        do {
            try mdContent.write(to: targetURL, atomically: true, encoding: .utf8)
            return targetURL
        } catch {
            print("saveMarkdownToDesktop error: \(error)")
            return nil
        }
    }

    private struct ThemeColors {
        let bgColors: [(r: CGFloat, g: CGFloat, b: CGFloat)]
        let textR: CGFloat
        let textG: CGFloat
        let textB: CGFloat
        let accentR: CGFloat
        let accentG: CGFloat
        let accentB: CGFloat
    }

    private func themeColorsFor(theme: String) -> ThemeColors {
        switch theme {
        case "Vintage Notepad":
            return ThemeColors(
                bgColors: [(0.98, 0.94, 0.78), (0.92, 0.86, 0.68)],
                textR: 0.18, textG: 0.14, textB: 0.08,
                accentR: 0.85, accentG: 0.55, accentB: 0.10
            )
        case "Genie Purple Glow":
            return ThemeColors(
                bgColors: [(0.16, 0.05, 0.30), (0.08, 0.02, 0.18)],
                textR: 0.96, textG: 0.90, textB: 1.0,
                accentR: 0.75, accentG: 0.35, accentB: 0.95
            )
        case "Cyber Matrix":
            return ThemeColors(
                bgColors: [(0.02, 0.07, 0.04), (0.00, 0.03, 0.01)],
                textR: 0.20, textG: 0.98, textB: 0.45,
                accentR: 0.0, accentG: 0.95, accentB: 0.40
            )
        case "California Sunset":
            return ThemeColors(
                bgColors: [(0.32, 0.10, 0.22), (0.18, 0.05, 0.26)],
                textR: 1.0, textG: 0.92, textB: 0.92,
                accentR: 0.95, accentG: 0.45, accentB: 0.55
            )
        case "Sakura Rose":
            return ThemeColors(
                bgColors: [(0.96, 0.85, 0.90), (0.90, 0.76, 0.84)],
                textR: 0.28, textG: 0.12, textB: 0.20,
                accentR: 0.90, accentG: 0.40, accentB: 0.65
            )
        default: // Apple Glass / Classic Film
            return ThemeColors(
                bgColors: [(0.10, 0.12, 0.18), (0.04, 0.05, 0.09)],
                textR: 0.95, textG: 0.95, textB: 0.98,
                accentR: 0.20, accentG: 0.60, accentB: 1.0
            )
        }
    }

    private func resolveNSFont(name: String, size: CGFloat) -> NSFont {
        switch name {
        case "SF Rounded", "SF Pro Rounded":
            if let desc = NSFont.systemFont(ofSize: size, weight: .medium).fontDescriptor.withDesign(.rounded) {
                return NSFont(descriptor: desc, size: size) ?? NSFont.systemFont(ofSize: size)
            }
            return NSFont.systemFont(ofSize: size)
        case "SF Mono":
            if let desc = NSFont.systemFont(ofSize: size, weight: .regular).fontDescriptor.withDesign(.monospaced) {
                return NSFont(descriptor: desc, size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            }
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case "New York", "New York Serif":
            if let desc = NSFont.systemFont(ofSize: size, weight: .regular).fontDescriptor.withDesign(.serif) {
                return NSFont(descriptor: desc, size: size) ?? NSFont.systemFont(ofSize: size)
            }
            return NSFont.systemFont(ofSize: size)
        case "American Typewriter":
            return NSFont(name: "American Typewriter", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Futura":
            return NSFont(name: "Futura", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Chalkboard", "Chalkboard SE":
            return NSFont(name: "Chalkboard SE", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Copperplate":
            return NSFont(name: "Copperplate", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Avenir Next":
            return NSFont(name: "Avenir Next", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Bradley Hand":
            return NSFont(name: "Bradley Hand", size: size) ?? NSFont.systemFont(ofSize: size)
        case "Papyrus":
            return NSFont(name: "Papyrus", size: size) ?? NSFont.systemFont(ofSize: size)
        default:
            return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
        }
    }

    public func openStickiesApp(content: String? = nil) {
        let trimmed = (content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Simply launch / activate macOS native Stickies.app
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Stickies") ?? URL(string: "file:///System/Applications/Stickies.app") {
                NSWorkspace.shared.open(url)
            } else {
                let script = "tell application \"Stickies\" to activate"
                if let appleScript = NSAppleScript(source: script) {
                    var errorInfo: NSDictionary?
                    appleScript.executeAndReturnError(&errorInfo)
                }
            }
            return
        }

        // Safe AppleScript command to make a new note in Stickies.app
        let escapedContent = trimmed
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let script = """
        tell application "Stickies"
            activate
        end tell
        tell application "System Events"
            tell process "Stickies"
                keystroke "n" using command down
                delay 0.1
                keystroke "\(escapedContent)"
            end tell
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
        }
    }

    // MARK: - 🌐 Interactive Web Page (.html)

    /// Formats note content and writes a standalone, responsive glassmorphic HTML page to destination folder or Genie Notes
    @discardableResult
    public func saveHTMLToDesktop(content: String, destinationFolder: URL? = nil, fontName: String = "SF Rounded", themeName: String = "Apple Glass") -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let targetFolder = destinationFolder ?? GenieStandardDirectories.notesURL
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        let firstLine = trimmed.components(separatedBy: .newlines).first ?? "QuickNote"
        let sanitizedTitle = sanitizeFilename(firstLine)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "Note - \(sanitizedTitle) - \(timestamp).html"
        let targetURL = targetFolder.appendingPathComponent(filename)

        let displayDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short)
        let escapedTitle = sanitizedTitle
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let paragraphs = trimmed.components(separatedBy: "\n\n")
            .map { p -> String in
                let escaped = p
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                    .replacingOccurrences(of: "\n", with: "<br/>")
                return "<p>\(escaped)</p>"
            }
            .joined(separator: "\n")

        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapedTitle) — Genie Desktop Note</title>
            <style>
                :root {
                    --bg-gradient: linear-gradient(135deg, #0b0f19 0%, #171e2e 50%, #1e1b4b 100%);
                    --card-bg: rgba(255, 255, 255, 0.05);
                    --card-border: rgba(255, 255, 255, 0.14);
                    --accent: #38bdf8;
                    --text-primary: #f8fafc;
                    --text-secondary: #94a3b8;
                }
                * { box-sizing: border-box; margin: 0; padding: 0; }
                body {
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 40px 20px;
                    background: var(--bg-gradient);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif;
                    color: var(--text-primary);
                    line-height: 1.65;
                }
                .card {
                    width: 100%;
                    max-width: 680px;
                    background: var(--card-bg);
                    backdrop-filter: blur(28px);
                    -webkit-backdrop-filter: blur(28px);
                    border: 1px solid var(--card-border);
                    border-radius: 24px;
                    padding: 42px;
                    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.45), 0 0 30px rgba(56, 189, 248, 0.15);
                }
                .badge {
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    padding: 5px 12px;
                    background: rgba(56, 189, 248, 0.14);
                    border: 1px solid rgba(56, 189, 248, 0.3);
                    border-radius: 999px;
                    font-size: 11.5px;
                    font-weight: 600;
                    color: var(--accent);
                    margin-bottom: 18px;
                }
                h1 {
                    font-size: 26px;
                    font-weight: 700;
                    letter-spacing: -0.4px;
                    margin-bottom: 8px;
                }
                .meta {
                    font-size: 13px;
                    color: var(--text-secondary);
                    margin-bottom: 24px;
                    padding-bottom: 14px;
                    border-bottom: 1px solid var(--card-border);
                }
                .content {
                    font-size: 15.5px;
                    color: #e2e8f0;
                    white-space: pre-wrap;
                }
                .content p { margin-bottom: 14px; }
                .footer {
                    margin-top: 28px;
                    padding-top: 14px;
                    border-top: 1px solid var(--card-border);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    font-size: 12px;
                    color: var(--text-secondary);
                }
                .copy-btn {
                    background: rgba(255, 255, 255, 0.10);
                    border: 1px solid var(--card-border);
                    color: var(--text-primary);
                    padding: 6px 14px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 12px;
                    font-weight: 500;
                    transition: all 0.2s ease;
                }
                .copy-btn:hover { background: rgba(255, 255, 255, 0.22); }
                @media print {
                    body { background: white; color: black; padding: 0; }
                    .card { box-shadow: none; border: 1px solid #ccc; background: white; color: black; }
                    .copy-btn { display: none; }
                }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="badge">🪔 GENIE DESKTOP MEMO</div>
                <h1>\(escapedTitle)</h1>
                <div class="meta">Captured on \(displayDate) • Typography: \(fontName) • Theme: \(themeName)</div>
                <div class="content">
                    \(paragraphs)
                </div>
                <div class="footer">
                    <span>Generated from Genie Desktop Notebook • macOS</span>
                    <button class="copy-btn" onclick="navigator.clipboard.writeText(document.querySelector('.content').innerText).then(() => { this.innerText = 'Copied! ✓'; setTimeout(() => this.innerText = 'Copy Note', 2000); })">Copy Note</button>
                </div>
            </div>
        </body>
        </html>
        """

        do {
            try html.write(to: targetURL, atomically: true, encoding: .utf8)
            return targetURL
        } catch {
            print("saveHTMLToDesktop error: \(error)")
            return nil
        }
    }

    // MARK: - 🧾 Typewriter Notepad Receipt (.txt)

    @discardableResult
    public func saveNotepadReceipt(content: String, destinationFolder: URL? = nil, template: NoteTemplateStyle = .classicDouble, theme: String = "Apple Glass") -> URL? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let targetFolder = destinationFolder ?? GenieStandardDirectories.notesURL
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        let firstLine = trimmed.components(separatedBy: .newlines).first ?? "Receipt"
        let sanitizedTitle = sanitizeFilename(firstLine)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "Receipt - \(sanitizedTitle) - \(timestamp).txt"
        let targetURL = targetFolder.appendingPathComponent(filename)

        let receiptText = buildNotepadFormat(content: trimmed, title: sanitizedTitle, template: template, theme: theme)

        do {
            try receiptText.write(to: targetURL, atomically: true, encoding: .utf8)
            return targetURL
        } catch {
            return nil
        }
    }

    // MARK: - 📦 Universal Format Dispatcher

    @discardableResult
    public func saveToDestination(
        destination: NoteOutputDestination,
        content: String,
        destinationFolder: URL? = nil,
        photoPath: String? = nil,
        photoImage: NSImage? = nil,
        fontName: String = "SF Rounded",
        themeName: String = "Apple Glass"
    ) -> [URL] {
        var results: [URL] = []
        switch destination {
        case .polaroidPng:
            if let u = savePolaroidToDesktop(content: content, destinationFolder: destinationFolder, photoPath: photoPath, photoImage: photoImage, fontName: fontName, themeName: themeName) {
                results.append(u)
            }
        case .glassCardPng:
            if let u = saveModernCardToDesktop(content: content, destinationFolder: destinationFolder, fontName: fontName, themeName: themeName) {
                results.append(u)
            }
        case .markdownMd:
            if let u = saveMarkdownToDesktop(content: content, destinationFolder: destinationFolder) {
                results.append(u)
            }
        case .webCardHtml:
            if let u = saveHTMLToDesktop(content: content, destinationFolder: destinationFolder, fontName: fontName, themeName: themeName) {
                results.append(u)
            }
        case .desktopTxt:
            if let u = saveNotepadReceipt(content: content, destinationFolder: destinationFolder, theme: themeName) {
                results.append(u)
            }
        case .stickyNote:
            saveToStickies(content: content, color: "Yellow")
        case .allFormats:
            if let u1 = savePolaroidToDesktop(content: content, destinationFolder: destinationFolder, photoPath: photoPath, photoImage: photoImage, fontName: fontName, themeName: themeName) { results.append(u1) }
            if let u2 = saveModernCardToDesktop(content: content, destinationFolder: destinationFolder, fontName: fontName, themeName: themeName) { results.append(u2) }
            if let u3 = saveMarkdownToDesktop(content: content, destinationFolder: destinationFolder) { results.append(u3) }
            if let u4 = saveHTMLToDesktop(content: content, destinationFolder: destinationFolder, fontName: fontName, themeName: themeName) { results.append(u4) }
            if let u5 = saveNotepadReceipt(content: content, destinationFolder: destinationFolder, theme: themeName) { results.append(u5) }
            saveToStickies(content: content, color: "Yellow")
        }
        return results
    }

    /// Formats note text into an authentic classic notepad / typewriter receipt format with user name and date
    public func buildNotepadFormat(content: String, title: String, template: NoteTemplateStyle = .classicDouble, theme: String = "Apple Glass") -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .full
        displayFormatter.timeStyle = .short
        let dateString = displayFormatter.string(from: Date())

        let userName: String = {
            let full = NSFullUserName()
            if !full.isEmpty { return full }
            let user = NSUserName()
            return user.isEmpty ? "macOS User" : user
        }()

        let width = 62

        switch template {
        case .starburst:
            let sep = "★" + String(repeating: "─", count: width - 2) + "★"
            let header = "│" + centerText("★ GENIE MEMOIR ★", width: width - 2) + "│"
            return """
            \(sep)
            \(header)
            \(sep)
            Date:   \(dateString)
            User:   \(userName)
            Topic:  \(title)
            \(String(repeating: "─", count: width))

            \(content)

            \(sep)
            Printed from Genie Desktop Notebook • macOS
            """

        case .decoOrnamental:
            let sep = "✦ • " + String(repeating: "─", count: width - 8) + " • ✦"
            let header = "│" + centerText("✧ GENIE EXECUTIVE FOLIO ✧", width: width - 2) + "│"
            return """
            \(sep)
            \(header)
            \(sep)
            Date:   \(dateString)
            User:   \(userName)
            Topic:  \(title)
            \(String(repeating: "─", count: width))

            \(content)

            \(sep)
            Printed from Genie Desktop Notebook • macOS
            """

        case .cyberTerminal:
            let bar = "[" + String(repeating: "▓", count: width - 2) + "]"
            let header = "|" + centerText(">>> GENIE CYBERLOG 0x7F <<<", width: width - 2) + "|"
            let sep = String(repeating: "=", count: width)
            return """
            \(bar)
            \(header)
            \(bar)
            [SYS_TIME] : \(dateString)
            [USER]     : \(userName)
            [TOPIC]    : \(title)
            \(sep)

            \(content)

            \(sep)
            [STATUS] OK • GENIE DESKTOP TERMINAL • macOS
            """

        default: // classicDouble
            let topBar = "╔" + String(repeating: "═", count: width - 2) + "╗"
            let bottomBar = "╚" + String(repeating: "═", count: width - 2) + "╝"
            let headerText = "GENIE DESKTOP NOTE"
            let paddedHeader = "║" + centerText(headerText, width: width - 2) + "║"
            let separator = String(repeating: "─", count: width)

            return """
            \(topBar)
            \(paddedHeader)
            \(bottomBar)
            Date:   \(dateString)
            User:   \(userName)
            Topic:  \(title)
            \(separator)

            \(content)

            \(separator)
            Printed from Genie Desktop Notebook • macOS
            """
        }
    }

    private func centerText(_ text: String, width: Int) -> String {
        let pad = max(0, (width - text.count) / 2)
        let rightPad = max(0, width - pad - text.count)
        return String(repeating: " ", count: pad) + text + String(repeating: " ", count: rightPad)
    }

    private func sanitizeFilename(_ text: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "\\/:*?\"<>|")
        var clean = text.components(separatedBy: invalidChars).joined()
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count > 28 {
            clean = String(clean.prefix(28)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return clean.isEmpty ? "QuickNote" : clean
    }
}

// MARK: - Mac Camera Capture Service for Instant Polaroid Photos
public final class CameraCaptureService: NSObject, @unchecked Sendable {
    public static let shared = CameraCaptureService()

    public func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    private func findBestCameraDevice() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .external,
                .continuityCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.first ?? AVCaptureDevice.default(for: .video)
    }

    public func captureCameraPhoto() async -> NSImage? {
        let granted = await requestCameraPermission()
        guard granted else { return nil }
        guard let device = findBestCameraDevice() else { return nil }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let session = AVCaptureSession()
                session.beginConfiguration()
                session.sessionPreset = .photo

                guard let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    session.commitConfiguration()
                    continuation.resume(returning: nil)
                    return
                }
                session.addInput(input)

                let photoOutput = AVCapturePhotoOutput()
                guard session.canAddOutput(photoOutput) else {
                    session.commitConfiguration()
                    continuation.resume(returning: nil)
                    return
                }
                session.addOutput(photoOutput)
                session.commitConfiguration()

                session.startRunning()

                // Allow exposure and white balance to calibrate
                Thread.sleep(forTimeInterval: 0.40)

                final class PhotoCaptureCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
                    var completion: ((NSImage?) -> Void)?
                    var retainedSelf: PhotoCaptureCoordinator?

                    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
                        let handler = completion
                        completion = nil
                        retainedSelf = nil

                        guard error == nil, let data = photo.fileDataRepresentation(), let img = NSImage(data: data) else {
                            handler?(nil)
                            return
                        }
                        handler?(img)
                    }
                }

                let coordinator = PhotoCaptureCoordinator()
                coordinator.retainedSelf = coordinator

                var hasResumed = false
                let resumeLock = NSLock()

                coordinator.completion = { img in
                    resumeLock.lock()
                    defer { resumeLock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        session.stopRunning()
                        continuation.resume(returning: img)
                    }
                }

                // Safety watchdog timeout (3.5s) in case camera hardware freezes
                DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                    resumeLock.lock()
                    defer { resumeLock.unlock() }
                    if !hasResumed {
                        hasResumed = true
                        session.stopRunning()
                        coordinator.retainedSelf = nil
                        continuation.resume(returning: nil)
                    }
                }

                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: coordinator)
            }
        }
    }

    public func captureScreenFallback() async -> NSImage? {
        return await MainActor.run {
            guard let mainScreen = NSScreen.main else { return nil }
            let rect = mainScreen.frame
            if let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) {
                return NSImage(cgImage: cgImage, size: rect.size)
            }
            return nil
        }
    }
}

