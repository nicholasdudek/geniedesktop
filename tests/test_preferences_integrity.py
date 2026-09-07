import re
from pathlib import Path

APP_DEFAULTS_FILE = Path(__file__).resolve().parents[1] / "Sources/GoldGate/Helpers/AppDefaultsManager.swift"

def test_preference_key_migration_parity():
    """Ensure every migrated key has a non-empty modern key and valid domain namespace."""
    content = APP_DEFAULTS_FILE.read_text()
    
    # Extract preferenceKeyMigrationMap entries
    match = re.search(r"preferenceKeyMigrationMap:\s*\[String:\s*String\]\s*=\s*\[(.*?)\]", content, re.DOTALL)
    assert match is not None, "preferenceKeyMigrationMap not found"
    
    mapping_str = match.group(1)
    pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', mapping_str)
    assert len(pairs) >= 15, f"Expected at least 15 migrated key pairs, found {len(pairs)}"
    
    valid_namespaces = {"canvas", "spatial", "studio", "menuBar", "window", "folderBar", "battery", "audio", "haptics", "visualEffects", "cursor"}
    
    for legacy_key, modern_key in pairs:
        assert legacy_key.startswith("nexus."), f"Legacy key {legacy_key} must start with 'nexus.'"
        prefix = modern_key.split(".")[0]
        assert prefix in valid_namespaces, f"Modern key {modern_key} must have valid namespace, got '{prefix}'"
        assert len(modern_key.split(".")) == 2, f"Modern key {modern_key} must follow 'namespace.attribute' format"
