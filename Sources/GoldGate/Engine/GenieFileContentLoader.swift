import AppKit
import Foundation
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import Vision

// MARK: - 🗂️ Genie Intelligent File Content Loader
/// Reads, inspects, and converts local files (code, documents, PDFs, images) into
/// structured context for the AI model, performing OCR on images and text extraction on PDFs.
public final class GenieFileContentLoader {
    public static let shared = GenieFileContentLoader()

    public enum FileCategory {
        case code(language: String)
        case markdown
        case plainText
        case json
        case pdf
        case image
        case audio
        case binary
    }

    private init() {}

    // MARK: - File Category & Icon Detection
    public func detectCategory(for url: URL) -> FileCategory {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "swift":
            return .code(language: "swift")
        case "py", "python":
            return .code(language: "python")
        case "js", "jsx", "mjs":
            return .code(language: "javascript")
        case "ts", "tsx":
            return .code(language: "typescript")
        case "html", "htm":
            return .code(language: "html")
        case "css", "scss", "sass", "less":
            return .code(language: "css")
        case "json":
            return .json
        case "md", "markdown":
            return .markdown
        case "sh", "bash", "zsh", "fish":
            return .code(language: "bash")
        case "rs":
            return .code(language: "rust")
        case "go":
            return .code(language: "go")
        case "c", "h":
            return .code(language: "c")
        case "cpp", "hpp", "cc", "cxx":
            return .code(language: "cpp")
        case "m", "mm":
            return .code(language: "objectivec")
        case "rb":
            return .code(language: "ruby")
        case "java", "kt", "kts":
            return .code(language: "java")
        case "yaml", "yml", "toml", "xml", "plist", "env":
            return .code(language: ext)
        case "sql":
            return .code(language: "sql")
        case "txt", "log", "diff", "patch":
            return .plainText
        case "pdf":
            return .pdf
        case "png", "jpg", "jpeg", "webp", "heic", "gif", "tiff", "bmp", "svg":
            return .image
        case "mp3", "m4a", "wav", "aac", "ogg", "flac":
            return .audio
        default:
            if let uti = UTType(filenameExtension: ext) {
                if uti.conforms(to: .sourceCode) {
                    return .code(language: ext)
                } else if uti.conforms(to: .text) {
                    return .plainText
                } else if uti.conforms(to: .image) {
                    return .image
                } else if uti.conforms(to: .pdf) {
                    return .pdf
                } else if uti.conforms(to: .audio) {
                    return .audio
                }
            }
            return .binary
        }
    }

    public func chipIconInfo(for url: URL) -> (icon: String, color: Color) {
        let category = detectCategory(for: url)
        switch category {
        case .code(let lang):
            if lang == "swift" {
                return ("swift", .orange)
            } else if lang == "python" {
                return ("chevron.left.forwardslash.chevron.right", Color(red: 0.25, green: 0.70, blue: 1.0))
            } else if lang == "bash" {
                return ("terminal.fill", .green)
            } else {
                return ("chevron.left.forwardslash.chevron.right", .cyan)
            }
        case .markdown:
            return ("doc.richtext.fill", .purple)
        case .plainText:
            return ("doc.text.fill", .white.opacity(0.85))
        case .json:
            return ("curlybraces", .yellow)
        case .pdf:
            return ("doc.fill", Color(red: 0.95, green: 0.25, blue: 0.25))
        case .image:
            return ("photo.fill", .cyan)
        case .audio:
            return ("waveform", .pink)
        case .binary:
            return ("doc.zipper", .gray)
        }
    }

    public func formattedFileSize(for url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    // MARK: - Smart Content Loading & Extraction
    public func loadFileContent(url: URL) async -> String {
        let filename = url.lastPathComponent
        let sizeStr = formattedFileSize(for: url)
        let category = detectCategory(for: url)

        switch category {
        case .code(let lang):
            return loadTextContent(url: url, filename: filename, sizeStr: sizeStr, lang: lang)

        case .json:
            return loadTextContent(url: url, filename: filename, sizeStr: sizeStr, lang: "json")

        case .markdown, .plainText:
            return loadTextContent(url: url, filename: filename, sizeStr: sizeStr, lang: "markdown")

        case .pdf:
            return loadPDFContent(url: url, filename: filename, sizeStr: sizeStr)

        case .image:
            return await loadImageContent(url: url, filename: filename, sizeStr: sizeStr)

        case .audio:
            return "[Attached Audio File: `\(filename)` (\(sizeStr)) at path: `\(url.path)`]"

        case .binary:
            return "[Attached Binary File: `\(filename)` (\(sizeStr)) at path: `\(url.path)`]"
        }
    }

    private func loadTextContent(url: URL, filename: String, sizeStr: String, lang: String) -> String {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return "[Attached File: `\(filename)` (\(sizeStr)) - could not read UTF-8 content]"
        }

        let lines = text.components(separatedBy: "\n")
        let maxLines = 500
        let truncated = lines.count > maxLines
        let contentToUse = truncated ? lines.prefix(maxLines).joined(separator: "\n") : text

        var output = "### 📄 File: `\(filename)` (\(lines.count) lines, \(sizeStr))\n"
        output += "```\(lang)\n"
        output += contentToUse
        if truncated {
            output += "\n\n// ... [truncated remaining \(lines.count - maxLines) lines for context efficiency] ..."
        }
        output += "\n```\n"
        return output
    }

    private func loadPDFContent(url: URL, filename: String, sizeStr: String) -> String {
        guard let document = PDFDocument(url: url) else {
            return "[Attached PDF Document: `\(filename)` (\(sizeStr)) - could not read PDF content]"
        }

        let pageCount = document.pageCount
        var extractedPages: [String] = []
        let maxPages = min(pageCount, 12)

        for i in 0..<maxPages {
            if let page = document.page(at: i), let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), !pageText.isEmpty {
                extractedPages.append("[Page \(i + 1)]:\n\(pageText)")
            }
        }

        var output = "### 📑 PDF Document: `\(filename)` (\(pageCount) pages, \(sizeStr))\n"
        if extractedPages.isEmpty {
            output += "(No machine-readable text found in PDF pages)\n"
        } else {
            output += extractedPages.joined(separator: "\n\n")
            if pageCount > maxPages {
                output += "\n\n// ... [truncated remaining \(pageCount - maxPages) pages] ..."
            }
        }
        output += "\n"
        return output
    }

    private func loadImageContent(url: URL, filename: String, sizeStr: String) async -> String {
        guard let nsImage = NSImage(contentsOf: url),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return "[Attached Image: `\(filename)` (\(sizeStr)) at path: `\(url.path)`]"
        }

        let width = cgImage.width
        let height = cgImage.height
        var output = "### 🖼️ Image: `\(filename)` (\(width)x\(height)px, \(sizeStr))\n"

        // Perform instant on-device Vision OCR
        let ocrBlocks = await GenieVisionOCREngine.shared.recognizeText(in: cgImage)
        if !ocrBlocks.isEmpty {
            let extractedText = ocrBlocks.map { $0.text }.joined(separator: "\n")
            output += "**[On-Device Vision OCR Text Extracted from Image]:**\n"
            output += "```text\n\(extractedText)\n```\n"
        } else {
            output += "(No readable text detected in image)\n"
        }
        output += "Image file path: `\(url.path)`\n"
        return output
    }

    // MARK: - Package Prompt with Full Context
    public func preparePromptWithAttachments(prompt: String, files: [URL]) async -> String {
        let clean = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !files.isEmpty else { return clean }

        var sections: [String] = []
        for file in files {
            let content = await loadFileContent(url: file)
            sections.append(content)
        }

        let attachmentsBlock = sections.joined(separator: "\n---\n")

        if clean.isEmpty {
            return "Please analyze and explain the following attached file(s):\n\n\(attachmentsBlock)"
        } else {
            return "\(clean)\n\n---\n## 📎 Attached Context & Files:\n\(attachmentsBlock)"
        }
    }
}
