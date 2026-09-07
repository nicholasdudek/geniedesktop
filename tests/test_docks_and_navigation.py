import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
APP_DEFAULTS_FILE = BASE_DIR / "Sources/GoldGate/Helpers/AppDefaultsManager.swift"
DESKTOP_GRID_FILE = BASE_DIR / "Sources/GoldGate/Views/DesktopGridView.swift"
CHAT_DOCK_FILE = BASE_DIR / "Sources/GoldGate/Views/RightSideChatDockView.swift"
CHAT_BAR_FILE = BASE_DIR / "Sources/GoldGate/Views/AppleSearchBarNoteView.swift"

def test_app_defaults_dock_keys():
    """Verify all 4-side dock and mini-map keys are registered in AppDefaultsManager."""
    content = APP_DEFAULTS_FILE.read_text()
    expected_keys = [
        "nexus.isLeftChatDockOpen",
        "nexus.isRightChatDockOpen",
        "nexus.isRightAppsDockOpen",
        "nexus.showMiniDockInChatBar",
        "nexus.showAppsMiniMap",
    ]
    for key in expected_keys:
        # Keys are registered either as literals or via the compile-checked PrefKey constants
        # (Helpers/PreferenceKeys.swift), e.g. "nexus.showAppsMiniMap" -> PrefKey.showAppsMiniMap.
        ident = key[len("nexus."):].replace(".", "_")
        assert f'"{key}"' in content or f"PrefKey.{ident}" in content, f"Key {key} must be registered in AppDefaultsManager"

def test_dock_edge_support():
    """Verify DockEdge enum exists and supports leading and trailing edges."""
    content = CHAT_DOCK_FILE.read_text()
    assert "public enum DockEdge: Sendable" in content or "enum DockEdge" in content
    assert "case leading" in content
    assert "case trailing" in content
    assert "public var edge: DockEdge" in content

def test_desktop_grid_4_sided_docks():
    """Verify DesktopGridView contains 4-sided dock containers and hover triggers."""
    content = DESKTOP_GRID_FILE.read_text()
    
    # Left & Right edge containers
    assert "leftEdgeChatDockContainer" in content
    assert "rightEdgeDocksContainer" in content
    
    # Cursor hover triggers for all sides
    assert "location.x <= 10" in content, "Left edge cursor trigger must be present"
    assert "location.y >= screenSize.height - 24" in content, "Bottom edge cursor trigger must be present"
    assert "location.y <= 6" in content, "Top edge cursor trigger must be present"
    
    # Mutual exclusivity handlers
    assert ".onChange(of: isLeftChatDockOpen)" in content
    assert ".onChange(of: isRightChatDockOpen)" in content
    assert ".onChange(of: isRightAppsDockOpen)" in content
    assert ".onChange(of: isTopSearchBarPoppedDown)" in content
    assert ".onChange(of: appDisplayStageRaw)" in content

def test_chat_bar_mini_dock_and_mini_map():
    """Verify AppleSearchBarNoteView includes the top-notch mini dock drop-down and right apps mini-map."""
    content = CHAT_BAR_FILE.read_text()
    
    assert "chatBarMiniDockStrip" in content
    assert "compactRightSideAppsMiniMapView" in content
    assert "showAppsMiniMap" in content
    assert "showMiniDockInChatBar" in content

def test_apps_retrieval_and_bump_physics():
    """Verify full applications can be retrieved down to bottom and spring bump physics are configured."""
    content = DESKTOP_GRID_FILE.read_text()
    
    # Check spring bump dampingFraction ~0.70
    assert "dampingFraction: 0.70" in content, "Spring bump effect damping fraction must be ~0.70"
    
    # Check retrieval handle and gesture
    assert "Retrieve Applications ⬇️" in content or "Retrieve to Bottom" in content
    assert "appDisplayStage == .hidden ? screenSize.height" in content

def test_iphone_home_indicator_bar():
    """Verify iPhone Home Indicator bar is integrated with standard dimensions and stateful chevrons."""
    content = DESKTOP_GRID_FILE.read_text()
    
    # Check iPhoneHomeIndicatorBar definition and call
    assert "iPhoneHomeIndicatorBar(screenSize: screenSize, bottomClearance: bottomClearance)" in content
    assert "private func iPhoneHomeIndicatorBar" in content
    
    # Check standard iPhone Home Indicator capsule dimensions
    assert ".frame(width: 140, height: 5)" in content
    assert "chevron.compact.down" in content
    assert "chevron.compact.up" in content
    
    # Check stateful toggling on tap
    assert "appDisplayStage = .hidden" in content
    assert "appDisplayStage = .fullScreen" in content

def test_iphone_depth_and_motion_physics():
    """Verify iOS dynamic depth scaling, wallpaper backdrop blur, and 1:1 elastic gestures."""
    content = DESKTOP_GRID_FILE.read_text()
    
    # Wallpaper depth blur and scale
    assert "isTopSearchBarPoppedDown ? 1.02 : 1.0" in content
    assert "isTopSearchBarPoppedDown ? 10.0 : 0.0" in content
    assert "Color.black.opacity(isTopSearchBarPoppedDown ? 0.22 : 0.0)" in content
    
    # Underlying app grid background depth scaling & softening
    assert "isTopSearchBarPoppedDown ? 0.94 :" in content
    assert "(isTopSearchBarPoppedDown && appDisplayStage == .hidden) ? 4.0 : 0.0" in content
    
    # 1:1 Interactive iOS pull tracking and swipe gesture thresholds
    assert "value.translation.height * 0.85" in content
    assert "dy < -45" in content
    assert "dy > 45" in content

