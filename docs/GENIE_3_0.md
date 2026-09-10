# Genie 3.0 development release

Version 3.0.0, build 300 adds a workspace agent alongside the existing chat UI.

## Use

1. Open the chat dock and select **Agent 3.0**.
2. Set the full chat-completions URL and an exact model ID supported by your server. The model must support function tools.
   - Ollama: `http://localhost:11434/v1/chat/completions`
   - OpenAI: `https://api.openai.com/v1/chat/completions`
   - LM Studio: its configured local server URL ending in `/v1/chat/completions`.
3. For a remote provider, enter your own API key. **Save key** stores it in macOS Keychain, scoped to the endpoint. No key is included in task history.
4. Choose the repository or working folder and describe an outcome and a check, such as “Fix this fixture and run its tests.”
5. Review exact edits and commands. Reads, search and directory listings run within the selected workspace. Commands run with normal user permissions and are not an OS sandbox.

Task messages and tool outputs are sent to the endpoint you configure. Local model endpoints can keep those requests on your Mac. This differs from earlier offline-only product descriptions. Existing chat and bridge integrations retain their separate settings and data flows.

## Runtime

`AgentRuntime` is a standalone Swift package with no third-party dependencies. The UI observes an actor-based loop; filesystem work and subprocess polling do not run on the main actor.

- Five structured tools: list, read, search, exact text edit/create, and command execution.
- Each file edit and shell command requires approval. Commands execute with normal user permissions; a working directory is not a sandbox.
- File tools reject absolute paths, parent traversal, symlink escapes and direct `.git` access. Text files and output are bounded at 64 KB.
- Commands run in their own process groups. Stop and the 60-second timeout kill the group; background descendants are stopped when the foreground command exits.
- The runtime checkpoints before tool execution and after results, using atomic JSON files with owner-only permissions under `~/Library/Application Support/Genie/AgentRuns`.
- Resume is explicit. Unmatched calls receive “outcome unknown” results so the model must inspect state; the harness never automatically replays a pending action.
- Limits: 24 model turns per session, 100,000 provider-reported tokens per task, 180 KB conversation payload, and a 10-minute session check between model turns. A model request can run for up to 120 seconds, and user approval time is unbounded.
- A successful command is recorded as evidence, not proof that the whole task is correct. The final response must describe the checks actually performed.

## Validation

Run isolated runtime tests without launching Genie:

```sh
cd AgentRuntime
swift test
```

Tests cover an edit/verify/save loop, approval denial, path traversal and symlink rejection, exact-match writes, command exit codes, timeout, cancellation, interrupted-run recovery, token limits, and truncated model output. They use scripted model responses and temporary workspaces; no paid API calls are made.

Build the app from the project root with `swift build`. The current project targets macOS 27 as configured before the runtime integration.

## Release boundaries

The new agent supports OpenAI-compatible tool calling. Native Claude and Gemini chat integrations remain in the existing Chat mode; they have not been migrated to the structured runtime. Browser/desktop automation, MCP discovery, parallel agents, automatic context compaction, dollar-based budgets and unattended approval policies are not part of this release.

The existing App Store profile has no network entitlement and is not the distribution path for this agent. Do not publish the prior offline privacy claims for the direct 3.0 build. No App Store upload or external release is performed by building this project.

The upgrade also repairs initial World Clock tab selection, multi-display right-edge cursor coordinates, and full-size generated desktop wallpapers. The previous suite has stale expectations for removed UI and SwiftDOM files; the new runtime tests do not conceal those failures.

Tool protocol reference: https://developers.openai.com/api/docs/guides/function-calling
