import os
import pytest

SOURCES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../Sources/GoldGate"))

def test_preference_keys_defined():
    pref_keys_path = os.path.join(SOURCES_DIR, "Helpers/PreferenceKeys.swift")
    assert os.path.exists(pref_keys_path), "PreferenceKeys.swift must exist"
    with open(pref_keys_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "reverseStationScrollWheelDirection" in content, "reverseStationScrollWheelDirection key missing"
    assert "wheelSlideDownShowsTopStation" in content, "wheelSlideDownShowsTopStation key missing"
    assert "clearHTMLOverlayEnabled" in content, "clearHTMLOverlayEnabled key missing"

def test_app_defaults_registered():
    defaults_path = os.path.join(SOURCES_DIR, "Helpers/AppDefaultsManager.swift")
    assert os.path.exists(defaults_path), "AppDefaultsManager.swift must exist"
    with open(defaults_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "PrefKey.wheelSlideDownShowsTopStation: true" in content or "wheelSlideDownShowsTopStation" in content
    assert "PrefKey.reverseStationScrollWheelDirection: false" in content or "reverseStationScrollWheelDirection" in content
    assert "PrefKey.clearHTMLOverlayEnabled: false" in content or "clearHTMLOverlayEnabled" in content

def test_continuous_station_scroll_engine_wheel_inversion():
    engine_path = os.path.join(SOURCES_DIR, "Engine/ContinuousStationScrollEngine.swift")
    assert os.path.exists(engine_path), "ContinuousStationScrollEngine.swift must exist"
    with open(engine_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "slideDownShowsTopStation" in content, "slideDownShowsTopStation computed property missing"
    assert "reverseWheelDirection" in content, "reverseWheelDirection computed property missing"
    assert "shouldInvert" in content, "Wheel direction inversion check missing"
    assert "handleDiscreteMouseWheel" in content, "Discrete mouse wheel handler missing"

def test_desktop_grid_view_wheel_routing():
    grid_view_path = os.path.join(SOURCES_DIR, "Views/DesktopGridView.swift")
    assert os.path.exists(grid_view_path), "DesktopGridView.swift must exist"
    with open(grid_view_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "slideDownShowsTop" in content, "slideDownShowsTop check missing in DesktopGridView"
    assert "isSwipeUp" in content and "isSwipeDown" in content, "Swipe direction evaluation missing"

def test_html_solution_generator():
    generator_path = os.path.join(SOURCES_DIR, "Engine/GenieHTMLSolutionGenerator.swift")
    assert os.path.exists(generator_path), "GenieHTMLSolutionGenerator.swift must exist"
    with open(generator_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "genieBridge" in content, "genieBridge JavaScript message handler missing"
    assert "wireInteractiveElements" in content, "Element wiring logic missing"
    assert "solutionsHubHTML" in content, "solutionsHubHTML generator missing"
    assert "imageGalleryHTML" in content, "imageGalleryHTML generator missing"
    assert "wrapCustomHTML" in content, "wrapCustomHTML generator missing"

def test_clear_html_overlay_manager_and_view():
    manager_path = os.path.join(SOURCES_DIR, "Core/GenieClearHTMLOverlayManager.swift")
    assert os.path.exists(manager_path), "GenieClearHTMLOverlayManager.swift must exist"
    with open(manager_path, "r", encoding="utf-8") as f:
        m_content = f.read()

    assert "GenieClearHTMLOverlayManager" in m_content
    assert "NSPanel" in m_content
    assert "isOpaque = false" in m_content
    assert "toggle()" in m_content

    view_path = os.path.join(SOURCES_DIR, "Views/GenieClearHTMLOverlayView.swift")
    assert os.path.exists(view_path), "GenieClearHTMLOverlayView.swift must exist"
    with open(view_path, "r", encoding="utf-8") as f:
        v_content = f.read()

    assert "WKWebView" in v_content
    assert "genieBridge" in v_content
    assert "handleSwiftAction" in v_content
    assert "switchStation" in v_content

def test_unified_settings_view_toggles():
    settings_path = os.path.join(SOURCES_DIR, "Views/UnifiedSettingsView.swift")
    assert os.path.exists(settings_path), "UnifiedSettingsView.swift must exist"
    with open(settings_path, "r", encoding="utf-8") as f:
        content = f.read()

    assert "wheelSlideDownShowsTopStation" in content
    assert "reverseStationScrollWheelDirection" in content
    assert "Mouse Wheel & Station Navigation" in content
    assert "Clear HTML Overlay & Solutions" in content
