# What Nicholas M. Dudek Engineered in Genie

Genie (internal package name `GoldGate`) is a native macOS spatial launcher and
local-AI desktop agent, built from scratch as a Swift Package Manager project
(no Xcode project file — `swift build` / `xcodebuild` against `Package.swift`).
Bundle id `com.nicholasdudek.genie`. This document summarizes the engineering
work as of 2026-09-10, three days into the visible commit history.

## Architecture: a sovereign, zero-middleware hypervisor

Genie's AI backend does not shell out to a third-party runtime like OrbStack.
Instead it owns the whole stack:

- **Golden Image** — a pre-baked `.raw` Ubuntu disk image bundling every AI
  runtime Genie needs (Ollama, Spark, BigQuery tooling) baked in ahead of time.
- **Native spawning** — Apple's `Virtualization.framework` boots isolated
  clones of that image directly from the macOS kernel, no external hypervisor.
- **Virtio-FS bridge** — a memory-mapped shared folder
  (`~/Genie/shared_runtime`) gives the Mac app and the Linux clone a
  zero-latency shared filesystem.
- **Direct-to-clone sockets** — the app talks to models running inside the
  clone over native sockets, with no proxy in between.

This is under active construction: `GenieHypervisorEngine`, `RuntimeManager`,
`RuntimeConfig`/`RuntimeConfiguration`, `RuntimeConfiguratorView` and
`RuntimeLogView` model "runtimes" as provisionable instances (vCPU, RAM,
disk, golden-image path) that get spawned, tracked, and torn down through the
hypervisor — a small VM-fleet manager embedded in a menu-bar app.

**Two build flavors, one codebase.** `swift build -c release` produces the
full Developer ID build; `GENIE_MAS=1 swift build -c release` produces
"Genie Lite" for the Mac App Store sandbox. The hypervisor, `run_command`,
`merge_files`, and `app_doc` are compiled out entirely under `GENIE_MAS`
because they need entitlements (`com.apple.security.virtualization`) or
sandbox-illegal subprocess spawning that the App Store profile can't carry —
gated centrally through `Helpers/GenieCapabilities.swift` rather than
scattered `#if` checks.

## The agent runtime: a real tool-calling loop, not a chat wrapper

`AgentRuntime/` is a standalone Swift package (`GenieAgentCore`) implementing
a full agentic loop independent of any one model:

- `AgentRuntime.execute` drives a turn loop against any `AgentModel`
  (protocol, so local Ollama models and hosted models are interchangeable),
  enforcing a turn limit, a token budget, a payload-size ceiling, and a
  session timeout.
- Every tool call is **checkpointed before it runs** (`store.save(run)` ahead
  of side effects) so an interrupted run can be resumed without replaying
  actions whose outcome is unknown — resumption explicitly tells the model
  "outcome unknown, inspect real state" rather than trusting the last claim.
- **Mutating tools require explicit user approval**
  (`AgentToolCatalog.mutatingNames`) — writes, edits, clipboard paste, shell
  commands, desktop automation, AirDrop, iMessage, and network transfer all
  stop and wait for a human decision before executing.
- Sixteen tools make up the catalog: `list_files`, `read_file`, `write_file`,
  `edit_file`, `merge_files`, `search_files`, `read_ui`, `grab_text`,
  `copy_text`, `paste_text`, `run_command`, `desktop_agent` (open/click/drag/
  scroll/type/key/screenshot via raw CG events), `app_doc` (live AppleScript
  dictionary + bundle metadata for any installed app), `airdrop`,
  `phone_bridge` (iMessage to one preconfigured recipient — deliberately not
  addressable to arbitrary contacts), and `agent_network` (Bonjour peer
  discovery and file exchange between Genie instances on the LAN).
- File tools are workspace-sandboxed: `AgentTools.resolve(_:)` rejects
  absolute paths, `..` traversal, and any access to `.git` internals, and
  `write_file`/`edit_file` verify every write by reading the file back and
  diffing against the exact expected bytes rather than trusting the OS call
  succeeded.
