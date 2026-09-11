# tests/test_desktop_organizer.py
# Verification test suite for Genie Desktop Organizer Engine and Refactor Sorting Tool

from pathlib import Path
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent

def test_desktop_organizer_engine_structure():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/GenieDesktopOrganizerEngine.swift"
    assert file_path.exists(), "GenieDesktopOrganizerEngine.swift must exist"
    content = file_path.read_text()

    assert "public final class GenieDesktopOrganizerEngine" in content
    assert "public enum DesktopSortCategory" in content
    assert "case screenshots = \"Screenshots\"" in content
    assert "case media = \"Media & Images\"" in content
    assert "case code = \"Developer & Code\"" in content
    assert "case documents = \"Documents & PDFs\"" in content
    assert "case archives = \"Archives & Installers\"" in content
    assert "case audio = \"Audio & Music\"" in content
    assert "categorize(fileURL: URL)" in content
    assert "organize(" in content
    assert "undoLastSort()" in content
    assert "dryRun: Bool" in content

def test_native_tool_engine_sort_desktop():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/GenieNativeToolEngine.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "sort_desktop" in content
    assert "organize_desktop" in content
    assert "refactor_sort" in content
    assert "runSortDesktopTool" in content
    assert "GenieDesktopOrganizerEngine.shared.organize" in content
    assert "undoLastSort" in content

def test_chat_task_policy_guidance():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/GenieChatTaskPolicy.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "REFACTOR SORTING & DESKTOP ORGANIZATION" in content
    assert "tool:sort_desktop" in content
    assert "NEVER waste dozens of separate tool calls" in content

def test_top_dashboard_sort_desktop_button():
    file_path = REPO_ROOT / "Sources/GoldGate/Views/LiquidGlassTopDashboardView.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "desktopSortFeedback" in content
    assert "Sort Desktop 🧹" in content
    assert "GenieDesktopOrganizerEngine.shared.organize" in content

def test_multi_device_shells_in_simulator():
    file_path = REPO_ROOT / "Sources/GoldGate/Views/GenieiPhoneDuoSimulatorView.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "ipadHardwareShell" in content
    assert "androidHardwareShell" in content
    assert "windowsHardwareShell" in content
    assert "iphoneHardwareShell" in content
    assert "stageManagerAppTile" in content
    assert "buildPlayStoreBundle" in content
    assert "GenieAndroidStorePackager.shared.scaffoldPlayStoreProject" in content
