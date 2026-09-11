import os
import re
import pytest

SOURCES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "Sources", "GoldGate")

def test_preference_keys_defined():
    pref_keys_path = os.path.join(SOURCES_DIR, "Helpers", "PreferenceKeys.swift")
    assert os.path.exists(pref_keys_path), "PreferenceKeys.swift must exist"
    with open(pref_keys_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert 'public static let chatSliderItemOrder = "nexus.chatSliderItemOrder"' in content
    assert 'public static let isDualHemisphereMode = "nexus.isDualHemisphereMode"' in content
    assert 'public static let dualHemisphereSplitRatio = "nexus.dualHemisphereSplitRatio"' in content

def test_chat_slider_command_drag_reordering():
    dock_view_path = os.path.join(SOURCES_DIR, "Views", "ChatWindowAppleDockView.swift")
    assert os.path.exists(dock_view_path), "ChatWindowAppleDockView.swift must exist"
    with open(dock_view_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "savedSliderOrderRaw" in content
    assert "isCommandPressed" in content
    assert "draggedItemId" in content
    assert "orderedDockEntries" in content
    assert "DragGesture(minimumDistance: 3)" in content
    assert "DRAG TO REORDER" in content
    assert "NSEvent.addLocalMonitorForEvents(matching: .flagsChanged)" in content

def test_apple_finder_miller_columns_view_exists():
    finder_columns_path = os.path.join(SOURCES_DIR, "Views", "AppleFinderMillerColumnsBrowserView.swift")
    assert os.path.exists(finder_columns_path), "AppleFinderMillerColumnsBrowserView.swift must exist"
    with open(finder_columns_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "struct MillerColumnItem" in content
    assert "struct AppleFinderMillerColumnsBrowserView" in content
    assert "columnPaths" in content
    assert "scrollablePreviewColumn" in content
    assert "liveRenderPreviewPane" in content
    assert "fileContentPreviewPane" in content
    assert "promoteToDesktop" in content
    assert "MillerWebKitLivePreview" in content

def test_finder_window_manager_dual_hemisphere():
    manager_path = os.path.join(SOURCES_DIR, "Core", "FinderChatWindowManager.swift")
    assert os.path.exists(manager_path), "FinderChatWindowManager.swift must exist"
    with open(manager_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "isDualHemisphereMode" in content
    assert "func toggleDualHemisphere()" in content
    assert "NexusToggleDualHemisphere" in content
    assert "NexusDualHemisphereToggled" in content

def test_finder_style_chat_window_unfolds_miller_columns_and_trims_vscode():
    chat_view_path = os.path.join(SOURCES_DIR, "Views", "FinderStyleChatWindowView.swift")
    assert os.path.exists(chat_view_path), "FinderStyleChatWindowView.swift must exist"
    with open(chat_view_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "AppleFinderMillerColumnsBrowserView" in content
    assert "isDualHemisphereMode" in content
    assert "toggleDualHemisphere()" in content
    assert "Dual Screen" in content
