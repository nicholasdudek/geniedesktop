# 📦 Genie Examples & Reference Artifacts

This directory contains real, authentic content created in the Genie (`GoldGate`) project to demonstrate its architecture, tool execution, models, living wallpapers, and native automation pipelines.

---

## 📂 Directory Layout

```
examples/
├── agent_tools/
│   ├── tool_catalog.json           # 17-tool validated agent catalog schema
│   └── file_types_registry.json     # 56+ registered file categories (Code, Data, Media)
├── models/
│   ├── genie-master.Modelfile       # Flagship 27.3B + 460M CLIP local model definition
│   └── genie-frontier.Modelfile     # Frontier autonomous architecture definition
├── scripts/
│   ├── smoke_test.swift             # Standalone Swift test harness for core subsystems
│   └── full_system_test.swift       # End-to-end integration and hypervisor validation
├── wallpapers/
│   └── Neural Bloom.html            # Living HTML5 canvas wallpaper with audio reactivity
└── workflows/
    ├── vision_desktop_inspection.json  # Multimodal ScreenCaptureKit GUI comprehension
    ├── code_refactor_checkpoint.json   # Atomic edit with read-back diff verification
    └── worker_node_fork.json           # Virtio-FS worker node deployment
```

---

## 🛠️ 1. Native Agent Tool Catalog (`agent_tools/`)

Genie enforces strict pre-execution schema validation. Tool calls must match one of the 17 verified tools in [`tool_catalog.json`](tool_catalog.json):

* **Filesystem**: `list_files`, `read_file`, `search_files`, `merge_files`, `edit_file`, `write_file`
* **System & Execution**: `run_command`, `siri`
* **Accessibility Tree**: `read_ui`, `grab_text`, `copy_text`, `paste_text`
* **Autonomous GUI**: `desktop_agent` (open, move, click, double_click, right_click, drag, scroll, type, key, snapshot)
* **Mesh & Continuity**: `agent_network`, `airdrop`, `phone_bridge`
* **Inspection**: `app_doc`, `activity_log`

Mutating actions require interactive user approval gates and generate pre-execution atomic JSON checkpoints with byte-level read-back verification.

---

## 🧠 2. On-Device AI Modelfiles (`models/`)

Genie runs on Apple Silicon Unified Memory without external API dependencies:

* **[`genie-master.Modelfile`](models/genie-master.Modelfile)**:
  - Base: `qwen3.8:latest` (27.3B dense architecture)
  - Vision: 460M CLIP visual encoder for direct GUI comprehension without lossy OCR
  - Pre-prompted with the strict 17-tool catalog and formatting instructions
  - Build command:
    ```bash
    ollama create genie-master -f examples/models/genie-master.Modelfile
    ```
* **[`genie-frontier.Modelfile`](models/genie-frontier.Modelfile)**:
  - High-capacity reasoning variant for multi-step software synthesis.

---

## ⚡️ 3. Standalone Verification Scripts (`scripts/`)

Execute native Swift test harnesses directly using the Swift toolchain:

```bash
# Run the 10-point subsystem smoke verification
swift examples/scripts/smoke_test.swift

# Run full system diagnostics and memory checks
swift examples/scripts/full_system_test.swift
```

Both scripts test Mach kernel telemetry, window ordering levels, display link timing, and Virtio-FS bridges.

---

## 🌸 4. Living HTML Wallpapers (`wallpapers/`)

Genie features a 120 FPS living canvas engine that renders interactive WebGL/Canvas wallpapers directly behind your application windows:

* **[`Neural Bloom.html`](wallpapers/Neural%20Bloom.html)**:
  - Generative neural network node graph with dynamic synaptic pulses
  - Audio reactive visualizer using macOS system audio playback telemetry
  - Interactive cursor lightning arcs rendered via accelerated HTML5 Canvas
  - To preview, simply open `examples/wallpapers/Neural Bloom.html` in Safari or Chrome.

---

## 🔄 5. Execution Workflows (`workflows/`)

Real task traces showing Genie's atomic transaction model:

1. **[`vision_desktop_inspection.json`](workflows/vision_desktop_inspection.json)**: Takes a 2880x1800 retina snapshot, detects UI bounding boxes, and locates controls.
2. **[`code_refactor_checkpoint.json`](workflows/code_refactor_checkpoint.json)**: Locates target code via fast substring search, prompts for human confirmation, verifies bytes written, and invokes `swift build`.
3. **[`worker_node_fork.json`](workflows/worker_node_fork.json)**: Forks a headless worker node into `~/Genie/shared_runtime/` over Apple Virtualization virtio-fs.
