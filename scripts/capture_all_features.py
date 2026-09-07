#!/usr/bin/env python3
"""
Automated feature walkthrough, screenshot capture, and recording generator for Genie.
Orchestrates UI navigation across all 18 flagship subsystems via DistributedNotificationCenter
and system IPC, capturing pixel-perfect isolated window snapshots and screen recordings.
"""

import os
import sys
import time
import subprocess
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS_DIR = REPO_ROOT / "Artifacts" / "Screenshots"
RECORDINGS_DIR = REPO_ROOT / "Artifacts" / "Recordings"
ARTIFACT_DIR = Path("/Users/nicholasdudek/.gemini/antigravity-cli/brain/c161c71c-b2b7-40b8-ab13-286c1b1970d6")
ARTIFACT_IMG_DIR = ARTIFACT_DIR / "screenshots"

SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
RECORDINGS_DIR.mkdir(parents=True, exist_ok=True)
ARTIFACT_IMG_DIR.mkdir(parents=True, exist_ok=True)

# 16 Control Center / Settings tabs in Genie
TABS = [
    ("01_power_reserve_battery", "Power Reserve & Dynamic Battery Telemetry", "Battery"),
    ("02_atmospheric_murals_shaders", "Atmospheric Murals & Live Metal Shaders", "Wallpapers"),
    ("03_atelier_finishes_glass", "Atelier Finishes & Vitreous Glass Themes", "Themes"),
    ("04_executive_intelligence_ai", "Executive Intelligence & Neural Local Models", "AI"),
    ("05_architectural_canvas", "Architectural Canvas & Spatial Plane Engine", "Workspace"),
    ("06_spatial_formations_geometry", "Spatial Formations & 14\" Safe Area Split", "Formations"),
    ("07_application_atelier", "Application Atelier & Drag-to-Dock Hub", "Applications"),
    ("08_haute_bezels_snuggies", "Haute Bezels, Housings & Notch Snuggies", "Snuggies"),
    ("09_haute_typography", "Haute Typography, Numerals & Scale Metrics", "Typography"),
    ("10_kinetic_gestures_inertia", "Kinetic Gestures, Force Inertia & Hot Corners", "Gestures"),
    ("11_acoustic_signatures_haptics", "Acoustic Signatures & Force Haptics", "Sound"),
    ("12_grand_horizon_menubar", "Grand Horizon & Inset Floating Status Rail", "MenuBar"),
    ("13_spatial_pets_pinball", "Spatial Kinetic Complications, Pets & Physics", "Pets"),
    ("14_bespoke_commissions_store", "Bespoke Commissions & Expansion Store", "Expansion"),
    ("15_security_governance_privacy", "Security Governance & Attestation Hub", "Privacy"),
    ("16_console_preferences", "Console Preferences & Unified System Hub", "System"),
]

def run_swift(code: str):
    p = subprocess.run(["swift", "-"], input=code, text=True, capture_output=True)
    return p.stdout.strip()

def post_tab(tab_name: str):
    swift = f"""
    import Foundation
    let dnc = DistributedNotificationCenter.default()
    dnc.postNotificationName(
        NSNotification.Name("com.user.nexus.tab"),
        object: "{tab_name}",
        userInfo: nil,
        deliverImmediately: true
    )
    """
    run_swift(swift)

def get_genie_window_id() -> int:
    swift = r"""
    import Cocoa
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    if let winList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
        for win in winList {
            let owner = win[kCGWindowOwnerName as String] as? String ?? ""
            let wid = win[kCGWindowNumber as String] as? CGWindowID ?? 0
            let layer = win[kCGWindowLayer as String] as? Int ?? -1
            if owner.contains("Genie") && layer > 10 {
                print("\(wid)")
                break
            }
        }
    }
    """
    out = run_swift(swift)
    try:
        return int(out.splitlines()[-1])
    except Exception:
        return 0

def capture_window(wid: int, target_path: Path):
    subprocess.run(["/usr/sbin/screencapture", "-l", str(wid), "-o", str(target_path)], check=True)

def capture_fullscreen(target_path: Path):
    subprocess.run(["/usr/sbin/screencapture", "-x", "-m", str(target_path)], check=True)

def trigger_ipc(cmd: str):
    trigger = Path(os.path.expanduser("~/.gemini/genie_action.trigger"))
    trigger.parent.mkdir(parents=True, exist_ok=True)
    trigger.write_text(cmd, encoding="utf-8")

