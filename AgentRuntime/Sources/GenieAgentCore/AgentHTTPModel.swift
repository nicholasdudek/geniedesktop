import Foundation

/// OpenAI-compatible chat completions: OpenAI, Ollama /v1, LM Studio, or a configured gateway.
public struct AgentHTTPModel: AgentModel {
    public let endpoint: URL
    public let model: String
    private let apiKey: String
    public init(endpoint: URL, model: String, apiKey: String) throws {
        guard endpoint.scheme == "https" || endpoint.scheme == "http" else {
            throw AgentFailure("Use HTTP or HTTPS for the model endpoint.")
        }
        guard endpoint.user == nil, endpoint.password == nil, endpoint.query == nil,
              !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentFailure("Provide a model and an endpoint without embedded credentials or query parameters.")
        }
        self.endpoint = endpoint; self.model = model; self.apiKey = apiKey
    }

    public static func wireMessage(_ message: AgentMessage) -> [String: Any] {
        var value: [String: Any] = ["role": message.role, "content": message.content]
        if let id = message.callID { value["tool_call_id"] = id }
        if !message.calls.isEmpty {
            value["tool_calls"] = message.calls.map { ["id": $0.id, "type": "function", "function": ["name": $0.name, "arguments": $0.arguments]] as [String: Any] }
        }
        return value
    }

    public func reply(to messages: [AgentMessage]) async throws -> AgentReply {
        var request = URLRequest(url: endpoint, timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty { request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model, "messages": messages.map(Self.wireMessage), "tools": AgentToolCatalog.schemas,
            "stream": false, "max_completion_tokens": 8192
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AgentFailure("Model request failed (HTTP \(code)). Check endpoint, model access, API key and tool support.")
        }
        return try Self.decode(data)
    }

    public static func decode(_ data: Data) throws -> AgentReply {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]], let choice = choices.first,
              let message = choice["message"] as? [String: Any] else { throw AgentFailure("Invalid model response.") }
        guard (choice["finish_reason"] as? String) != "length" else { throw AgentFailure("Model response reached its output limit. No partial tool calls were executed.") }
        if let refusal = message["refusal"] as? String, !refusal.isEmpty { throw AgentFailure(refusal) }
        var calls: [AgentToolCall] = []
        var ids = Set<String>()
        for value in message["tool_calls"] as? [[String: Any]] ?? [] {
            guard let id = value["id"] as? String, !id.isEmpty, ids.insert(id).inserted,
                  value["type"] as? String == "function",
                  let function = value["function"] as? [String: Any],
                  let name = function["name"] as? String, let args = function["arguments"] as? String else {
                throw AgentFailure("Malformed or duplicate model tool call.")
            }
            calls.append(AgentToolCall(id: id, name: name, arguments: args))
        }
        let text = message["content"] as? String ?? ""
        guard !text.isEmpty || !calls.isEmpty else { throw AgentFailure("Model returned an empty response.") }
        let usage = object["usage"] as? [String: Any]
        return AgentReply(message: AgentMessage(role: "assistant", content: text, calls: calls), tokens: usage?["total_tokens"] as? Int ?? 0)
    }
}
