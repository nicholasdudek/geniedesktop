#!/usr/bin/env python3
"""
Comprehensive screenshot generator and App Store asset builder for Genie (GoldGate).
Generates 2880x1800 Retina App Store marketing screenshots and updates website assets.
"""

import os
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie")
GOLDGATE_ROOT = REPO_ROOT / "GoldGate"
CAPTURES_DIR = Path("/tmp/genie_captures")

APPSTORE_UPLOADS_DIR = REPO_ROOT / "Marketing" / "Genie_AppStore_Upload_Package" / "Screenshots"
APPSTORE_SUITE_DIR = REPO_ROOT / "Marketing" / "Genie_AppStore_Suite"
WEB_SCREENSHOTS_DIR = GOLDGATE_ROOT / "web" / "assets" / "screenshots"
WEBSITE_IMAGES_DIR = REPO_ROOT / "Marketing" / "GoldGate_Website" / "assets" / "images"

for d in [APPSTORE_UPLOADS_DIR, APPSTORE_SUITE_DIR, WEB_SCREENSHOTS_DIR, WEBSITE_IMAGES_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# 21 Subsystems Inventory
FEATURES = [
    ("01_power_reserve_battery", "01_battery.png", "Power Reserve & Dynamic Battery Telemetry", "Real-time battery metrics, minimal pill styles, charge bolt icons, and color palettes."),
    ("02_atmospheric_murals_shaders", "02_wallpapers.png", "Atmospheric Murals & Live Metal Shaders", "Metal 120 FPS dynamic shaders, 4K aerial wallpapers, and day/night transitions."),
    ("03_atelier_finishes_glass", "03_themes.png", "Atelier Finishes & Vitreous Living Glass", "Frosted translucent glass, Obsidian Velvet, Cyber Horizons, and living themes."),
    ("04_executive_intelligence_ai", "04_ai_models.png", "Executive Intelligence & Local Model Routing", "Integrated local Ollama vision models (genie-master), Gemini 2.5, Claude 3.7, and GPT-4o."),
    ("05_architectural_canvas", "05_workspace.png", "Architectural Canvas & Spatial Plane Engine", "Infinite workspace navigation with 81-screen continuous macro sectors and coordinate mapping."),
    ("06_spatial_formations_geometry", "06_formations.png", "Spatial Formations & Safe Area Geometry", "Geometric layouts: Responsive Grid, Fibonacci Galaxy, Bottom Shelf, Halfpipe Arc, and Dual Column."),
    ("07_application_atelier", "07_applications.png", "Application Atelier & Drag-to-Dock Hub", "Instant drag-and-drop workspace organization, multi-app grouping, and launch controls."),
    ("08_haute_bezels_snuggies", "08_snuggies.png", "Haute Bezels & Notch Snuggies", "Precision window housings, camera notch integration, and custom luxury borders."),
    ("09_haute_typography", "09_typography.png", "Haute Typography, Numerals & Scale Metrics", "Curated font pairings, tabular numerals, text scaling, and typography presets."),
    ("10_kinetic_gestures_inertia", "10_trackpad.png", "Kinetic Gestures, Force Inertia & Shortcuts", "Multi-touch trackpad gestures, momentum scrolling, and custom keyboard triggers."),
    ("11_acoustic_signatures_haptics", "11_sound_haptics.png", "Acoustic Signatures & Force Haptics", "Tactile mechanical audio feedback, Taptic engine responses, and custom soundboards."),
    ("12_grand_horizon_menubar", "12_menubar.png", "Grand Horizon & Inset Floating Status Rail", "Custom floating menu bar replacement with integrated mini dock and quick controls."),
    ("13_spatial_pets_pinball", "13_pets_pinball.png", "Spatial Kinetic Complications, Pets & Physics", "Interactive desktop companions, rigid body physics simulations, and complications."),
    ("14_bespoke_commissions_store", "14_expansion.png", "Bespoke Commissions & Expansion Store", "Extensible add-on marketplace for custom themes, widgets, shaders, and plugins."),
    ("15_security_governance_privacy", "15_privacy.png", "Security Governance & Attestation Hub", "Strict sandboxing, permission gates, zero telemetry leakage, and biometric security."),
    ("16_console_preferences", "16_system.png", "Console Preferences & Unified System Hub", "Global keyboard shortcuts, launch-at-login, GPU performance governors, and system flags."),
    ("17_world_clock_pillows", "17_world_clock.png", "OLED World Clock Pillows & Time Travel", "Blackout cards with specular rim gradients, analog watch faces, alarms, and overlap ribbons."),
    ("18_hypervisor_ai_stations", "18_virtual_machines.png", "Sovereign Hypervisor & Dedicated Linux VMs", "Direct Apple Silicon Virtualization kernel engine with zero-overlap resource partitioning."),
    ("19_chat_dual_tab_preview", "20_chat_and_preview.png", "Genie Chat & Dual-Tab Live Web Studio", "Autonomous desktop AI agent with real-time tool execution, live HTML/CSS preview, and source editor."),
    ("20_system_diagnostics_sentinel", "32_canvas_matrix.png", "Continuous Telemetry & Real-Time Diagnostics", "Zero-investigation sentinel engine tracking parallel threads, memory headroom, and system health."),
    ("21_spatial_desktop_grid", "33_desktop_grid.png", "Spatial Desktop Grid & Split Workspace", "Seamless multi-tasking workspace with embedded chat and split view file inspection.")
]

# 10 Flagship App Store Showcase Sets
APP_STORE_SLIDES = [
    {
        "filename": "01_AppStore_2880x1800_The_Ambient_Awakening_Neural_Bloom.png",
        "title": "THE AMBIENT AWAKENING",
        "subtitle": "Neural Bloom living shaders, spring-animated dropdowns & vitreous frosted glass",
        "capture": "02_wallpapers.png",
        "is_fullscreen": True
    },
    {
        "filename": "02_AppStore_2880x1800_Genie_Editor_Brick_Wall.png",
        "title": "GENIE EDITOR & BRICK WALL",
        "subtitle": "Absolute context isolation firewall & real-time typing convergence meeting at next layer",
        "capture": "20_chat_and_preview.png",
        "is_fullscreen": True
    },
    {
        "filename": "03_AppStore_2880x1800_Living_Animated_Chat_Widget.png",
        "title": "FIRST-EVER ANIMATED CHAT WIDGET",
        "subtitle": "Bioluminescent breathing aura, 5-bar live equalizer waveform & OLED World Clock Pillows",
        "capture": "13_pets_pinball.png",
        "is_fullscreen": False
    },
    {
        "filename": "04_AppStore_2880x1800_Spatial_Desktop_Canvas.png",
        "title": "SPATIAL DESKTOP CANVAS",
        "subtitle": "Reimagine your macOS workspace with continuous 3x3 spatial navigation",
        "capture": "33_desktop_grid.png",
        "is_fullscreen": True
    },
    {
        "filename": "02_AppStore_2880x1800_Genie_Chat_AI_Agent.png",
        "title": "AUTONOMOUS LOCAL AI AGENT",
        "subtitle": "Native vision model reasoning with real-time tools and dual-tab live preview",
        "capture": "20_chat_and_preview.png",
        "is_fullscreen": True
    },
    {
        "filename": "03_AppStore_2880x1800_World_Clock_Pillows.png",
        "title": "WORLD CLOCK PILLOWS",
        "subtitle": "OLED blackout cards, analog sweep hands, time travel scrubber & alarm clock",
        "capture": "17_world_clock.png",
        "is_fullscreen": False
    },
    {
        "filename": "04_AppStore_2880x1800_AI_Stations_Hypervisor.png",
        "title": "SOVEREIGN LINUX HYPERVISOR",
        "subtitle": "Dedicated Apple Silicon virtualization for isolated Linux clones & Spark clusters",
        "capture": "18_virtual_machines.png",
        "is_fullscreen": False
    },
    {
        "filename": "05_AppStore_2880x1800_Living_Themes_Shaders.png",
        "title": "LIVING THEMES & METAL SHADERS",
        "subtitle": "120 FPS Metal fluid dynamics, vitreous glass, and dynamic 4K aerial murals",
        "capture": "02_wallpapers.png",
        "is_fullscreen": False
    },
    {
        "filename": "06_AppStore_2880x1800_Dynamic_Battery_Telemetry.png",
        "title": "DYNAMIC BATTERY TELEMETRY",
        "subtitle": "Minimal pill indicators, live wattage, health metrics, and bespoke status glyphs",
        "capture": "01_battery.png",
        "is_fullscreen": False
    },
    {
        "filename": "07_AppStore_2880x1800_Application_Atelier.png",
        "title": "GEOMETRIC APP FORMATIONS",
        "subtitle": "Responsive Grid, Fibonacci Galaxy, Halfpipe Arc & Bottom Shelf formations",
        "capture": "06_formations.png",
        "is_fullscreen": False
    },
    {
        "filename": "08_AppStore_2880x1800_Window_Housings_Snuggies.png",
        "title": "HAUTE BEZELS & NOTCH SNUGGIES",
        "subtitle": "Luxury window frames, camera notch integration, and tactile sound signatures",
        "capture": "08_snuggies.png",
        "is_fullscreen": False
    },
    {
        "filename": "09_AppStore_2880x1800_Interactive_Widgets_Pets.png",
        "title": "INTERACTIVE WIDGETS & PETS",
        "subtitle": "Desktop companions, 2D physics pinball, and spatial complication cards",
        "capture": "13_pets_pinball.png",
        "is_fullscreen": False
    },
    {
        "filename": "10_AppStore_2880x1800_System_Diagnostics_HUD.png",
        "title": "CONTINUOUS DIAGNOSTICS HUD",
        "subtitle": "Real-time thread sentinel, memory headroom monitoring, and instant telemetry",
        "capture": "32_canvas_matrix.png",
        "is_fullscreen": True
    }
]

def create_app_store_screenshot(slide_info, wallpaper_path: Path, output_path: Path):
    W, H = 2880, 1800
    canvas = Image.new("RGBA", (W, H), (12, 16, 24, 255))

    # 1. Base wallpaper
    if wallpaper_path.exists():
        wp = Image.open(wallpaper_path).convert("RGBA")
        wp_ratio = wp.width / wp.height
        canvas_ratio = W / H
        if wp_ratio > canvas_ratio:
            new_h = H
            new_w = int(H * wp_ratio)
        else:
            new_w = W
            new_h = int(W / wp_ratio)
        wp_resized = wp.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = (new_w - W) // 2
        top = (new_h - H) // 2
        wp_cropped = wp_resized.crop((left, top, left + W, top + H))
        canvas.paste(wp_cropped, (0, 0))

    # 2. Dark vignette overlay for contrast and sleek presentation
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    # Header gradient bar
    for y in range(260):
        alpha = int(220 * (1.0 - (y / 260.0)**1.5))
        ov_draw.line([(0, y), (W, y)], fill=(8, 11, 18, alpha))
    # Bottom subtle vignette
    for y in range(H - 120, H):
        alpha = int(180 * ((y - (H - 120)) / 120.0))
        ov_draw.line([(0, y), (W, y)], fill=(8, 11, 18, alpha))
    canvas = Image.alpha_composite(canvas, overlay)

    # 3. Typography Header (Apple App Store format)
    draw = ImageDraw.Draw(canvas)
    try:
        font_title = ImageFont.truetype("/System/Library/Fonts/SFPro-Bold.otf", 56)
        font_sub = ImageFont.truetype("/System/Library/Fonts/SFPro-Medium.otf", 30)
    except Exception:
        try:
            font_title = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 56)
            font_sub = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 30)
        except Exception:
            font_title = ImageFont.load_default()
            font_sub = ImageFont.load_default()

    title_text = slide_info["title"]
    sub_text = slide_info["subtitle"]

    # Pill badge behind title
    bbox_title = draw.textbbox((0, 0), title_text, font=font_title)
    tw = bbox_title[2] - bbox_title[0]
    th = bbox_title[3] - bbox_title[1]
    tx = (W - tw) // 2
    ty = 60

    # Draw glow & header text
    draw.text((tx, ty), title_text, font=font_title, fill=(255, 255, 255, 255))

    bbox_sub = draw.textbbox((0, 0), sub_text, font=font_sub)
    sw = bbox_sub[2] - bbox_sub[0]
    sx = (W - sw) // 2
    sy = ty + th + 24
    draw.text((sx, sy), sub_text, font=font_sub, fill=(200, 215, 235, 240))

    # 4. Feature Screenshot Placement
    cap_path = CAPTURES_DIR / slide_info["capture"]
    if cap_path.exists():
        cap_img = Image.open(cap_path).convert("RGBA")
        if slide_info["is_fullscreen"]:
            # Desktop view: scale to fit beautifully with rounded border & shadow
            target_w = 2520
            scale = target_w / cap_img.width
            target_h = int(cap_img.height * scale)
            if target_h > 1460:
                target_h = 1460
                scale = target_h / cap_img.height
                target_w = int(cap_img.width * scale)

            cap_resized = cap_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
            
            # Create drop shadow
            shadow_pad = 40
            shadow_canvas = Image.new("RGBA", (target_w + shadow_pad * 2, target_h + shadow_pad * 2), (0, 0, 0, 0))
            s_draw = ImageDraw.Draw(shadow_canvas)
            s_draw.rounded_rectangle([shadow_pad, shadow_pad + 12, shadow_pad + target_w, shadow_pad + target_h + 12], radius=24, fill=(0, 0, 0, 160))
            shadow_blurred = shadow_canvas.filter(ImageFilter.GaussianBlur(24))

            # Mask rounded corners on screenshot
            mask = Image.new("L", (target_w, target_h), 0)
            m_draw = ImageDraw.Draw(mask)
            m_draw.rounded_rectangle([0, 0, target_w, target_h], radius=24, fill=255)

            px = (W - target_w) // 2
            py = 230 + (H - 230 - target_h) // 2

            canvas.paste(shadow_blurred, (px - shadow_pad, py - shadow_pad), shadow_blurred)
            canvas.paste(cap_resized, (px, py), mask)

            # Elegant border
            border_draw = ImageDraw.Draw(canvas)
            border_draw.rounded_rectangle([px, py, px + target_w, py + target_h], radius=24, outline=(255, 255, 255, 50), width=2)
        else:
            # Floating panel view: center elegantly with rich shadow
            # Target size: 2000px wide (or natural scale)
            target_w = min(2100, int(cap_img.width * 1.15))
            scale = target_w / cap_img.width
            target_h = int(cap_img.height * scale)

            if target_h > 1380:
                target_h = 1380
                scale = target_h / cap_img.height
                target_w = int(cap_img.width * scale)

            cap_resized = cap_img.resize((target_w, target_h), Image.Resampling.LANCZOS)

            shadow_pad = 60
            shadow_canvas = Image.new("RGBA", (target_w + shadow_pad * 2, target_h + shadow_pad * 2), (0, 0, 0, 0))
            s_draw = ImageDraw.Draw(shadow_canvas)
            s_draw.rounded_rectangle([shadow_pad, shadow_pad + 16, shadow_pad + target_w, shadow_pad + target_h + 16], radius=32, fill=(0, 0, 0, 190))
            shadow_blurred = shadow_canvas.filter(ImageFilter.GaussianBlur(36))

            mask = Image.new("L", (target_w, target_h), 0)
            m_draw = ImageDraw.Draw(mask)
            m_draw.rounded_rectangle([0, 0, target_w, target_h], radius=32, fill=255)

            px = (W - target_w) // 2
            py = 220 + (H - 220 - target_h) // 2

            canvas.paste(shadow_blurred, (px - shadow_pad, py - shadow_pad), shadow_blurred)
            canvas.paste(cap_resized, (px, py), mask)

            border_draw = ImageDraw.Draw(canvas)
            border_draw.rounded_rectangle([px, py, px + target_w, py + target_h], radius=32, outline=(244, 195, 117, 80), width=2)

    canvas.convert("RGB").save(output_path, "PNG", optimize=True)
    print(f"  ✓ Built App Store Screenshot: {output_path.name} (2880x1800)")

