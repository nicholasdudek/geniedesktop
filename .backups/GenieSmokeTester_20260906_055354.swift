import AppKit
import AVFoundation
import CoreGraphics
import CoreText
import Foundation
import Vision

// MARK: - 🧪 Genie Automated Smoke Test Suite
public struct GenieSmokeTester {

    @MainActor
    public static func runAllTests() async {
        print("\n\u{001B}[1;36m════════════════════════════════════════════════════════════════════\u{001B}[0m")
        print("\u{001B}[1;36m🧪 GOLDGATE GENIE AUTOMATED SMOKE TEST SUITE (2026)\u{001B}[0m")
        print("\u{001B}[1;36m════════════════════════════════════════════════════════════════════\u{001B}[0m")

        var passed = 0
        var failed = 0

        func recordResult(name: String, success: Bool, detail: String = "") {
            if success {
                passed += 1
                print("  \u{001B}[1;32m[PASS]\u{001B}[0m \(name)" + (detail.isEmpty ? "" : " (\(detail))"))
            } else {
                failed += 1
                print("  \u{001B}[1;31m[FAIL]\u{001B}[0m \(name)" + (detail.isEmpty ? "" : " (\(detail))"))
            }
        }

        // Test 1: BarMode Navigation and Attributes
        do {
            let allModes = BarMode.allCases
            var cycleMatches = true
            for mode in allModes {
                if mode.icon.isEmpty || mode.title.isEmpty || mode.placeholder.isEmpty {
                    cycleMatches = false
                }
            }
            let validCycle = (BarMode.chat.next() == .search) &&
                             (BarMode.search.next() == .apps) &&
                             (BarMode.apps.next() == .file) &&
                             (BarMode.file.next() == .terminal) &&
                             (BarMode.terminal.next() == .polaroid) &&
                             (BarMode.polaroid.next() == .screenMirror) &&
                             (BarMode.screenMirror.next() == .vision) &&
                             (BarMode.vision.next() == .settings) &&
                             (BarMode.settings.next() == .chat)

            recordResult(
                name: "BarMode 9-Way Cyclic Navigation & Metadata",
                success: allModes.count == 9 && cycleMatches && validCycle,
                detail: "9 modes, full circular transition validated including settings"
            )
        }

        // Test 2: LocalModelManager Parsing and Tool Extraction
        do {
            let lmm = LocalModelManager.shared
            let noteMock = "Let me save that for you:\n```note\nKey deliverables for Q3: Complete refactoring\n```\nHope this helps!"
            let extractedNote = lmm.extractNoteCommand(from: noteMock)

            let appMock = "Launching browser:\n```app\nSafari\n```\nEnjoy!"
            let extractedApp = lmm.extractAppCommand(from: appMock)

            let stationMock = "Moving to desk:\n```switch_station\nchat\n```\ndone!"
            let extractedStation = lmm.extractSwitchStationCommand(from: stationMock)

            let toolsSuccess = (extractedNote?.format == "markdown" && extractedNote?.content.contains("Complete refactoring") == true) &&
                               (extractedApp == "Safari") &&
                               (extractedStation == "chat")

            recordResult(
                name: "LocalModelManager Tool & Command Parsing",
                success: toolsSuccess,
                detail: "Extracted [note], [app], [switch_station] code blocks"
            )
        }

        // Test 3: Hardware-Accelerated Apple Vision OCR on Synthetic Frame
        do {
            let width = 500
            let height = 120
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let ctx = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

                let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 38, nil)
                let attr: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.black
                ]
                let str = NSAttributedString(string: "GENIE VISION TEST 2026", attributes: attr)
                let line = CTLineCreateWithAttributedString(str)
                ctx.textPosition = CGPoint(x: 20, y: 40)
                CTLineDraw(line, ctx)

