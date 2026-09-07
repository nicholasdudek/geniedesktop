from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
ENGINE_DIR = BASE_DIR / "Sources/GoldGate/Engine"
CORE_DIR = BASE_DIR / "Sources/GoldGate/Core"
HELPERS_DIR = BASE_DIR / "Sources/GoldGate/Helpers"

def test_atmospheric_shader_engine_variables():
    content = (ENGINE_DIR / "AtmosphericShaderEngine.swift").read_text()
    
    # Assert descriptive parameters in canonical function
    assert "canvasWidth: CGFloat" in content
    assert "canvasHeight: CGFloat" in content
    assert "elapsedTime: Double" in content
    assert "shaderType: String" in content
    assert "opacityAlpha: CGFloat" in content
    
    # Assert backward-compatible overload exists
    assert "@inlinable" in content
    assert "public static func draw(" in content
    assert "W: CGFloat" in content
    assert "H: CGFloat" in content
    assert "canvasWidth: W" in content

def test_swift_dom_engine_variables():
    swift_dom_file = ENGINE_DIR / "SwiftDOMEngine.swift" if (ENGINE_DIR / "SwiftDOMEngine.swift").exists() else ENGINE_DIR / "SwiftDOM.swift"
    content = swift_dom_file.read_text()
    
    assert "func buildUniverseTree(screenWidth: CGFloat, screenHeight: CGFloat, forceUniverse81: Bool? = nil)" in content
    assert "func build9GridTree(screenWidth: CGFloat, screenHeight: CGFloat)" in content
    assert "gridDimension" in content
    assert "buildGridHierarchy" in content
    assert "isUniverse81" in content
    assert "canvasSize" in content
    assert "viewportSize" in content
    
    # Assert backward-compatible overloads
    assert "func buildUniverseTree(screenW: CGFloat, screenH: CGFloat)" in content
    assert "func build9GridTree(screenW: CGFloat, screenH: CGFloat)" in content

def test_spatial_plane_manager_variables():
    content = (CORE_DIR / "SpatialPlaneManager.swift").read_text()
    
    # Struct fields
    assert "var compassOrientation: String" in content
    assert "var columnCoordinate: Int" in content
    assert "var rowCoordinate: Int" in content
    assert "var desktopPlaneCacheBuffers: [Int: DesktopPlaneRAMCache]" in content
    
    # Backward compatibility
    assert "var compass: String" in content
    assert "var col: Int" in content
    assert "var row: Int" in content
    assert "var ramBuffers: [Int: DesktopPlaneRAMCache]" in content
    
    # Coordinate functions
    assert "func universeCoordinate(for index: Int) -> (col: Int, row: Int)" in content
    assert "func indexForUniverse(columnCoordinate: Int, rowCoordinate: Int) -> Int" in content
    assert "func indexForGrid(columnCoordinate: Int, rowCoordinate: Int) -> Int" in content
    
    # Physics methods
    assert "func handleContinuousCanvasPanDelta(deltaX: CGFloat, deltaY: CGFloat, allowsRubberBanding: Bool = true)" in content
    assert "func handleThreeFingerScrollDelta(deltaX: CGFloat, deltaY: CGFloat)" in content
    assert "func handleThreeFingerSwipeJump(deltaX: CGFloat, deltaY: CGFloat)" in content
    assert "func handleContinuousCanvasPanDelta(dx: CGFloat, dy: CGFloat, allowsRubberBanding: Bool = true)" in content

def test_app_defaults_migration_variables():
    content = (HELPERS_DIR / "AppDefaultsManager.swift").read_text()
    
    assert "preferenceKeyMigrationMap" in content
    assert "migrateLegacyPreferences" in content
    assert "preferenceValue" in content
    assert '"nexus.dropdownMode": "canvas.dropdownDisplayMode"' in content
    assert '"nexus.isUniverse81Active": "spatial.isUniverse81Active"' in content
    assert '"nexus.extendedDesktopEdgeGlideEnabled": "spatial.isEdgeGlideNavigationEnabled"' in content
