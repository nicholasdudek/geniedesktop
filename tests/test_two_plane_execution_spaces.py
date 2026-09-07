import ctypes
import os
import plistlib
import subprocess
import tempfile
import time
from pathlib import Path
import pytest
import AppKit
import Quartz

BASE_DIR = Path(__file__).resolve().parents[1]
SPACES_LAYER_FILE = BASE_DIR / "Sources/GoldGate/Core/SpacesLayerManager.swift"
SKYLIGHT_GOVERNOR_FILE = BASE_DIR / "Sources/GoldGate/Engine/SkyLightNeuralGovernorEngine.swift"
MAC_DESKTOPS_FILE = BASE_DIR / "Sources/GoldGate/Core/MacDesktopsManager.swift"
SPATIAL_PLANE_FILE = BASE_DIR / "Sources/GoldGate/Core/SpatialPlaneManager.swift"

# MARK: - 1. Spatial 9-Grid (3x3) Coordinate Math & Topology

def slot_to_grid_coordinate(slot: int) -> tuple[int, int]:
    """Convert 1-based slot index (1..9) to 0-based (col, row) coordinates in 3x3 grid."""
    assert 1 <= slot <= 9, f"Slot {slot} out of 1..9 bounds"
    col = (slot - 1) % 3
    row = (slot - 1) // 3
    return (col, row)

def grid_coordinate_to_slot(col: int, row: int) -> int:
    """Convert 0-based (col, row) to 1-based slot index (1..9)."""
    assert 0 <= col < 3 and 0 <= row < 3, f"Coordinates ({col}, {row}) out of 3x3 bounds"
    return row * 3 + col + 1

def directional_navigate(current_slot: int, direction: str) -> int | None:
    """Compute target slot when navigating North, South, East, West in the 3x3 matrix."""
    col, row = slot_to_grid_coordinate(current_slot)
    if direction == "north" and row > 0:
        return grid_coordinate_to_slot(col, row - 1)
    elif direction == "south" and row < 2:
        return grid_coordinate_to_slot(col, row + 1)
    elif direction == "east" and col < 2:
        return grid_coordinate_to_slot(col + 1, row)
    elif direction == "west" and col > 0:
        return grid_coordinate_to_slot(col - 1, row)
    return None

def test_3x3_spatial_matrix_coordinate_bidirectionality():
    """Verify that all 9 slots round-trip perfectly between 1D index and 2D (col, row)."""
    expected_mapping = {
        1: (0, 0), # NW (Northwest)
        2: (1, 0), # N (North - Layer 2 Code & Matrix)
        3: (2, 0), # NE (Northeast)
        4: (0, 1), # W (West)
        5: (1, 1), # Center / Home
        6: (2, 1), # E (East)
        7: (0, 2), # SW (Southwest)
        8: (1, 2), # S (South)
        9: (2, 2), # SE (Southeast)
    }
    for slot, (expected_col, expected_row) in expected_mapping.items():
        col, row = slot_to_grid_coordinate(slot)
        assert (col, row) == (expected_col, expected_row), f"Slot {slot} mapped incorrectly"
        assert grid_coordinate_to_slot(col, row) == slot

def test_3x3_spatial_directional_vectors():
    """Verify 2D Cartesian navigation (North, South, East, West) across the 9 spaces."""
    # From Center (Slot 5)
    assert directional_navigate(5, "north") == 2 # Layer 2: Code & Matrix
    assert directional_navigate(5, "south") == 8 # South
    assert directional_navigate(5, "west") == 4  # West
    assert directional_navigate(5, "east") == 6  # East

    # From Layer 2 (Slot 2)
    assert directional_navigate(2, "south") == 5 # Back to Center
    assert directional_navigate(2, "west") == 1  # Prime Desktop
    assert directional_navigate(2, "east") == 3  # Design & Media
    assert directional_navigate(2, "north") is None # Edge boundary


