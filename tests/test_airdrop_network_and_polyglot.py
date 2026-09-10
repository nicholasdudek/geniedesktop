import os
import subprocess
import pytest

SOURCES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Sources", "GoldGate"))
ENGINE_DIR = os.path.join(SOURCES_DIR, "Engine")

def test_airdrop_and_local_network_engine_exists():
    engine_file = os.path.join(ENGINE_DIR, "GenieAirDropAndLocalNetworkEngine.swift")
    assert os.path.exists(engine_file), "GenieAirDropAndLocalNetworkEngine.swift must exist"
    with open(engine_file, "r") as f:
        content = f.read()
    assert "class GenieAirDropAndLocalNetworkEngine" in content
    assert "sendViaAirDrop" in content
    assert "startLocalNetworkServices" in content
    assert "_genie-agent._tcp" in content
    assert "stageFileForAgentNetwork" in content
    assert "/Users/Shared/Genie/Bridge" in content

def test_skills_orchestrator_registers_new_skills():
    skills_file = os.path.join(ENGINE_DIR, "GenieSkillsOrchestrator.swift")
    with open(skills_file, "r") as f:
        content = f.read()
    assert "id: \"airdrop_share\"" in content
    assert "id: \"local_network_share\"" in content
    assert "id: \"app_doc\"" in content
    assert "id: \"polyglot_code\"" in content
    assert "executeAppDocumentation" in content
    assert "executePolyglotCode" in content

def test_local_model_manager_polyglot_and_network_prompts():
    model_mgr_file = os.path.join(ENGINE_DIR, "LocalModelManager.swift")
    with open(model_mgr_file, "r") as f:
        content = f.read()
    assert "POLYGLOT PROGRAMMING & FULL STACK CREATION ENGINE" in content
    assert "NATIVE MACOS AIRDROP & AGENT-TO-AGENT LOCAL NETWORKS" in content
    assert "APPLICATION DOCUMENTATION & SCRIPTING DICTIONARY INSPECTOR" in content
    assert "extractAirDropCommand" in content
    assert "extractAgentNetworkCommand" in content
    assert "extractAppDocCommand" in content

def test_training_script_contains_polyglot_and_vdom_knowledge():
    train_script = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "train_codebase_knowledge.py"))
    with open(train_script, "r") as f:
        content = f.read()
    assert "How does Genie program in all languages to build anything for the user?" in content
    assert "How do Genie agents build local networks to share files from agent to agent?" in content
    assert "How does Genie automate AirDrop on macOS?" in content
    assert "How does Genie access and utilize documentation for all installed applications on macOS?" in content
    assert "Would the backed up code in .backups/vdom_removal_20260907_210015 work now" in content

def test_sdef_utility_on_macos():
    # Verify sdef tool is available and can inspect Finder.app
    finder_path = "/System/Library/CoreServices/Finder.app"
    if not os.path.exists(finder_path):
        finder_path = "/System/Applications/Finder.app"
    
    if os.path.exists(finder_path):
        res = subprocess.run(["/usr/bin/sdef", finder_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        assert res.returncode == 0
        assert "<dictionary" in res.stdout
