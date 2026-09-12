import Foundation
import GenieEnvironmentKit

@main
struct CLI {
    static func main() async {
        do { try await execute() }
        catch { FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8)); exit(1) }
    }
    /// utmctl cannot carry responses, so a piped transport is selected by
    /// environment: SSH for a UTM or remote VM, orbctl for an OrbStack machine.
    static func transport() -> any EnvironmentTransport {
        let env = ProcessInfo.processInfo.environment
        if let host = env["GENIE_ENV_SSH_HOST"] {
            let key = env["GENIE_ENV_SSH_KEY"] ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh/genie_env_ed25519").path
            return PipeBackend.ssh(host: host, user: env["GENIE_ENV_SSH_USER"] ?? NSUserName(), identity: URL(fileURLWithPath: key))
        }
        if let machine = env["GENIE_ENV_ORB_MACHINE"] { return PipeBackend.orbStack(machine: machine) }
        return UTMBackend()
    }

    static func execute() async throws {
        let args = Array(CommandLine.arguments.dropFirst())
        let backend = UTMBackend()
        let transport = Self.transport()
        let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Genie/Environments")
        let manager = try EnvironmentManager(directory: directory, transport: transport)
        func argument(_ index: Int) throws -> String {
            guard args.indices.contains(index) else { throw EnvironmentError("Missing argument. Run genie-env help.") }
            return args[index]
        }
        func uuid(_ index: Int) throws -> UUID {
            guard let value = UUID(uuidString: try argument(index)) else { throw EnvironmentError("Expected UUID.") }
            return value
        }
        switch args.first ?? "help" {
        case "list": print(try await backend.list())
        case "start": try await backend.start(vmID: uuid(1)); print("VM started")
        case "check":
            print(try await transport.request(vmID: args.count > 1 ? uuid(1) : UUID(), payload: .object(["op": .string("health")])).formatted)
        case "install": print(try await backend.installGuest(vmID: uuid(1)))
        case "clone": print(try await backend.clone(templateID: uuid(1), name: argument(2)).uuidString)
        case "register":
            let spec = try await manager.create(EnvironmentSpec(name: argument(2), vmID: uuid(1)))
            print(spec.id.uuidString)
        case "environments":
            for spec in try await manager.environments() { print("\(spec.id)  \(spec.vmID)  \(spec.name)") }
        case "submit":
            let input = try JSONDecoder().decode(JSONValue.self, from: Data(argument(3).utf8))
            let key = args.count > 4 ? args[4] : UUID().uuidString
            print(try await manager.submit(environment: uuid(1), tool: argument(2), input: input, idempotencyKey: key).formatted)
        case "clone-workspace":
            print(try await manager.clone(environment: uuid(1), name: argument(2)).id.uuidString)
        case "jobs": print(try await manager.jobs(environment: uuid(1)).formatted)
        case "get": print(try await manager.job(environment: uuid(1), jobID: argument(2)).formatted)
        case "wait": print(try await manager.result(environment: uuid(1), jobID: argument(2)).formatted)
        case "cancel": print(try await manager.cancel(environment: uuid(1), jobID: argument(2)).formatted)
        case "events": print(try await manager.events(environment: uuid(1), after: args.count > 2 ? Int(args[2]) ?? 0 : 0).formatted)
        case "export-guest":
            let target = URL(fileURLWithPath: try argument(1))
            try FileManager.default.copyItem(at: UTMBackend.guestFiles(), to: target)
            print(target.path)
        default:
            print("""
            genie-env list | environments
            genie-env start|check|install VM_UUID
            genie-env clone TEMPLATE_UUID NAME
            genie-env register VM_UUID NAME
            genie-env clone-workspace ENV_UUID NAME
            genie-env submit ENV_UUID TOOL JSON [IDEMPOTENCY_KEY]
            genie-env jobs ENV_UUID
            genie-env get|wait|cancel ENV_UUID JOB_ID
            genie-env events ENV_UUID [CURSOR]
            genie-env export-guest NEW_DIRECTORY

            Transport (utmctl cannot return guest output):
              GENIE_ENV_SSH_HOST=host [GENIE_ENV_SSH_USER=user] [GENIE_ENV_SSH_KEY=path]
              GENIE_ENV_ORB_MACHINE=name
            """)
        }
    }
}
