# Genie (GoldGate) - Native Hypervisor Edition

Native macOS spatial launcher + local-AI app. SwiftPM package named `Genie`, target source under `Sources/GoldGate`. Bundle id `com.nicholasdudek.genie`.

## 🏗️ The Native Architecture (Zero-Middleware)
Genie has been re-engineered to eliminate all external dependencies (e.g., OrbStack). It now uses a **Sovereign Hypervisor** approach.

### How it Works:
1. **The Golden Image**: A pre-baked `.raw` binary image of a minimalist Ubuntu environment containing all AI runtimes (Ollama, Spark, BigQuery).
2. **Native Spawning**: Uses Apple's `Virtualization.framework` to spawn isolated "Clones" directly from the macOS kernel.
3. **The Virtio-FS Bridge**: A memory-mapped shared folder (`/Users/nicholasdudek/Genie/shared_runtime`) allows the Mac app and Linux clones to share files with zero latency.
4. **Direct-to-Clone Communication**: The app communicates with models via native socket bridging, bypassing the need for external proxies.

## 🛠️ How to Create the Golden Image (from scratch)
If you need to regenerate the base environment:
1. **Boot a base Ubuntu VM** (via any hypervisor or cloud instance).
2. **Install Core Dependencies**:
   - `apt install openjdk-17-jdk python3-pip curl wget git`
   - `pip install watchdog`
3. **Configure Model Runtimes**: Install Ollama and pull the `genie-master` and `genie-macos-agent` models.
4. **Set Up Shared Folders**: Create `/home/ubuntu/genie_runtimes`.
5. **Export to RAW**: Use `qemu-img convert` or `orbctl export` to save the disk as `/Users/nicholasdudek/Genie/GoldenImage_Native.raw`.

## Build — two flavours, one codebase
```sh
swift build -c release                 # Developer ID (full)
GENIE_MAS=1 swift build -c release     # Genie Lite (Mac App Store, sandboxed)
```
Keep the two in separate scratch paths (`--scratch-path`); they differ only by a
compile-time define, so a shared `.build` will hand you the wrong binary. Verify
which one you have with `strings Genie | grep GENIE-BUILD-FLAVOUR`.

`GENIE_MAS=1` is read by *three* manifests — the root, `AgentRuntime/`, and
`EnvironmentKit/`. SwiftPM does not propagate a target's `.define` into its
dependencies, so each local package has to read the env var itself.

The Hypervisor engine below is **Developer ID only**. It needs
`com.apple.security.virtualization`, which the App Store profile cannot carry,
and booting a downloaded guest image is Guideline 2.5.2 regardless. Genie Lite
compiles it out — see `Helpers/GenieCapabilities.swift` for every such gate.

## AI providers
`GenieBrainProvider` routes requests to `HypervisorEngine` $\rightarrow$ `VZVirtualMachine` $\rightarrow$ `LocalModel`.