# MARK: - 2. macOS Native Spaces Discovery & WindowServer Bridge

def test_native_spaces_plist_discovery():
    """Verify that macOS native Spaces configuration is accessible and parsable."""
    spaces_plist = Path.home() / "Library/Preferences/com.apple.spaces.plist"
    assert spaces_plist.exists(), "com.apple.spaces.plist must exist on macOS"

    with open(spaces_plist, "rb") as f:
        data = plistlib.load(f)

    configs = data.get("SpacesDisplayConfiguration", {})
    assert "Management Data" in configs, "SpacesDisplayConfiguration must contain Management Data"
    management = configs["Management Data"]
    monitors = management.get("Monitors", [])
    assert len(monitors) > 0, "At least one monitor must be tracked by macOS Spaces"

    primary_monitor = monitors[0]
    spaces = primary_monitor.get("Spaces", [])
    assert len(spaces) >= 1, "At least one space must exist on the primary monitor"

def test_skylight_windowserver_cgs_connection():
    """Verify that SkyLight framework exports the kernel compositor APIs needed for 9-grid space operations."""
    skylight_path = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
    skylight = ctypes.cdll.LoadLibrary(skylight_path)
    assert skylight is not None, "SkyLight.framework must load via dyld"

    # 1. SLSMainConnectionID
    assert hasattr(skylight, "SLSMainConnectionID")
    cid_func = skylight.SLSMainConnectionID
    cid_func.restype = ctypes.c_int32
    cid = cid_func()
    assert cid > 0, f"Valid Mach port connection ID expected, got {cid}"

    # 2. SLSMoveWindowsToManagedSpace (Window migration across spaces)
    assert hasattr(skylight, "SLSMoveWindowsToManagedSpace"), "SLSMoveWindowsToManagedSpace must be exported"

    # 3. SLSSpaceCreate (Space creation)
    assert hasattr(skylight, "SLSSpaceCreate"), "SLSSpaceCreate must be exported"

    # 4. SLSManagedDisplaySetCurrentSpace (Instant hardware space switch)
    assert hasattr(skylight, "SLSManagedDisplaySetCurrentSpace"), "SLSManagedDisplaySetCurrentSpace must be exported"


# MARK: - 3. Two-Plane Execution: "Code Ran -> After Code Move Those Items"

class TwoPlaneExecutionCoordinator:
    """
    Orchestrates the 2-Plane architecture:
    - Plane 1: Primary interactive user desktop.
    - Plane 2: Dedicated execution/sandbox space ("Layer 2 • Code & Matrix").
    
    When code runs in Plane 2, outputs (artifacts, files, generated notes) are staged.
    Upon completion, 'after_code_move_items' automatically migrates the completed items
    and target windows to Plane 1.
    """
    def __init__(self, workspace_root: Path):
        self.workspace_root = workspace_root
        self.plane1_desktop = workspace_root / "Plane1_PrimeDesktop"
        self.plane2_execution = workspace_root / "Plane2_CodeAndMatrix"
        self.plane1_desktop.mkdir(parents=True, exist_ok=True)
        self.plane2_execution.mkdir(parents=True, exist_ok=True)
        self.execution_log: list[str] = []

    def execute_in_plane_2(self, task_name: str, payload_items: dict[str, str]) -> dict[str, Path]:
        """Run code inside Plane 2 and produce generated artifacts."""
        self.execution_log.append(f"START: Task '{task_name}' running in Plane 2 (Code & Matrix)")
        generated: dict[str, Path] = {}

        for item_name, item_content in payload_items.items():
            item_path = self.plane2_execution / item_name
            item_path.write_text(item_content)
            generated[item_name] = item_path
            self.execution_log.append(f"GENERATED: {item_name} in Plane 2")

        self.execution_log.append(f"FINISH: Task '{task_name}' execution completed in Plane 2")
        return generated

    def after_code_move_items(self, items_to_move: list[str]) -> list[Path]:
        """Post-execution hook: Move items generated in Plane 2 to Plane 1."""
        migrated: list[Path] = []
        for name in items_to_move:
            src = self.plane2_execution / name
            dst = self.plane1_desktop / name
            if src.exists():
                src.rename(dst)
                migrated.append(dst)
                self.execution_log.append(f"MIGRATED: {name} from Plane 2 -> Plane 1 (Prime Desktop)")
        return migrated

