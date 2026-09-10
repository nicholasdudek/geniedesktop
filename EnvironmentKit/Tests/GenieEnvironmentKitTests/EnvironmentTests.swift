import XCTest
@testable import GenieEnvironmentKit

actor RecordingTransport: EnvironmentTransport {
    var requests: [JSONValue] = []
    func request(vmID: UUID, payload: JSONValue) async throws -> JSONValue {
        requests.append(payload)
        if payload["op"]?.string == "register" { return payload["spec"]! }
        return .object(["id": .string("job-1"), "state": .string("succeeded"), "result": .string("done")])
    }
    func count() -> Int { requests.count }
}

final class EnvironmentTests: XCTestCase {
    func testReopenAndResultAfterManagerRecreation() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let transport = RecordingTransport()
        let manager = try EnvironmentManager(directory: root, transport: transport)
        let spec = try await manager.create(EnvironmentSpec(name: "test", vmID: UUID()))
        let submitted = try await manager.submit(environment: spec.id, tool: "browser.inspect", input: .object([:]), idempotencyKey: "same-job")
        let reopened = try EnvironmentManager(directory: root, transport: transport)
        let loaded = try await reopened.open(spec.id)
        XCTAssertEqual(loaded, spec)
        let result = try await reopened.result(environment: spec.id, jobID: submitted["id"]!.string!)
        XCTAssertEqual(result["state"]?.string, "succeeded")
    }
    func testDisabledToolDoesNotReachTransport() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let transport = RecordingTransport()
        let manager = try EnvironmentManager(directory: root, transport: transport)
        let spec = try await manager.create(EnvironmentSpec(name: "browser", vmID: UUID(), tools: ["browser"]))
        do {
            _ = try await manager.submit(environment: spec.id, tool: "shell.run", input: .object([:]))
            XCTFail("Disabled tool accepted")
        } catch { XCTAssertTrue(error.localizedDescription.contains("not enabled")) }
        let count = await transport.count()
        XCTAssertEqual(count, 1)
    }
    func testJSONRoundTripPreservesBooleansAndNull() throws {
        let original = JSONValue.object(["flag": .bool(true), "count": .number(4), "missing": .null, "list": .array([.string("x")])])
        XCTAssertEqual(try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original)), original)
    }
    func testUTMErrorsOnStderrAreNotSuccessfulEvenWithZeroExit() async throws {
        let backend = UTMBackend(executable: URL(fileURLWithPath: "/bin/sh"))
        do {
            _ = try await backend.run(["-c", "echo 'Error from event: guest agent unavailable' >&2; exit 0"])
            XCTFail("Should reject UTM's zero-exit Apple Event error")
        } catch { XCTAssertTrue(error.localizedDescription.contains("guest agent unavailable")) }
    }
    func testHostTimeoutIsBounded() async throws {
        let start = Date()
        let backend = UTMBackend(executable: URL(fileURLWithPath: "/bin/sleep"))
        do {
            _ = try await backend.run(["10"], timeout: 0.1)
            XCTFail("Expected timeout")
        } catch { XCTAssertLessThan(Date().timeIntervalSince(start), 3) }
    }
}
