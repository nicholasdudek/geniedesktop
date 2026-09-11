# tests/test_app_trainer_and_iphone_duo.py
# Verification test suite for Genie App Trainer, Fullscreen Mario Window, and iPhone Duo Simulator

from pathlib import Path
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent

def test_app_trainer_engine_structure():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/GenieAppTrainerEngine.swift"
    assert file_path.exists(), "GenieAppTrainerEngine.swift must exist"
    content = file_path.read_text()

    assert "public final class GenieAppTrainerEngine" in content
    assert "public struct TrainedMacApp" in content
    assert "/Applications" in content
    assert "/System/Applications" in content
    assert "NSAppleScriptEnabled" in content
    assert "generateTrainingSystemPrompt()" in content
    assert "trainOnInstalledMacApps()" in content

def test_local_model_manager_trainer_and_iphone_tools():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/LocalModelManager.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "GenieAppTrainerEngine.shared.generateTrainingSystemPrompt()" in content
    assert "IPHONE SIMULATOR, DUO FOLD & MOVIE STREAMING TOOLS" in content
    assert "iphone_browser" in content
    assert "iphone_simulator" in content
    assert "duo_simulator" in content

def test_fullscreen_window_and_mario_letters():
    file_path = REPO_ROOT / "Sources/GoldGate/Views/LiquidGlassTopDashboardView.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert 'var isZenModeEnabled: Bool = true' in content, "Zen Mode must default to true for fullscreen first"
    assert 'genieTopDockPosX' in content, "Must persist X coordinate"
    assert 'genieTopDockPosY' in content, "Must persist Y coordinate"
    assert 'dismissDashboard' in content
    assert 'GENIE FULLSCREEN STUDIO' in content
    assert 'heroMode: true' in content

    banner_path = REPO_ROOT / "Sources/GoldGate/Views/GenieTopDockNeuralEngineBannerView.swift"
    assert banner_path.exists()
    banner_content = banner_path.read_text()
    assert "heroMode: Bool = false" in banner_content
    assert "████   █████  ██   ██  ██  █████" in banner_content
    assert "TRAINED ON" in banner_content

def test_iphone_duo_simulator_view():
    file_path = REPO_ROOT / "Sources/GoldGate/Views/GenieiPhoneDuoSimulatorView.swift"
    assert file_path.exists(), "GenieiPhoneDuoSimulatorView.swift must exist"
    content = file_path.read_text()

    assert "public final class iPhoneDuoSimulatorManager" in content
    assert "public struct GenieiPhoneDuoSimulatorView" in content
    assert "isDuoScreenMode" in content
    assert "isLandscapeMovieMode" in content
    assert "youtube.com" in content
    assert "netflix.com" in content
    assert "launchNativeXcodeSimulator" in content
    assert "openURLInBootedSimulator" in content

def test_duo_fold_container_split_editor_and_movie():
    file_path = REPO_ROOT / "Sources/GoldGate/Views/GenieDuoFoldContainerView.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert "DuoFoldPage2Content" in content
    assert "splitEditorAndSimulator" in content
    assert "page2WorkspaceView" in content
    assert "GenieiPhoneDuoSimulatorView" in content
    assert "GenieNativeEditorPreviewerView" in content

def test_native_tool_engine_iphone_and_duo_dispatch():
    file_path = REPO_ROOT / "Sources/GoldGate/Engine/GenieNativeToolEngine.swift"
    assert file_path.exists()
    content = file_path.read_text()

    assert 'case "iphone_simulator"' in content
    assert 'case "iphone_browser"' in content
    assert 'case "duo_simulator"' in content
    assert 'case "iphone_mirror"' in content
    assert "runiPhoneSimulatorTool" in content
    assert "runiPhoneBrowserTool" in content
    assert "runDuoSimulatorTool" in content
