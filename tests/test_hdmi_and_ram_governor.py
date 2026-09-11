import os
import re
import subprocess
from pathlib import Path
import pytest

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
GOVERNOR_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieMemoryGovernorEngine.swift"
HDMI_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieHDMICaptureEngine.swift"
SANDBOX_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieSandboxedExecutionEngine.swift"
PREFS_FILE = REPO_ROOT / "Sources/GoldGate/Helpers/PreferenceKeys.swift"
DEFAULTS_FILE = REPO_ROOT / "Sources/GoldGate/Helpers/AppDefaultsManager.swift"

# MARK: - 1. Memory Governor Architecture & RAM Partitioning Tests

def test_memory_governor_source_exists():
    assert GOVERNOR_FILE.exists(), f"Missing {GOVERNOR_FILE}"
    content = GOVERNOR_FILE.read_text(encoding="utf-8")
    assert "class GenieMemoryGovernorEngine" in content
    assert "GenieMemoryPressureLevel" in content
    assert "DispatchSource.makeMemoryPressureSource" in content

def test_memory_governor_ulimit_and_partition_capping():
    content = GOVERNOR_FILE.read_text(encoding="utf-8")
    # Verify default 4096 MB budget and ulimit injection
    assert "maxAgentMemoryMB: Int = 4096" in content
    assert "effectiveMemoryLimitKB" in content
    assert "ulimit -v" in content
    assert "ulimit -m" in content

def test_memory_governor_thread_safe_critical_pressure_store():
    content = GOVERNOR_FILE.read_text(encoding="utf-8")
    assert "CriticalPressureStore" in content
    assert "nonisolated public static var isCriticalPressureActive: Bool" in content
    assert "purgeVolatileCaches" in content

def test_memory_governor_zero_leak_idle_sentinel():
    content = GOVERNOR_FILE.read_text(encoding="utf-8")
    assert "isLeakFree" in content
    assert "idleStatusDescription" in content
    assert "setupIdleSentinel" in content
    assert "evaluateIdleMemoryHealth" in content

# MARK: - 2. Zero-Copy GPU Pixel Forking Pipeline Tests

def test_hdmi_capture_pixel_forking_structures():
    assert HDMI_FILE.exists(), f"Missing {HDMI_FILE}"
    content = HDMI_FILE.read_text(encoding="utf-8")
    assert "struct GenieForkedFrame" in content
    assert "class GenieNeuralFrameRingBuffer" in content
    assert "neuralRingBuffer = GenieNeuralFrameRingBuffer(capacity: 45)" in content

def test_hdmi_capture_dual_channel_forking():
    content = HDMI_FILE.read_text(encoding="utf-8")
    # Display channel (Channel 1)
    assert "Channel 1: Display Channel (HDMI / Screen Output" in content
    assert "onMetalTextureCaptured" in content
    assert "onFrameCaptured" in content

    # Neural Training Channel (Channel 2)
    assert "Channel 2: Neural Training Channel (Zero-Copy Fork)" in content
    assert "isPixelForkActive" in content
    assert "forkedDisplayFrames" in content
    assert "forkedTrainingFrames" in content
    assert "droppedTrainingFrames" in content

def test_hdmi_ring_buffer_logic_simulation():
    """Simulate GenieNeuralFrameRingBuffer FIFO push/pop semantics."""
    class MockRingBuffer:
        def __init__(self, capacity=45):
            self.capacity = capacity
            self.buffer = []
            self.dropped = 0
            self.admitted = 0

        def push(self, frame_id):
            if len(self.buffer) >= self.capacity:
                self.buffer.pop(0)
                self.dropped += 1
                self.buffer.append(frame_id)
                return False
            self.buffer.append(frame_id)
            self.admitted += 1
            return True

        def pop(self):
            return self.buffer.pop(0) if self.buffer else None

    rb = MockRingBuffer(capacity=5)
    for i in range(10):
        rb.push(f"frame_{i}")

    assert len(rb.buffer) == 5
    assert rb.dropped == 5
    assert rb.admitted == 5
    assert rb.pop() == "frame_5"

# MARK: - 3. Sandbox Engine & Toolchain Isolation Tests

def test_sandbox_strips_personal_credentials():
    assert SANDBOX_FILE.exists(), f"Missing {SANDBOX_FILE}"
    content = SANDBOX_FILE.read_text(encoding="utf-8")
    # Must remove host credentials
    assert 'env.removeValue(forKey: "SSH_AUTH_SOCK")' in content
    assert 'env.removeValue(forKey: "AWS_ACCESS_KEY_ID")' in content
    assert 'env.removeValue(forKey: "AWS_SECRET_ACCESS_KEY")' in content
    assert 'env.removeValue(forKey: "GITHUB_TOKEN")' in content

def test_sandbox_isolated_path_and_history():
    content = SANDBOX_FILE.read_text(encoding="utf-8")
    # Toolchain isolation: uses dedicated agent user directories and workspace history
    assert "/Users/genie-agent/.local/bin" in content
    assert ".genie_zsh_history" in content
    assert "GENIE_RAM_LIMIT_MB" in content
    assert "ramPartitionMB: Int" in content

def test_preferences_contain_agent_and_hdmi_keys():
    prefs_content = PREFS_FILE.read_text(encoding="utf-8")
    assert "agentDedicatedUserEnabled" in prefs_content
    assert "agentMemoryLimitMB" in prefs_content
    assert "hdmiPixelForkEnabled" in prefs_content

    defaults_content = DEFAULTS_FILE.read_text(encoding="utf-8")
    assert "PrefKey.agentMemoryLimitMB: 4096" in defaults_content
    assert "PrefKey.hdmiPixelForkEnabled: true" in defaults_content