- UI automation goes through macOS Accessibility (`read_ui` enumerates
  `AXUIElement`s with IDs; `grab_text`/`copy_text`/`paste_text` act only on
  IDs the model has already observed), never OCR guesswork, and secure text
  fields are excluded outright.

## Local AI

- `GenieLocalTinyModelEngine` curates a catalog of small local models that
  are *both* vision-capable and tool-calling-capable (Qwen3.5 0.8B/2B/4B,
  Qwen3-VL 4B), pulled on demand through Ollama — deliberately excluding
  otherwise-popular small models (Llama 3.2, Qwen2.5-Coder, DeepSeek-R1
  distills, Gemma 2, Phi-3.5) because each is missing one of the two
  capabilities, which would silently fail the moment a `desktop_agent`
  screenshot showed up in a tool-calling turn.
- The default model, `genie-master`, was given vision ("eyes") and its local
  context window doubled to 128k this week, alongside work to stop
  re-decoding the wallpaper on every frame — a real perf fix, not a feature.
- Genie can render a page it wrote and then look at the render
  ("Let Genie render and look at the pages it writes"), and attaches a
  screenshot to the *next* request rather than the one that triggered it, so
  the model reasons over what actually got drawn.
- Gemini credential handling is prefix-routed through Keychain rather than a
  single hardcoded token, and the GCP project splits Vertex AI (`aiplatform`,
  used by a sibling project, Antigravity) from the Generative Language API
  (used by Genie) under one project id.

## Desktop integration

- A full macOS menu-bar presence: `NSStatusItem` + borderless floating panels,
  a dock, a Finder-style chat window, a mini browser, and 54 SwiftUI views
  covering settings, environment configuration, chat layout themes, and the
  new runtime configurator.
- **World Clock**, ported and renamed under a `Genie` prefix this week
  (`GenieWorldClock`, `GenieAlarmClock`, `GenieAlarmClockManager`,
  `GenieAnalogWatchFace`): time-zone aware alarms, a floating watch dock, and
  hand-built analog clock rendering, alongside a from-scratch scroll-bar
  component (`GenieThickScrollBars`).
- Genie 4.0 added a Finder Sync extension, widgets, and agent sandboxing
  while removing an older custom VDOM rendering layer — a deliberate move
  toward the platform's own controls ("Use the platform's own controls
  instead of hand-rolled ones") over hand-rolled UI.
- A write boundary keeps the agent confined to `~/Desktop` at the OS level
  (`sandbox-exec` plus `GenieDesktopFileGuard`), independent of and in
  addition to the workspace-path sandboxing inside `AgentTools`.
- Dead code has been actively identified and removed rather than left to rot:
  `EmbeddedVSCodeStudioView` and `AIEditorBridgeEngine` are confirmed dead
  (chat writes actually live in `LocalModelManager`), and an HTML overlay
  manager/generator pair was deleted outright this week.

## Engineering discipline visible in the code

- Approval gating, path sandboxing, and read-back verification are applied
  consistently, not bolted on per-feature — the same "verify, don't trust"
  pattern shows up in file writes, clipboard paste, and tool-call resumption.
- The sandbox-vs-full-build split is enforced in exactly one place per
  package (`GenieCapabilities.swift`, plus each of the three SwiftPM
  manifests reading `GENIE_MAS` independently, since SwiftPM does not
  propagate a target's `.define` into local package dependencies) rather than
  scattered `#if GENIE_MAS` checks reproducing the same logic.
- Sixteen commits in three days cover architecture (hypervisor), model
  capability (vision, context window), UI simplification (dropping
  hand-rolled screen-size panes and emoji labels in favor of platform
  controls), and correctness fixes (tree ensemble fix, wallpaper re-decode
  fix) — a mix of new capability and active cleanup, not just feature
  accretion.
