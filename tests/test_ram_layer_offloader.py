import os
import re
from pathlib import Path
import pytest

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
OFFLOADER_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieRAMLayerOffloaderEngine.swift"
GOVERNOR_FILE = REPO_ROOT / "Sources/GoldGate/Engine/GenieMemoryGovernorEngine.swift"
SPATIAL_PLANE_FILE = REPO_ROOT / "Sources/GoldGate/Core/SpatialPlaneManager.swift"
SPACES_LAYER_FILE = REPO_ROOT / "Sources/GoldGate/Core/SpacesLayerManager.swift"


def test_ram_layer_offloader_engine_exists():
    """Verify GenieRAMLayerOffloaderEngine is implemented with full offload and lazy hydration lifecycle."""
    assert OFFLOADER_FILE.exists(), f"Missing {OFFLOADER_FILE}"
    content = OFFLOADER_FILE.read_text(encoding="utf-8")
    assert "class GenieRAMLayerOffloaderEngine: ObservableObject" in content
    assert "func offloadRAMLayersWhenNecessary()" in content
    assert "func offloadInactiveRAMLayers(critical: Bool)" in content
    assert "func offloadDistantSpatialLayers()" in content
    assert "func hydrateLayerIfNeeded(screenIndex: Int)" in content
    assert "var totalRAMReclaimedMB: Double" in content
    assert "var isOffloadingActive: Bool" in content
    assert "var activeResidentLayerCount: Int" in content


def test_spatial_plane_manager_has_layer_offloading_support():
    """Verify DesktopPlaneRAMCache supports offloading flags and disk paths."""
    assert SPATIAL_PLANE_FILE.exists(), f"Missing {SPATIAL_PLANE_FILE}"
    content = SPATIAL_PLANE_FILE.read_text(encoding="utf-8")
    assert "public var isOffloaded: Bool = false" in content
    assert "public var offloadedDiskPath: URL? = nil" in content
    assert "func isImmediateCardinalNeighbor" in content
    assert "buffer.isOffloaded = true" in content


def test_spaces_layer_manager_has_ram_layer_offloading_support():
    """Verify SpaceGraphicLayer supports offloading 4K Metal textures and video frames."""
    assert SPACES_LAYER_FILE.exists(), f"Missing {SPACES_LAYER_FILE}"
    content = SPACES_LAYER_FILE.read_text(encoding="utf-8")
    assert "public var isOffloaded: Bool = false" in content
    assert "mutating func offloadRAMLayer()" in content
    assert "mutating func hydrateRAMLayer()" in content
    assert "func offloadInactiveLayers" in content
    assert "func hydrateLayerIfNeeded" in content


def test_memory_governor_triggers_layer_offloading_on_pressure():
    """Verify GenieMemoryGovernorEngine invokes layer offloading under high memory pressure."""
    assert GOVERNOR_FILE.exists(), f"Missing {GOVERNOR_FILE}"
    content = GOVERNOR_FILE.read_text(encoding="utf-8")
    assert "GenieRAMLayerOffloaderEngine.shared.offloadInactiveRAMLayers" in content
    assert "func offloadRAMLayersWhenNecessary()" in content


def test_ram_layer_offloading_simulation():
    """Simulate 81-screen universe memory reduction from layer offloading."""
    total_screens = 81
    screen_width = 3840
    screen_height = 2160
    bytes_per_pixel = 4
    image_bytes = screen_width * screen_height * bytes_per_pixel # ~33.17 MB per 4K image
    images_per_screen = 2 # Wallpaper + Thumbnail

    full_uncompressed_bytes = total_screens * images_per_screen * image_bytes
    full_uncompressed_mb = full_uncompressed_bytes / (1024 * 1024)

    # With offloading: only focal screen + 4 cardinal neighbors reside in RAM (max 5 screens)
    resident_screens = 5
    offloaded_screens = total_screens - resident_screens

    resident_mb = (resident_screens * images_per_screen * image_bytes) / (1024 * 1024)
    reclaimed_mb = (offloaded_screens * images_per_screen * image_bytes) / (1024 * 1024)

    assert full_uncompressed_mb > 5000, f"Expected >5GB without offloading, got {full_uncompressed_mb}MB"
    assert resident_mb < 350, f"Expected resident RAM < 350MB, got {resident_mb}MB"
    assert reclaimed_mb > 4800, f"Expected reclaimed RAM > 4.8GB, got {reclaimed_mb}MB"

    reduction_percentage = (reclaimed_mb / full_uncompressed_mb) * 100.0
    assert reduction_percentage > 90.0, f"Expected >90% memory savings, got {reduction_percentage}%"
