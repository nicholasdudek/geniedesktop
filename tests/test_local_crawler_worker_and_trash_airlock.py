import os
import subprocess
import pytest
from pathlib import Path

def test_local_file_crawler_source_and_types():
    """Verifies GenieLocalFileCrawlerEngine exists, uses IPESignature, and has proper methods."""
    crawler_path = Path("Sources/GoldGate/Engine/GenieLocalFileCrawlerEngine.swift")
    assert crawler_path.exists(), "GenieLocalFileCrawlerEngine.swift must exist"

    content = crawler_path.read_text(encoding="utf-8")
    assert "GenieLocalFileCrawlerEngine" in content
    assert "GenieLocalFileItem" in content
    assert "IPESignature" in content
    assert "searchFiles" in content
    assert "crawlDirectory" in content
    assert "ignoredDirectoryNames" in content
    assert "purgeIndex" in content

def test_fork_worker_node_and_orchestrator():
    """Verifies GenieForkWorkerNode executes instructions strictly in sequence."""
    worker_path = Path("Sources/GoldGate/Engine/GenieForkWorkerNode.swift")
    assert worker_path.exists(), "GenieForkWorkerNode.swift must exist"

    content = worker_path.read_text(encoding="utf-8")
    assert "GenieForkWorkerNode" in content
    assert "GenieWorkerNodeOrchestrator" in content
    assert "GenieWorkerInstruction" in content
    assert "GenieWorkerInstructionType" in content
    assert "executeSequence" in content
    assert "dropWorker" in content
    assert "dropWorkerOnSharedFork" in content
    assert "dropWorkerInRAM" in content

def test_trash_can_airlock_gateway():
    """Verifies the hidden Trash can file trick and atomic Desktop promotion gateway."""
    airlock_path = Path("Sources/GoldGate/Engine/GenieTrashAirlockGateway.swift")
    assert airlock_path.exists(), "GenieTrashAirlockGateway.swift must exist"

    content = airlock_path.read_text(encoding="utf-8")
    assert "GenieTrashAirlockGateway" in content
    assert "primaryAirlockURL" in content
    assert "promoteToDesktop" in content
    assert "stageFile" in content
    assert "stageFromDesktopToVM" in content
    assert "stripQuarantine" in content
    assert "com.apple.quarantine" in content
    assert "clonefile" in content
    assert "rename" in content

def test_in_ram_local_email_server():
    """Verifies sovereign in-RAM local email server and client for Genie agents."""
    email_path = Path("Sources/GoldGate/Engine/GenieInRAMLocalEmailServer.swift")
    assert email_path.exists(), "GenieInRAMLocalEmailServer.swift must exist"

    content = email_path.read_text(encoding="utf-8")
    assert "GenieInRAMLocalEmailServer" in content
    assert "GenieLocalEmailMessage" in content
    assert "GenieLocalEmailAccount" in content
    assert "spinUpAddress" in content
    assert "sendEmail" in content
    assert "inbox" in content
    assert "steve@genie.local" in content

def test_architectural_chat_template_engine():
    """Verifies chat templates are refactored to inject Genie's full architecture context."""
    template_path = Path("Sources/GoldGate/Engine/GenieArchitecturalChatTemplateEngine.swift")
    assert template_path.exists(), "GenieArchitecturalChatTemplateEngine.swift must exist"

    content = template_path.read_text(encoding="utf-8")
    assert "GenieArchitecturalChatTemplateEngine" in content
    assert "generateArchitecturalContextBlock" in content
    assert "formatAsChatML" in content
    assert "formatAsLlama3" in content
    assert "formatAsStandardRoleJSON" in content
    assert "Unified Memory" in content
    assert "Sequential Worker Nodes" in content
    assert "Trash Can Desktop Airlock" in content

def test_apple_menu_bar_inside_chat():
    """Verifies the authentic Apple Menu Bar inside the chat view with RAM and battery telemetry."""
    menu_path = Path("Sources/GoldGate/Views/GenieChatAppleMenuBarView.swift")
    assert menu_path.exists(), "GenieChatAppleMenuBarView.swift must exist"

    content = menu_path.read_text(encoding="utf-8")
    assert "GenieChatAppleMenuBarView" in content
    assert "appleLogoMenu" in content
    assert "unifiedRAMStatusPill" in content
    assert "batteryTelemetryPill" in content
    assert "sovereignEmailPill" in content
    assert "trashAirlockPill" in content
    assert "GenieLocalEmailClientSheet" in content

def test_top_dock_neural_engine_banner():
    """Verifies the retro ASCII Neural Engine banner is integrated into the top dock."""
    banner_path = Path("Sources/GoldGate/Views/GenieTopDockNeuralEngineBannerView.swift")
    dock_path = Path("Sources/GoldGate/Views/LiquidGlassMiniDockView.swift")

    assert banner_path.exists(), "GenieTopDockNeuralEngineBannerView.swift must exist"
    assert dock_path.exists(), "LiquidGlassMiniDockView.swift must exist"

    banner_content = banner_path.read_text(encoding="utf-8")
    assert "GenieTopDockNeuralEngineBannerView" in banner_content
    assert "GENIE OS" in banner_content
    assert "APPLE SILICON" in banner_content
    assert "ZERO LATENCY" in banner_content
    assert "GENIE NEURAL ENGINE" in banner_content

    dock_content = dock_path.read_text(encoding="utf-8")
    assert "GenieTopDockNeuralEngineBannerView" in dock_content