def main():
    print("==================================================")
    print("  GENIE FLAGSHIP FEATURES CAPTURE & RECORDING PIPELINE")
    print("==================================================")

    # 1. Capture all 16 Control Center Feature Tabs
    print("\n[Phase 1/3] Capturing 16 Control Center Feature Panels...")
    captured_tabs = []

    for slug, title, tab in TABS:
        print(f"  --> Activating Tab: {tab} ({title})...")
        post_tab(tab)
        time.sleep(0.9)  # Allow SwiftUI transitions to settle

        wid = get_genie_window_id()
        if wid > 0:
            png_repo = SCREENSHOTS_DIR / f"{slug}.png"
            capture_window(wid, png_repo)

            png_artifact = ARTIFACT_IMG_DIR / f"{slug}.png"
            shutil.copy2(png_repo, png_artifact)

            captured_tabs.append((slug, title, png_repo, png_artifact))
            print(f"      ✓ Captured Window ID {wid} -> {png_repo.name} ({png_repo.stat().st_size // 1024} KB)")
        else:
            print(f"      ⚠ Could not locate Genie window for {tab}")

    # 2. Capture Spatial Matrix 3x3 Overview (Fullscreen Canvas)
    print("\n[Phase 2/3] Capturing 3x3 Spatial Overview Grid...")
    trigger_ipc("canvas")
    time.sleep(1.8)

    canvas_slug = "17_spatial_3x3_matrix_overview"
    canvas_repo = SCREENSHOTS_DIR / f"{canvas_slug}.png"
    capture_fullscreen(canvas_repo)
    canvas_artifact = ARTIFACT_IMG_DIR / f"{canvas_slug}.png"
    shutil.copy2(canvas_repo, canvas_artifact)
    print(f"      ✓ Captured 3x3 Spatial Matrix -> {canvas_repo.name} ({canvas_repo.stat().st_size // 1024} KB)")

    # Land back into home slot
    trigger_ipc("land 5")
    time.sleep(1.2)

    # 3. Capture Desktop Dialogue Studio (Page 1)
    print("\n[Phase 2b/3] Capturing Desktop Dialogue Studio & Omni Search...")
    run_swift("""
    import Foundation
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("com.user.nexus.grid"),
        object: nil, userInfo: nil, deliverImmediately: true
    )
    """)
    time.sleep(1.5)
    studio_slug = "18_dialogue_studio_omni_search"
    studio_repo = SCREENSHOTS_DIR / f"{studio_slug}.png"
    capture_fullscreen(studio_repo)
    studio_artifact = ARTIFACT_IMG_DIR / f"{studio_slug}.png"
    shutil.copy2(studio_repo, studio_artifact)
    print(f"      ✓ Captured Dialogue Studio -> {studio_repo.name} ({studio_repo.stat().st_size // 1024} KB)")

    # Dismiss grid
    run_swift("""
    import Foundation
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("com.user.nexus.grid"),
        object: nil, userInfo: nil, deliverImmediately: true
    )
    """)
    time.sleep(1.0)

    # 4. Record Dynamic Video Walkthroughs
    print("\n[Phase 3/3] Recording Live Dynamic Screen Walkthroughs...")
    
    # Video 1: Control Center Showcase
    vid1_path = RECORDINGS_DIR / "Genie_Control_Center_Walkthrough.mov"
    print(f"  --> Recording Video 1: Control Center Showcase to {vid1_path.name}...")
    rec1 = subprocess.Popen(["/usr/sbin/screencapture", "-v", str(vid1_path)])
    time.sleep(1.0)

    demo_tabs = ["Battery", "Wallpapers", "Themes", "AI", "Formations", "Typography", "Pets", "Applications"]
    for t in demo_tabs:
        post_tab(t)
        time.sleep(1.4)

    rec1.send_signal(subprocess.signal.SIGINT)
    try:
        rec1.wait(timeout=6)
    except Exception:
        rec1.terminate()
    print(f"      ✓ Finalized {vid1_path.name} ({vid1_path.stat().st_size // 1024} KB)")
    if vid1_path.exists():
        shutil.copy2(vid1_path, ARTIFACT_DIR / vid1_path.name)

    # Video 2: Spatial Canvas & 3x3 Zoom Walkthrough
    vid2_path = RECORDINGS_DIR / "Genie_Spatial_Canvas_Walkthrough.mov"
    print(f"  --> Recording Video 2: Spatial Matrix & 3x3 Zoom to {vid2_path.name}...")
    rec2 = subprocess.Popen(["/usr/sbin/screencapture", "-v", str(vid2_path)])
    time.sleep(1.0)

    # Toggle canvas zoom out
    trigger_ipc("canvas")
    time.sleep(2.5)
    # Pan across canvas
    trigger_ipc("pan 200 0")
    time.sleep(1.5)
    trigger_ipc("pan -200 0")
    time.sleep(1.5)
    # Land back
    trigger_ipc("land 5")
    time.sleep(2.0)

    rec2.send_signal(subprocess.signal.SIGINT)
    try:
        rec2.wait(timeout=6)
    except Exception:
        rec2.terminate()
    print(f"      ✓ Finalized {vid2_path.name} ({vid2_path.stat().st_size // 1024} KB)")
    if vid2_path.exists():
        shutil.copy2(vid2_path, ARTIFACT_DIR / vid2_path.name)

    print("\n==================================================")
    print(f"✓ CAPTURE PIPELINE COMPLETE: {len(captured_tabs) + 2} Screenshots & 2 Video Recordings!")
    print("==================================================")

if __name__ == "__main__":
    main()
