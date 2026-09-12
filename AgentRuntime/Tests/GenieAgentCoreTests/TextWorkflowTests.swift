import XCTest
@testable import GenieAgentCore

final class TextWorkflowTests: XCTestCase {
    private func call(_ name: String, _ args: [String: String]) throws -> AgentToolCall {
        AgentToolCall(name: name, arguments: String(decoding: try JSONEncoder().encode(args), as: UTF8.self))
    }

    func testUnicodeSelectionAndExactComparison() throws {
        let value = "Hello 👩🏽‍💻\n世界\tend"
        let range = (value as NSString).range(of: "世界")
        XCTAssertEqual(try AgentTextTransfer.replacingSelection(in: value, range: CFRange(location: range.location, length: range.length), with: "café\n\t🙂"), "Hello 👩🏽‍💻\ncafé\n\t🙂\tend")
        XCTAssertFalse(AgentTextTransfer.identical("é", "e\u{301}"))
        XCTAssertThrowsError(try AgentTextTransfer.replacingSelection(in: "🙂", range: CFRange(location: 1, length: 0), with: "bad"))
        XCTAssertThrowsError(try AgentTextTransfer.replacingSelection(in: "a", range: CFRange(location: 0, length: Int.max), with: "bad"))
    }

    func testWriteReadAndStaleContentProtection() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let tools = AgentTools(workspace: directory)
        let content = "  café\t🙂\r\nsecond line\n"
        let create = try call("write_file", ["path": "nested/note.txt", "expected_content": "__NEW_FILE__", "content": content])
        do { _ = try await tools.execute(create); XCTFail("Write without approval") } catch {}
        _ = try await tools.execute(create, approved: true)
        let read = try await tools.execute(call("read_file", ["path": "nested/note.txt"]))
        XCTAssertTrue(AgentTextTransfer.identical(read.output, content))
        do { _ = try await tools.execute(create, approved: true); XCTFail("Overwrote existing file") } catch {}
        let stale = try call("write_file", ["path": "nested/note.txt", "expected_content": "outdated", "content": "lost data"])
        do { _ = try await tools.execute(stale, approved: true); XCTFail("Stale write accepted") } catch {}
        let edit = try call("write_file", ["path": "nested/note.txt", "expected_content": content, "content": content + "new\n"])
        _ = try await tools.execute(edit, approved: true)
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("nested/note.txt")), Data((content + "new\n").utf8))
    }

    func testMergeIndependentChangesAndReportConflict() async throws {
        let base = "one\ntwo\nthree\nfour\nfive\n"
        let merged = try await AgentFileMerge.preview(current: "ONE\ntwo\nthree\nfour\nfive\n", base: base, incoming: "one\ntwo\nthree\nfour\nFIVE\n")
        XCTAssertTrue(merged.success)
        let payload = try JSONSerialization.jsonObject(with: Data(merged.output.utf8)) as! [String: Any]
        XCTAssertEqual(payload["content"] as? String, "ONE\ntwo\nthree\nfour\nFIVE\n")
        XCTAssertEqual(payload["files_changed"] as? Bool, false)
        let conflict = try await AgentFileMerge.preview(current: "ours\n", base: "original\n", incoming: "theirs\n")
        XCTAssertFalse(conflict.success)
        let conflicting = try JSONSerialization.jsonObject(with: Data(conflict.output.utf8)) as! [String: Any]
        XCTAssertEqual(conflicting["conflicts"] as? Bool, true)
        XCTAssertTrue((conflicting["content"] as! String).contains("<<<<<<<"))
    }

    func testNewToolsValidateAndRequireApproval() async throws {
        let tools = AgentTools(workspace: FileManager.default.temporaryDirectory)
        for name in ["copy_text", "paste_text", "write_file"] {
            XCTAssertTrue(AgentToolCatalog.mutatingNames.contains(name))
        }
        for (name, args) in [("copy_text", ["element_id": "invented", "scope": "value"]),
                             ("paste_text", ["element_id": "invented", "expected_value": "", "text": "hello"])] {
            do { _ = try await tools.execute(call(name, args)); XCTFail("Unapproved clipboard mutation") }
            catch { XCTAssertTrue(error.localizedDescription.contains("approval")) }
        }
        do {
            _ = try await tools.arguments(for: call("merge_files", ["path": "a", "base_path": "../outside", "incoming_path": "b"]))
            XCTFail("Merge path escaped workspace")
        } catch {}
    }

    func testSovereignMeshValidationAndStatus() async throws {
        let tools = AgentTools(workspace: FileManager.default.temporaryDirectory)
        XCTAssertTrue(AgentToolCatalog.names.contains("agent_network"))
        XCTAssertTrue(AgentToolCatalog.mutatingNames.contains("agent_network"))

        let statusCall = try call("agent_network", ["action": "status"])
        let args = try await tools.arguments(for: statusCall)
        XCTAssertEqual(args["action"], "status")

        let result = try await tools.execute(statusCall, approved: true)
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("Sovereign Mesh Status"))
    }
}