def main():
    print("==================================================")
    print("  GENIE APP STORE & WEBSITE ASSETS SUITE BUILDER")
    print("==================================================")

    # 1. Copy raw captures to web/assets/screenshots and Marketing/GoldGate_Website
    print("\n[Phase 1/3] Publishing raw feature screenshots to website asset directories...")
    for slug, cap_file, title, desc in FEATURES:
        src = CAPTURES_DIR / cap_file
        if src.exists():
            dest_web = WEB_SCREENSHOTS_DIR / f"{slug}.png"
            dest_mkt = WEBSITE_IMAGES_DIR / f"{slug}.png"
            shutil.copy2(src, dest_web)
            shutil.copy2(src, dest_mkt)
            print(f"  ✓ {slug}.png ({src.stat().st_size // 1024} KB)")

    # 2. Build 10 Flagship 2880x1800 App Store Screenshots
    print("\n[Phase 2/3] Generating 10 Retina 2880x1800 App Store Showcase Screenshots...")
    wp_path = GOLDGATE_ROOT / "build" / "DirectRelease" / "Genie.app" / "Contents" / "Resources" / "Wallpapers" / "GoldenGateDynamic.jpg"
    if not wp_path.exists():
        wp_path = GOLDGATE_ROOT / "web" / "assets" / "wallpapers" / "GoldenGateDynamic.jpg"

    for slide in APP_STORE_SLIDES:
        out_pkg = APPSTORE_UPLOADS_DIR / slide["filename"]
        out_suite = APPSTORE_SUITE_DIR / slide["filename"]
        create_app_store_screenshot(slide, wp_path, out_pkg)
        shutil.copy2(out_pkg, out_suite)

    # 3. Create canonical short names for AppStore Suite
    suite_mappings = {
        "Apps.png": "01_AppStore_2880x1800_Spatial_Desktop_Canvas.png",
        "Desktop.png": "01_AppStore_2880x1800_Spatial_Desktop_Canvas.png",
        "Themes.png": "05_AppStore_2880x1800_Living_Themes_Shaders.png",
        "Formations.png": "07_AppStore_2880x1800_Application_Atelier.png",
        "Status_Bar.png": "06_AppStore_2880x1800_Dynamic_Battery_Telemetry.png",
        "General.png": "02_AppStore_2880x1800_Genie_Chat_AI_Agent.png",
        "Wallpaper.png": "05_AppStore_2880x1800_Living_Themes_Shaders.png",
        "Entities___Pets.png": "09_AppStore_2880x1800_Interactive_Widgets_Pets.png",
        "Sounds.png": "08_AppStore_2880x1800_Window_Housings_Snuggies.png",
        "VIP_Packs.png": "04_AppStore_2880x1800_AI_Stations_Hypervisor.png",
        "Motion___FX.png": "05_AppStore_2880x1800_Living_Themes_Shaders.png",
        "Mouse___Trails.png": "10_AppStore_2880x1800_System_Diagnostics_HUD.png",
    }
    for alias, canonical in suite_mappings.items():
        src = APPSTORE_SUITE_DIR / canonical
        if src.exists():
            shutil.copy2(src, APPSTORE_SUITE_DIR / alias)

    print("\n[Phase 3/3] App Store & Website assets updated successfully!")
    print(f"  • App Store Upload Package: {len(list(APPSTORE_UPLOADS_DIR.glob('*.png')))} images")
    print(f"  • Marketing Suite: {len(list(APPSTORE_SUITE_DIR.glob('*.png')))} images")
    print(f"  • Web Assets: {len(list(WEB_SCREENSHOTS_DIR.glob('*.png')))} images")

if __name__ == "__main__":
    main()
