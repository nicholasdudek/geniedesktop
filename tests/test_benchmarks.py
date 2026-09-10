import os
import subprocess
from pathlib import Path
import pytest

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
APP_BINARY = Path("/Applications/Genie.app/Contents/MacOS/Genie")

def test_genie_app_binary_exists():
    assert APP_BINARY.exists(), f"Missing {APP_BINARY}"

def test_genie_benchmark_execution():
    result = subprocess.run(
        [str(APP_BINARY), "--benchmark"],
        capture_output=True,
        text=True,
        timeout=30
    )
    assert result.returncode == 0, f"Benchmark failed: {result.stderr}"
    output = result.stdout

    # 1. Ring Buffer Throughput
    assert "Zero-Copy GPU Pixel Ring Buffer Ingestion Throughput" in output
    assert "Throughput:" in output
    assert "Frames/Sec" in output

    # 2. Vision Verification ("Can you see with it")
    assert "Apple Silicon Neural Vision & Optical Text Ingestion" in output
    assert "Recognized Text Lines:" in output
    assert "GENIE NEURAL VISION" in output
    assert "CAN SEE" in output

    # 3. Memory Governor Resident Telemetry
    assert "Mach Task Resident Memory Sampling Latency" in output
    assert "Hard Cap: 4096 MB" in output

    # 4. Toolchain Screening
    assert "Toolchain Sandboxing Safety Screening Rate" in output
    assert "commands/sec" in output
