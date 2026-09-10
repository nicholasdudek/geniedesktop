import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_agent_sandboxing_integration():
    """Verify GenieSandboxedExecutionEngine, preference keys, and orchestrator hooks."""
    pref_keys_file = ROOT / "Sources/GoldGate/Helpers/PreferenceKeys.swift"
    assert pref_keys_file.exists()
    pref_text = pref_keys_file.read_text()
    assert "agentSandboxEnabled" in pref_text

    defaults_file = ROOT / "Sources/GoldGate/Helpers/AppDefaultsManager.swift"
    assert defaults_file.exists()
    defaults_text = defaults_file.read_text()
    assert "PrefKey.agentSandboxEnabled: true" in defaults_text

    engine_file = ROOT / "Sources/GoldGate/Engine/GenieSandboxedExecutionEngine.swift"
    assert engine_file.exists()
    engine_text = engine_file.read_text()
    assert "class GenieSandboxedExecutionEngine" in engine_text
    assert "sandbox-exec" in engine_text
    assert "generateSandboxProfile" in engine_text
    assert "screenCommand" in engine_text
    assert "Desktop/Genie/Workspace" in engine_text

    orchestrator_file = ROOT / "Sources/GoldGate/Engine/GenieSkillsOrchestrator.swift"
    orch_text = orchestrator_file.read_text()
    assert "GenieSandboxedExecutionEngine.shared.execute(command: clean)" in orch_text


def test_finder_chat_file_browser():
    """Verify live File Browser integration in FinderChat window."""
    browser_file = ROOT / "Sources/GoldGate/Views/FinderFileBrowserPaneView.swift"
    assert browser_file.exists()
    browser_text = browser_file.read_text()
    assert "struct FinderFileBrowserPaneView" in browser_text
    assert "updateDiskSpace" in browser_text
    assert "handleActivate" in browser_text
    assert "Reveal in Finder" in browser_text

    window_mgr = ROOT / "Sources/GoldGate/Core/FinderChatWindowManager.swift"
    mgr_text = window_mgr.read_text()
    assert "case files = \"Files\"" in mgr_text

    chat_view = ROOT / "Sources/GoldGate/Views/FinderStyleChatWindowView.swift"
    view_text = chat_view.read_text()
    assert "FinderFileBrowserPaneView" in view_text
    assert "case files = \"Files & Chat\"" in view_text
    assert "case filesOnly = \"Files\"" in view_text


def test_top_pull_down_liquid_glass_dashboard():
    """Verify top-edge pull-down liquid glass dashboard."""
    dash_file = ROOT / "Sources/GoldGate/Views/LiquidGlassTopDashboardView.swift"
    assert dash_file.exists()
    dash_text = dash_file.read_text()
    assert "struct LiquidGlassTopDashboardView" in dash_text
    assert "miniSettingsPane" in dash_text
    assert "systemTelemetryPane" in dash_text
    assert "headerClockWidget" in dash_text
    assert "quickChatPane" in dash_text

    desktop_grid = ROOT / "Sources/GoldGate/Views/DesktopGridView.swift"
    grid_text = desktop_grid.read_text()
    assert "LiquidGlassTopDashboardView" in grid_text
    assert "isTopSearchBarPoppedDown" in grid_text


def test_widgetkit_extension_architecture():
    """Verify GenieWidgets target, bundle, and registered widgets."""
    pkg_file = ROOT / "Package.swift"
    pkg_text = pkg_file.read_text()
    assert "\"GenieWidgets\"" in pkg_text
    assert "WidgetKit" in pkg_text

    widgets_file = ROOT / "Sources/GenieWidgets/GenieWidgets.swift"
    assert widgets_file.exists()
    w_text = widgets_file.read_text()
    assert "struct GenieWidgetsBundle: WidgetBundle" in w_text
    assert "struct GenieQuickChatWidget: Widget" in w_text
    assert "struct GenieSystemStatusWidget: Widget" in w_text
    assert "struct GenieWorkspaceSwitcherWidget: Widget" in w_text

    info_plist = ROOT / "Sources/GenieWidgets/Info.plist"
    assert info_plist.exists()
    entitlements = ROOT / "Sources/GenieWidgets/GenieWidgets.entitlements"
    assert entitlements.exists()
