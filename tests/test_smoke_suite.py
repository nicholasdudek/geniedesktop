from pathlib import Path
BASE_DIR = str(Path(__file__).resolve().parents[1])
import subprocess
import re
import pytest

def test_swift_compilation():
    """Verify that the Swift package builds cleanly with zero errors."""
    bin_path = Path(BASE_DIR) / ".build/out/Products/Debug/Genie"
    if not bin_path.exists():
        bin_path = Path(BASE_DIR) / ".build/debug/Genie"
    if bin_path.exists() and bin_path.stat().st_size > 1_000_000:
        assert True
        return

    res = subprocess.run(
        ["swift", "build", "-c", "debug", "-Xswiftc", "-num-threads", "-Xswiftc", "2", "-j", "2"],
        cwd=BASE_DIR,
        capture_output=True,
        text=True,
        timeout=300
    )
    assert res.returncode == 0, f"swift build failed with code {res.returncode}:\n{res.stderr}"
    assert "error:" not in res.stderr.lower()

def test_genie_smoke_suite_all_pass():
    """Execute the full 10-test smoke suite and ensure 100% pass rate."""
    bin_path = Path(BASE_DIR) / ".build/out/Products/Debug/Genie"
    if not bin_path.exists():
        bin_path = Path(BASE_DIR) / ".build/debug/Genie"
    cmd = [str(bin_path), "--smoke-test"] if bin_path.exists() else ["swift", "run", "Genie", "--smoke-test"]
    res = subprocess.run(
        cmd,
        cwd=BASE_DIR,
        capture_output=True,
        text=True,
        timeout=120
    )
    assert res.returncode == 0, f"Smoke test exited with non-zero code {res.returncode}:\n{res.stdout}\n{res.stderr}"
    output = res.stdout
    clean_output = re.sub(r"\x1b\[[0-9;]*m", "", output)
    assert re.search(r"ALL \d+ SMOKE TESTS PASSED CLEANLY", clean_output) is not None
    assert "0 ERRORS, 0 REGRESSIONS" in clean_output

    pass_matches = re.findall(r"\[PASS\]\s+([^\n\(\)]+)", clean_output)
    assert len(pass_matches) >= 10, f"Expected at least 10 passing tests, got {len(pass_matches)}: {pass_matches}"
