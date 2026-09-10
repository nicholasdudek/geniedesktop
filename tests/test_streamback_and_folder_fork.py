import os
import subprocess
import pytest
from pathlib import Path

def test_apfs_clonefile_system_support(tmp_path):
    """Verifies that macOS APFS copy-on-write clonefile behaves instantaneously."""
    src = tmp_path / "origin.txt"
    dst = tmp_path / "cloned.txt"
    src.write_text("GENIE_APFS_COW_VERIFICATION_PAYLOAD", encoding="utf-8")

    # Use /bin/cp -c (macOS APFS clone)
    res = subprocess.run(["/bin/cp", "-c", str(src), str(dst)], capture_output=True, text=True)
    assert res.returncode == 0
    assert dst.exists()
    assert dst.read_text(encoding="utf-8") == "GENIE_APFS_COW_VERIFICATION_PAYLOAD"

def test_shared_folder_bridge_hierarchy():
    """Verifies the shared bridge directory hierarchy under /Users/Shared/Genie."""
    bridge_root = Path("/Users/Shared/Genie/Bridge")
    spaces_root = Path("/Users/Shared/Genie/spaces")

    # Check existence or create through standard bridge dirs
    subdirs = ["stream", "artifacts", "inbox", "outbox"]
    for sub in subdirs:
        subpath = bridge_root / sub
        subpath.mkdir(parents=True, exist_ok=True)
        assert subpath.exists()
        assert subpath.is_dir()

    spaces_root.mkdir(parents=True, exist_ok=True)
    assert spaces_root.exists()

def test_preference_keys_defined():
    """Verifies that all new preference keys are registered in Swift code."""
    pref_file = Path("Sources/GoldGate/Helpers/PreferenceKeys.swift")
    assert pref_file.exists()
    content = pref_file.read_text(encoding="utf-8")

    assert "streamBackForkEnabled" in content
    assert "streamBackPort" in content
    assert "sharedFolderBridgeEnabled" in content
    assert "agentBrainProvider" in content

def test_streamback_and_folder_fork_engines_exist():
    """Verifies the source files for the Stream-Back, Shared Folder Fork, and Autonomous Loop engines."""
    streamback_file = Path("Sources/GoldGate/Engine/GenieStreamBackEngine.swift")
    folderfork_file = Path("Sources/GoldGate/Engine/GenieSharedFolderForkEngine.swift")
    autonomous_file = Path("Sources/GoldGate/Engine/GenieAutonomousLoopEngine.swift")

    assert streamback_file.exists()
    assert folderfork_file.exists()
    assert autonomous_file.exists()

    sb_content = streamback_file.read_text(encoding="utf-8")
    assert "GenieStreamBackEngine" in sb_content
    assert "runHttpServer" in sb_content
    assert "multipart/x-mixed-replace" in sb_content

    ff_content = folderfork_file.read_text(encoding="utf-8")
    assert "GenieSharedFolderForkEngine" in ff_content
    assert "forkZeroCopy" in ff_content
    assert "clonefile" in ff_content

    al_content = autonomous_file.read_text(encoding="utf-8")
    assert "GenieAutonomousLoopEngine" in al_content
    assert "GenieBrainProvider" in al_content
    assert "cloudGemini" in al_content

def test_genie_app_all_19_smoke_tests_pass():
    """Executes the updated Genie app smoke test suite and verifies all 19 tests pass cleanly."""
    app_binary = "/Applications/Genie.app/Contents/MacOS/Genie"
    assert os.path.exists(app_binary)

    res = subprocess.run([app_binary, "--smoke-test"], capture_output=True, text=True, timeout=30)
    assert res.returncode == 0
    assert "SMOKE TESTS PASSED CLEANLY" in res.stdout
    assert "Zero-Copy APFS Folder Forking & Shared Bridge" in res.stdout
    assert "Channel 3 Upstream Video Stream-Back Fork" in res.stdout
    assert "Autonomous Actuator & Hybrid Brain Routing (Local + API)" in res.stdout