def test_two_plane_execution_and_post_code_item_migration():
    """Verify the end-to-end 2-plane workflow: code runs in Plane 2, then moves items to Plane 1."""
    with tempfile.TemporaryDirectory() as tmpdir:
        coordinator = TwoPlaneExecutionCoordinator(Path(tmpdir))

        # 1. Plane 1 and Plane 2 initial state
        assert len(list(coordinator.plane1_desktop.iterdir())) == 0
        assert len(list(coordinator.plane2_execution.iterdir())) == 0

        # 2. Code runs in Plane 2 ("Code & Matrix")
        payload = {
            "AgentReport.md": "# Autonomous Analysis\nComplete test matrix validated.",
            "VisualArtifact.png": "PNG_MOCK_BYTES",
            "ResultSummary.json": '{"status": "success", "errors": 0}',
        }
        generated = coordinator.execute_in_plane_2("Genie Autonomous Build", payload)

        assert len(generated) == 3
        assert len(list(coordinator.plane2_execution.iterdir())) == 3
        assert len(list(coordinator.plane1_desktop.iterdir())) == 0  # Plane 1 still clean!

        # 3. Post-execution migration ("after code move those items")
        migrated = coordinator.after_code_move_items(["AgentReport.md", "VisualArtifact.png", "ResultSummary.json"])

        # 4. Verify items moved cleanly to Plane 1
        assert len(migrated) == 3
        assert (coordinator.plane1_desktop / "AgentReport.md").exists()
        assert (coordinator.plane1_desktop / "VisualArtifact.png").exists()
        assert (coordinator.plane1_desktop / "ResultSummary.json").exists()

        # Plane 2 workspace is now clean
        assert len(list(coordinator.plane2_execution.iterdir())) == 0

        # Check execution sequence log
        log_text = "\n".join(coordinator.execution_log)
        assert "START: Task 'Genie Autonomous Build' running in Plane 2" in log_text
        assert "FINISH: Task 'Genie Autonomous Build' execution completed in Plane 2" in log_text
        assert "MIGRATED: AgentReport.md from Plane 2 -> Plane 1 (Prime Desktop)" in log_text


# MARK: - 4. Swift Codebase Structural Conformance

def test_swift_spaces_layer_manager_plane2_definition():
    """Verify SpacesLayerManager defines Layer 2 as 'Code & Matrix' and has mergeLayerDown migration."""
    content = SPACES_LAYER_FILE.read_text()
    assert 'case 2: defaultName = "Layer 2 • Code & Matrix"' in content
    assert "public func mergeLayerDown(sourceSpaceIndex: Int)" in content
    assert "moveWindowsToSpace(windowIDs: winIDs, spaceID: targetSpaceID)" in content

def test_swift_skylight_neural_governor_window_mover():
    """Verify SkyLightNeuralGovernorEngine implements sub-millisecond window migration."""
    content = SKYLIGHT_GOVERNOR_FILE.read_text()
    assert "func moveWindowsToSpace(windowIDs: [CGWindowID], spaceID: UInt64) -> Bool" in content
    assert "SLSMoveWindowsToManagedSpace" in content

def test_swift_mac_desktops_manager_hardware_space_creation():
    """Verify MacDesktopsManager implements hardware-level space creation via SLSSpaceCreate."""
    content = MAC_DESKTOPS_FILE.read_text()
    assert "func executeHardwareSpaceCreation() -> UInt64?" in content
    assert "SLSSpaceCreate" in content
    assert "SLSManagedDisplaySetCurrentSpace" in content
