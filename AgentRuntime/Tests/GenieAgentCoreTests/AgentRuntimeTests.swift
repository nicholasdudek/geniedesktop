import XCTest
@testable import GenieAgentCore

private actor ScriptedModel: AgentModel {
    var replies: [AgentReply]
    var received: [[AgentMessage]] = []
    init(_ messages: [AgentMessage]) { replies = messages.map { AgentReply(message: $0, tokens: 10) } }
    func reply(to messages: [AgentMessage]) async throws -> AgentReply {
        received.append(messages)
        guard !replies.isEmpty else { throw AgentFailure("Unexpected model request.") }
        return replies.removeFirst()
    }
}

final class AgentRuntimeTests: XCTestCase {
    var folder: URL!
    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: folder) }
    func call(_ name: String, _ args: [String: String]) throws -> AgentToolCall {
        AgentToolCall(name: name, arguments: String(decoding: try JSONEncoder().encode(args), as: UTF8.self))
    }

    func testRejectsTraversalAndSymlinkEscape() async throws {
        let tools = AgentTools(workspace: folder)
        try FileManager.default.createSymbolicLink(at: folder.appendingPathComponent("outside"), withDestinationURL: folder.deletingLastPathComponent())
        for path in ["../secret", "/etc/passwd", "outside/secret", ".git/config"] {
            do { _ = try await tools.resolve(path); XCTFail("Allowed \(path)") } catch {}
        }
        let resolved = try await tools.resolve("inside.txt")
        XCTAssertTrue(resolved.path.hasSuffix("inside.txt"))
    }

    func testEditRequiresApprovalAndExactMatch() async throws {
        let tools = AgentTools(workspace: folder)
        let create = try call("edit_file", ["path": "sample.txt", "old_text": "", "new_text": "old value"])
        do { _ = try await tools.execute(create); XCTFail("Unapproved edit executed") } catch {}
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("sample.txt").path))
        _ = try await tools.execute(create, approved: true)
        do { _ = try await tools.execute(create, approved: true); XCTFail("Overwrote existing file") } catch {}
        let edit = try call("edit_file", ["path": "sample.txt", "old_text": "old", "new_text": "new"])
        _ = try await tools.execute(edit, approved: true)
        XCTAssertEqual(try String(contentsOf: folder.appendingPathComponent("sample.txt"), encoding: .utf8), "new value")
    }

    func testCommandExitOutputTimeoutAndCancellation() async throws {
        let result = try await AgentCommandRunner.run("echo evidence; exit 7", directory: folder)
        XCTAssertEqual(result.exitCode, 7)
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.output.contains("evidence"))
        let timeout = try await AgentCommandRunner.run("sleep 10", directory: folder, timeout: 0.1)
        XCTAssertEqual(timeout.exitCode, 124)
        let task = Task { try await AgentCommandRunner.run("sleep 10", directory: folder) }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancellation ignored") } catch is CancellationError {} catch { XCTFail("\(error)") }
    }

    func testFullLoopEditsVerifiesAndPersists() async throws {
        let edit = try call("edit_file", ["path": "answer.txt", "old_text": "", "new_text": "42"])
        let verify = try call("run_command", ["command": "test \"$(cat answer.txt)\" = 42"])
        let model = ScriptedModel([
            AgentMessage(role: "assistant", content: "Creating the answer.", calls: [edit]),
            AgentMessage(role: "assistant", content: "Checking the file.", calls: [verify]),
            AgentMessage(role: "assistant", content: "Created answer.txt and verified its contents.")
        ])
        let store = AgentRunStore(directory: folder.appendingPathComponent("history"))
        let run = await AgentRuntime().execute(AgentRun(objective: "Write 42", workspace: folder.path, model: "fixture"), model: model, store: store, approve: { _ in true }, observe: { _ in })
        XCTAssertEqual(run.status, "Finished")
        XCTAssertEqual(run.turns, 3)
        XCTAssertTrue(run.lastVerified)
        XCTAssertEqual(try store.runs().first?.id, run.id)
        let received = await model.received
        XCTAssertEqual(received[2].filter { $0.role == "tool" }.count, 2)
    }

    func testDeniedCommandDoesNotExecute() async throws {
        let command = try call("run_command", ["command": "touch forbidden"])
        let model = ScriptedModel([AgentMessage(role: "assistant", content: "", calls: [command]), AgentMessage(role: "assistant", content: "Action denied.")])
        let run = await AgentRuntime().execute(AgentRun(objective: "Example", workspace: folder.path, model: "fixture"), model: model, store: AgentRunStore(directory: folder.appendingPathComponent("history")), approve: { _ in false }, observe: { _ in })
        XCTAssertEqual(run.status, "Finished")
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("forbidden").path))
        XCTAssertTrue(run.messages.contains { $0.content.contains("User denied") })
    }

    func testResumeReconcilesPendingCallWithoutReplaying() async throws {
        let command = try call("run_command", ["command": "touch replayed"])
        var previous = AgentRun(objective: "Example", workspace: folder.path, model: "fixture")
        previous.messages = [AgentMessage(role: "user", content: "Example"), AgentMessage(role: "assistant", content: "", calls: [command])]
        previous.pendingCall = command
        let model = ScriptedModel([AgentMessage(role: "assistant", content: "Needs inspection.")])
        _ = await AgentRuntime().execute(previous, model: model, store: AgentRunStore(directory: folder.appendingPathComponent("history")), approve: { _ in XCTFail("Replayed pending action"); return true }, observe: { _ in })
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("replayed").path))
        let messages = await model.received.first!
        XCTAssertTrue(messages.contains { $0.callID == command.id && $0.content.contains("outcome unknown") })
    }

    func testTruncatedModelResponseNeverExecutes() throws {
        let data = Data(#"{"choices":[{"finish_reason":"length","message":{"content":"partial"}}]}"#.utf8)
        XCTAssertThrowsError(try AgentHTTPModel.decode(data))
    }

    func testTokenLimitStopsBeforeNextModelCall() async throws {
        var previous = AgentRun(objective: "Example", workspace: folder.path, model: "fixture")
        previous.tokens = 100
        let run = await AgentRuntime().execute(previous, model: ScriptedModel([]), store: AgentRunStore(directory: folder.appendingPathComponent("history")), tokenBudget: 100, approve: { _ in false }, observe: { _ in })
        XCTAssertEqual(run.status, "Failed")
        XCTAssertEqual(run.turns, 0)
    }

    func testAutonomousModeBypassesApprovalGate() async throws {
        let edit = try call("edit_file", ["path": "auto.txt", "old_text": "", "new_text": "autonomous content"])
        let command = try call("run_command", ["command": "echo autonomous > verified.txt"])
        let model = ScriptedModel([
            AgentMessage(role: "assistant", content: "Editing and executing autonomously.", calls: [edit, command]),
            AgentMessage(role: "assistant", content: "Finished autonomous actions.")
        ])
        let store = AgentRunStore(directory: folder.appendingPathComponent("history"))
        // Pass approve closure that fails if invoked:
        let run = await AgentRuntime().execute(
            AgentRun(objective: "Auto test", workspace: folder.path, model: "fixture"),
            model: model,
            store: store,
            bypassApproval: true,
            approve: { _ in
                XCTFail("Approval callback was called in autonomous mode")
                return false
            },
            observe: { _ in }
        )
        XCTAssertEqual(run.status, "Finished")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("auto.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("verified.txt").path))
    }
}
