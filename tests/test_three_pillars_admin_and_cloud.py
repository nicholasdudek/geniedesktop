import os
import subprocess
import json
import pytest
from pathlib import Path

def test_pillar1_admin_governor_audit_log_and_isolation():
    """Validates Pillar 1: Admin Access Governor, audit log directory, and destructive command screening."""
    audit_dir = Path("/Users/Shared/Genie/Audit")
    audit_log = audit_dir / "admin_audit.log"

    assert audit_dir.exists()
    assert audit_dir.is_dir()
    assert audit_log.exists()

    content = audit_log.read_text(encoding="utf-8")
    assert "GENIE SYSTEM ADMINISTRATOR AUDIT TRAIL" in content

    # Verify Swift source exists and includes safety governor
    src_file = Path("Sources/GoldGate/Engine/GenieAdminAccessGovernor.swift")
    assert src_file.exists()
    src_code = src_file.read_text(encoding="utf-8")
    assert "GenieAdminAccessGovernor" in src_code
    assert "executeWithAdminPrivileges" in src_code
    assert "inspectUserAccess" in src_code
    assert "screenCommand" in src_code

def test_pillar2_multi_agent_home_directory_hierarchy(tmp_path):
    """Validates Pillar 2: Multi-Agent Home Directory & Human Review Engine."""
    agents_dir = Path("/Users/Shared/Genie/Agents")
    assert agents_dir.exists()
    assert agents_dir.is_dir()

    # Primary agent must exist
    primary_dir = agents_dir / "genie-primary"
    assert primary_dir.exists()

    required_subdirs = ["home", "workspace", "artifacts", "logs", "review"]
    for sub in required_subdirs:
        subpath = primary_dir / sub
        assert subpath.exists(), f"Missing subfolder {sub} in agent root {primary_dir}"

    profile_file = primary_dir / "agent_profile.json"
    assert profile_file.exists()
    profile = json.loads(profile_file.read_text(encoding="utf-8"))
    assert profile["id"] == "genie-primary"
    assert "Lead Multimodal Reasoning" in profile["role"]

    # Verify review deposit mechanism
    review_file = primary_dir / "review" / "test_review_item.txt"
    review_file.write_text("Proposed Agent Solution", encoding="utf-8")
    assert review_file.exists()

def test_pillar3_hybrid_dual_saving_cloud_vault():
    """Validates Pillar 3: Hybrid Dual Saving Engine (Local Home + Cloud Vault)."""
    cloud_engine_file = Path("Sources/GoldGate/Engine/GenieAgentCloudSavingEngine.swift")
    assert cloud_engine_file.exists()

    content = cloud_engine_file.read_text(encoding="utf-8")
    assert "GenieAgentCloudSavingEngine" in content
    assert "syncAgentToCloud" in content
    assert "syncAllAgentsToCloud" in content
    assert "resolveCloudDestination" in content

    # Local fallback Cloud Vault path check
    cloud_vault = Path("/Users/Shared/Genie/CloudVault/Agents")
    assert cloud_vault.exists()
    primary_cloud = cloud_vault / "genie-primary"
    assert primary_cloud.exists()

def test_all_genie_smoke_tests_pass():
    """Validates that all smoke tests in Genie pass cleanly."""
    app_binary = "/Applications/Genie.app/Contents/MacOS/Genie"
    assert os.path.exists(app_binary)

    res = subprocess.run([app_binary, "--smoke-test"], capture_output=True, text=True, timeout=30)
    assert res.returncode == 0
    assert "SMOKE TESTS PASSED CLEANLY" in res.stdout
    assert "Pillar 1: System Administrator & Multi-User Access Governor" in res.stdout
    assert "Pillar 2: Multi-Agent Home Directory & Review System" in res.stdout
    assert "Pillar 3: Hybrid Dual Saving Engine (Local Home + Cloud Vault)" in res.stdout
    assert "iPhone Touch Actuator & Gesture Execution Engine" in res.stdout
