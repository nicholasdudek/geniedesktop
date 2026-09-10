import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_gpu_forking_in_spaces_layer_manager():
    """Verify GPU frame buffer forking is integrated into SpacesLayerManager and SpaceGraphicLayer."""
    spaces_mgr = ROOT / "Sources/GoldGate/Core/SpacesLayerManager.swift"
    assert spaces_mgr.exists(), "SpacesLayerManager.swift must exist"
    content = spaces_mgr.read_text()

    # Verify SpaceGraphicLayer GPU properties
    assert "var isGPUForkActive: Bool" in content
    assert "var forkedFrame: GenieForkedFrame?" in content
    assert "var metalTexture: MTLTexture?" in content

    # Verify SpacesLayerManager GPU fork attachment APIs
    assert "func attachGPUFork(to spaceIndex: Int, frame: GenieForkedFrame)" in content
    assert "func detachGPUFork(from spaceIndex: Int)" in content
    assert "var isGPUSpacesForkingEnabled: Bool" in content


def test_gpu_forking_in_agent_virtual_spaces():
    """Verify GPU frame buffer stream is wired into AgentVirtualSpaceManager for background agent spaces."""
    agent_mgr = ROOT / "Sources/GoldGate/Core/AgentVirtualSpaceManager.swift"
    assert agent_mgr.exists(), "AgentVirtualSpaceManager.swift must exist"
    content = agent_mgr.read_text()

    # Verify AgentVirtualSpaceManager GPU streaming
    assert "var activeGPUForkedFrame: GenieForkedFrame?" in content
    assert "var isGPUVisualStreamActive: Bool" in content
    assert "func updateActiveGPUFrame(_ frame: GenieForkedFrame)" in content
    assert "func clearActiveGPUFrame()" in content


def test_expansion_pack_companions_and_snuggie_in_desktop_grid():
    """Verify all expansion pack companions and snuggies are implemented with render pipelines in DesktopGridView."""
    desktop_grid = ROOT / "Sources/GoldGate/Views/DesktopGridView.swift"
    assert desktop_grid.exists(), "DesktopGridView.swift must exist"
    content = desktop_grid.read_text()

    # Companions
    assert "case \"Japanese Koi Sanctuary 🎏\":" in content
    assert "case \"Pixel Yoshi Companion 🦖\":" in content
    assert "Two graceful koi swimming in harmony" in content
    assert "Pixel Dino Body" in content

    # Icon Snuggie
    assert "case \"Pixel Heart Armor ❤️\":" in content


def test_expansion_pack_shaders_in_atmospheric_engine():
    """Verify expansion pack shaders are recognized in AtmosphericShaderEngine."""
    shader_engine = ROOT / "Sources/GoldGate/Engine/AtmosphericShaderEngine.swift"
    assert shader_engine.exists(), "AtmosphericShaderEngine.swift must exist"
    content = shader_engine.read_text()

    # Shader aliases / implementations
    assert "4K Sakura Petal Blizzard 🌸" in content
    assert "Retro CRT Vector Scanline Grid 🕹️" in content


def test_expansion_store_manager_equip_pipeline():
    """Verify ExpansionStoreManager provides atomic applyPack and applyIncludedItem functionality."""
    store_mgr = ROOT / "Sources/GoldGate/Helpers/ExpansionStoreManager.swift"
    assert store_mgr.exists(), "ExpansionStoreManager.swift must exist"
    content = store_mgr.read_text()

    # Storage and equip methods
    assert "var equippedPackID: String?" in content
    assert "func isPackEquipped(_ id: String) -> Bool" in content
    assert "func applyPack(_ pack: ExpansionPackItem)" in content
    assert "func applyIncludedItem(_ itemString: String)" in content

    # Check key mappings handled by applyIncludedItem
    assert "PrefKey.ambientEntity" in content
    assert "PrefKey.wallpaperFxType" in content
    assert "PrefKey.appFormation" in content
    assert "PrefKey.iconSnuggie" in content
    assert "PrefKey.batteryStyle" in content


def test_expansion_pack_ui_equipping_in_menubar_dropdown():
    """Verify MenuBarDropdownView has interactive equip buttons and item lists."""
    dropdown = ROOT / "Sources/GoldGate/Views/MenuBarDropdownView.swift"
    assert dropdown.exists(), "MenuBarDropdownView.swift must exist"
    content = dropdown.read_text()

    # Registered entities and snuggies
    assert "Japanese Koi Sanctuary 🎏" in content
    assert "Pixel Yoshi Companion 🦖" in content
    assert "Pixel Heart Armor ❤️" in content

    # Interactive equip buttons in expansionPackCard
    assert "EQUIPPED ✓" in content
    assert "EQUIP PACK" in content
    assert "equipPackAction(pack)" in content
    assert "includedItemEquipRow" in content