                if let testCgImage = ctx.makeImage() {
                    let testNsImage = NSImage(cgImage: testCgImage, size: NSSize(width: width, height: height))
                    let (recognized, lines, boxes) = await GenieVisionEngine.shared.performOCR(on: testNsImage)
                    let success = recognized.localizedCaseInsensitiveContains("GENIE") ||
                                  recognized.localizedCaseInsensitiveContains("VISION")
                    recordResult(
                        name: "Hardware-Accelerated Apple Vision OCR Pipeline",
                        success: success,
                        detail: "Recognized \(lines.count) lines, \(boxes.count) bounding boxes"
                    )
                } else {
                    recordResult(name: "Hardware-Accelerated Apple Vision OCR Pipeline", success: false, detail: "Failed to generate CGImage")
                }
            } else {
                recordResult(name: "Hardware-Accelerated Apple Vision OCR Pipeline", success: false, detail: "Failed to create CGContext")
            }
        }

        // Test 4: GenieVoiceEngine State & Speech Synthesis Engine
        do {
            let voiceEngine = GenieVoiceEngine.shared
            let voices = AVSpeechSynthesisVoice.speechVoices()
            let voiceSuccess = !voices.isEmpty && !voiceEngine.isSpeaking
            recordResult(
                name: "GenieVoiceEngine Initialization & Voices Discovery",
                success: voiceSuccess,
                detail: "Found \(voices.count) available system voices"
            )
        }

        // Test 5: iPhoneMirrorManager Configuration & Sendable Integrity
        do {
            let mirror = iPhoneMirrorManager.shared
            let mirrorSuccess = (iPhoneMirrorManager.bundleID == "com.apple.ScreenContinuity") &&
                                (iPhoneMirrorManager.appName == "iPhone Mirroring") &&
                                !mirror.isStreaming
            recordResult(
                name: "iPhoneMirrorManager Continuity Configuration",
                success: mirrorSuccess,
                detail: "BundleID: \(iPhoneMirrorManager.bundleID), AppName: \(iPhoneMirrorManager.appName)"
            )
        }

        // Test 6: Desktop Standard Directories Hierarchy
        do {
            let notes = GenieStandardDirectories.notesURL
            let docs = GenieStandardDirectories.documentsURL
            let polaroids = GenieStandardDirectories.polaroidsURL
            let presentations = GenieStandardDirectories.presentationsURL
            let fm = FileManager.default
            let fsSuccess = fm.fileExists(atPath: notes.path) &&
                            fm.fileExists(atPath: docs.path) &&
                            fm.fileExists(atPath: polaroids.path) &&
                            fm.fileExists(atPath: presentations.path)
            recordResult(
                name: "GenieStandardDirectories Workspace Storage Hierarchy",
                success: fsSuccess,
                detail: "Notes, Docs, Polaroids, Presentations verified on disk"
            )
        }

        // Test 7: DesktopNotePrinter Markdown Generator
        do {
            let printer = DesktopNotePrinter.shared
            let testContent = "# Smoke Test Document\nGenerated during automated verification."
            let savedURL = printer.saveMarkdownToDesktop(content: testContent)
            let success = savedURL != nil && FileManager.default.fileExists(atPath: savedURL!.path)
            if let url = savedURL {
                try? FileManager.default.removeItem(at: url)
            }
            recordResult(
                name: "DesktopNotePrinter Markdown Generation & IO",
                success: success,
                detail: "Rendered and saved markdown note cleanly"
            )
        }

        // Test 8: Type-To-Activate System ("if nothing is activated you can just start typing")
        do {
            let isFieldActive = DesktopWindowManager.isTextInputFieldActive()
            var notificationReceived = false
            let observer = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NexusSearchBarAppendText"),
                object: nil,
                queue: .main
            ) { notif in
                if (notif.object as? String) == "G" {
                    notificationReceived = true
                }
            }

            DesktopWindowManager.shared.startTypingWithInitialCharacter("G")
            NotificationCenter.default.removeObserver(observer)

            let success = !isFieldActive && notificationReceived && (DesktopWindowManager.shared.currentPage == 1)
            recordResult(
                name: "Type-To-Activate System (Desktop Auto-Summon on Typing)",
                success: success,
                detail: "Field inactive, broadcast character G, elevated to page 1"
            )
        }

        // Test 9: Antigravity Desktop Control (OS-level Agent Automation)
        do {
            let sampleResponse = """
I will automate the workflow on your desktop:
```desktop_agent
open "Safari"
wait 1.5
click_text "Search"
type "https://apple.com"
key return
scroll down
record 5
snapshot
```
Let me know if you need anything else!
"""
            let agent = AntigravityDesktopAgent.shared
            let extractedScript = LocalModelManager.shared.extractDesktopAgentCommand(from: sampleResponse)
            let actions = extractedScript != nil ? agent.parseScript(from: extractedScript!) : []

            let countMatches = (actions.count == 8)
            let firstIsOpen = actions.first == .openApp(name: "Safari")
            let hasClickText = actions.contains(where: { if case .clickText(let t) = $0 { return t == "Search" }; return false })
            let hasType = actions.contains(where: { if case .type(let t) = $0 { return t == "https://apple.com" }; return false })
            let hasKey = actions.contains(where: { if case .key(let n, _) = $0 { return n == "return" }; return false })
            let hasRecord = actions.contains(where: { if case .record(let s) = $0 { return s == 5.0 }; return false })

            // Test Stop Execution safety valve
            agent.stopExecution()
            let stopSuccess = agent.isCancelled && !agent.isExecuting

            let success = countMatches && firstIsOpen && hasClickText && hasType && hasKey && hasRecord && stopSuccess
            recordResult(
                name: "Antigravity Desktop Agent & Autonomous HUD Control",
                success: success,
                detail: "8 actions parsed (open, wait, clickText, type, key, scroll, record, snapshot) & stop control verified"
            )
        }

        print("\u{001B}[1;36m────────────────────────────────────────────────────────────────────\u{001B}[0m")
        if failed == 0 {
            print("\u{001B}[1;32m🎉 ALL \(passed) SMOKE TESTS PASSED CLEANLY (0 ERRORS, 0 REGRESSIONS)\u{001B}[0m")
            print("\u{001B}[1;36m════════════════════════════════════════════════════════════════════\u{001B}[0m\n")
            exit(0)
        } else {
            print("\u{001B}[1;31m❌ \(failed) TEST(S) FAILED OUT OF \(passed + failed) TOTAL\u{001B}[0m")
            print("\u{001B}[1;36m════════════════════════════════════════════════════════════════════\u{001B}[0m\n")
            exit(1)
        }
    }
}
