#!/usr/bin/env python3
"""
build_all_feature_previews.py
Generates the 3 flagship Apple App Store Previews showcasing ALL 10 subsystems
of Genie Build 500 across three 29-second 1080p cinematic video sequences.

Outputs:
- 1080p H.264/AAC MP4s for App Store Connect (1920x1080, 29.0s)
- High-res animated showcase WebP and GIFs for Web & GitHub
- High-resolution poster thumbnails
"""

import os
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie")
GOLDGATE_ROOT = REPO_ROOT / "GoldGate"
WALLPAPERS_DIR = GOLDGATE_ROOT / "Wallpapers"
SCREENSHOTS_DIR = GOLDGATE_ROOT / "web" / "assets" / "screenshots"

OUT_APPSTORE_VIDS = REPO_ROOT / "Marketing" / "AppStore_Connect_Assets" / "App_Store_Connect_Uploads_Build14" / "2_App_Preview_Videos_1080p"
OUT_MKT_VIDS = REPO_ROOT / "Marketing" / "Opening_App_Previews"
OUT_WEB_VIDS = GOLDGATE_ROOT / "web" / "assets" / "previews"
ROOT_VIDS = GOLDGATE_ROOT / "assets" / "video"
ROOT_PREVIEWS = GOLDGATE_ROOT / "assets" / "previews"

for d in [OUT_APPSTORE_VIDS, OUT_MKT_VIDS, OUT_WEB_VIDS, ROOT_VIDS, ROOT_PREVIEWS]:
    d.mkdir(parents=True, exist_ok=True)

TEMP_FRAMES = Path("/tmp/genie_multi_preview_frames")
TEMP_FRAMES.mkdir(parents=True, exist_ok=True)

PREVIEWS = [
    {
        "id": "1",
        "name": "App_Preview_1_Spatial_Canvas_1080p",
        "title": "AUTONOMOUS OS & SPATIAL CANVAS",
        "subtitle": "Genie Build 500 — Intelligent Automation & Infinite Workspace",
        "bg_wallpaper": "GenieAerial4K.jpg",
        "accent": (244, 195, 117), # Champagne Gold
        "outro_text": "SOVEREIGN AGENT & SPATIAL MATRIX",
        "chapters": [
            {
                "feature": "AUTONOMOUS OS AGENT",
                "callout": "CoreGraphics & 19 Shadow Tools",
                "capture": "04_executive_intelligence_ai.png",
                "pills": ["CGEvent Mouse & Keyboard", "AXUIElement Tree", "Autonomous Reasoning"],
                "duration": 7.5
            },
            {
                "feature": "81-SCREEN SPATIAL MATRIX",
                "callout": "Continuous Multi-Space Plane",
                "capture": "21_spatial_desktop_grid.png",
                "pills": ["81-Screen Universe", "Frustum Culled", "Sub-35MB RAM"],
                "duration": 7.5
            },
            {
                "feature": "APPLICATION ATELIER",
                "callout": "Fibonacci Galaxy & Formations",
                "capture": "07_application_atelier.png",
                "pills": ["Fibonacci Spiral", "Floating Lotus", "Drag-to-Dock Hub"],
                "duration": 7.5
            }
        ]
    },
    {
        "id": "2",
        "name": "App_Preview_2_Living_Themes_1080p",
        "title": "DUO FOLD STUDIO & LIVING THEMES",
        "subtitle": "Genie Build 500 — Dual-Pane Web Studio & 120 FPS Metal Shaders",
        "bg_wallpaper": "GoldenGateSunset.jpg",
        "accent": (96, 165, 250), # Electric Blue
        "outro_text": "LIQUID GLASS & METAL SHADERS",
        "chapters": [
            {
                "feature": "DUO FOLD CODE STUDIO",
                "callout": "Live WebKit Code Synthesis",
                "capture": "19_chat_dual_tab_preview.png",
                "pills": ["Vision-Guided Agent", "Live HTML/CSS Preview", "Instant Code Sync"],
                "duration": 7.5
            },
            {
                "feature": "LIVING THEMES & METAL SHADERS",
                "callout": "120 FPS Fluid MSL Dynamics",
                "capture": "02_atmospheric_murals_shaders.png",
                "pills": ["Metal 3 Shaders", "Vitreous Liquid Glass", "Day/Night Transitions"],
                "duration": 7.5
            },
            {
                "feature": "22 PT MINI DOCK & DANCE TO MUSIC",
                "callout": "CoreAudio Beat Synchronization",
                "capture": "19_app_matrix_dance_to_music.png",
                "pills": ["Retina Magnification", "Micro Smoke Particles", "124 BPM Audio Groove"],
                "duration": 7.5
            }
        ]
    },
    {
        "id": "3",
        "name": "App_Preview_3_Formations_And_Controls_1080p",
        "title": "IN-RAM HYPERVISOR & HARDWARE SENTINEL",
        "subtitle": "Genie Build 500 — Linux Micro-Clones & Hardware Telemetry",
        "bg_wallpaper": "SonomaHorizon.jpg",
        "accent": (52, 211, 153), # Emerald Green
        "outro_text": "SOVEREIGN IN-RAM HYPERVISOR",
        "chapters": [
            {
                "feature": "IN-RAM LINUX HYPERVISOR",
                "callout": "Apple Silicon Kernel Virtualization",
                "capture": "18_hypervisor_ai_stations.png",
                "pills": ["Zero-Latency Virtio-FS", "In-Memory Linux Swarms", "Instant Ollama Bridge"],
                "duration": 7.5
            },
            {
                "feature": "OLED WORLD CLOCK PILLOWS",
                "callout": "Specular Blackout Rim Cards",
                "capture": "17_world_clock_pillows.png",
                "pills": ["Analog Sweep Hands", "Multi-Zone Alarms", "Time Travel Scrubber"],
                "duration": 7.5
            },
            {
                "feature": "DYNAMIC BATTERY & SYSTEM SENTINEL",
                "callout": "SMC Wattage Draw & Thermal Guard",
                "capture": "01_power_reserve_battery.png",
                "pills": ["Live Wattage Draw", "Clamshell Stay-Awake", "Overheat Guard HUD"],
                "duration": 7.5
            }
        ]
    }
]

def load_fonts():
    font_path = "/System/Library/Fonts/HelveticaNeue.ttc"
    try:
        f_hero = ImageFont.truetype(font_path, 44, index=1)
        f_title = ImageFont.truetype(font_path, 34, index=1)
        f_sub = ImageFont.truetype(font_path, 22, index=10)
        f_pill = ImageFont.truetype(font_path, 16, index=10)
        f_badge = ImageFont.truetype(font_path, 14, index=1)
        f_callout = ImageFont.truetype(font_path, 20, index=1)
    except Exception:
        default = ImageFont.load_default()
        return default, default, default, default, default, default
    return f_hero, f_title, f_sub, f_pill, f_badge, f_callout

def build_feature_scene(W, H, bg_img, chapter, preview_info, f_title, f_callout, f_pill):
    s = bg_img.copy()
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 110))
    s = Image.alpha_composite(s, ov)
    d = ImageDraw.Draw(s)
    accent = preview_info["accent"]

    # Header HUD bar
    d.rounded_rectangle([180, 26, W - 180, 88], radius=18, fill=(12, 18, 30, 230), outline=(accent[0], accent[1], accent[2], 140), width=2)
    d.text((216, 40), f"GENIE 4.0 • {chapter['feature']}", font=f_title, fill=(255, 255, 255))
    d.text((W - 620, 44), chapter["callout"], font=f_callout, fill=accent)

    # Capture image
    cap_path = SCREENSHOTS_DIR / chapter["capture"]
    if cap_path.exists():
        cap_img = Image.open(cap_path).convert("RGBA")
        target_cap_w = 1580
        target_cap_h = int(cap_img.height * (target_cap_w / cap_img.width))
        if target_cap_h > 800:
            target_cap_h = 800
            target_cap_w = int(cap_img.width * (target_cap_h / cap_img.height))
        cap_scaled = cap_img.resize((target_cap_w, target_cap_h), Image.Resampling.LANCZOS)

        mask = Image.new("L", (target_cap_w, target_cap_h), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.rounded_rectangle([0, 0, target_cap_w, target_cap_h], radius=22, fill=255)

        px = (W - target_cap_w) // 2
        py = 106 + (H - 106 - 76 - target_cap_h) // 2
        s.paste(cap_scaled, (px, py), mask)
        d.rounded_rectangle([px, py, px + target_cap_w, py + target_cap_h], radius=22, outline=(accent[0], accent[1], accent[2], 120), width=2)

    # Bottom pill badges
    p_x = 210
    p_y = H - 68
    for p in chapter.get("pills", []):
        bb = d.textbbox((0, 0), p, font=f_pill)
        pw = bb[2] - bb[0] + 36
        d.rounded_rectangle([p_x, p_y, p_x + pw, p_y + 34], radius=17, fill=(15, 23, 42, 230), outline=(255, 255, 255, 70), width=1)
        d.ellipse([p_x + 12, p_y + 13, p_x + 20, p_y + 21], fill=accent)
        d.text((p_x + 28, p_y + 8), p, font=f_pill, fill=(241, 245, 249))
        p_x += pw + 18

    return s

def generate_preview_clip(preview_info):
    name = preview_info["name"]
    print(f"\n--> Rendering Comprehensive Preview: {name}...")
    f_hero, f_title, f_sub, f_pill, f_badge, f_callout = load_fonts()

    W, H = 1920, 1080
    bg_path = WALLPAPERS_DIR / preview_info["bg_wallpaper"]
    bg_img = Image.open(bg_path).convert("RGBA").resize((W, H), Image.Resampling.LANCZOS)
    accent = preview_info["accent"]

    scenes = []

    # 1. Intro Slate (2.5s)
    s_intro = bg_img.copy()
    ov_intro = Image.new("RGBA", (W, H), (8, 12, 22, 225))
    s_intro = Image.alpha_composite(s_intro, ov_intro)
    d_intro = ImageDraw.Draw(s_intro)

    d_intro.rounded_rectangle([740, 340, 1180, 395], radius=27, fill=(18, 26, 44, 235), outline=accent, width=2)
    d_intro.text((790, 356), "GENIE 4.0 // BUILD 500", font=f_badge, fill=accent)

    t_bb = d_intro.textbbox((0, 0), preview_info["title"], font=f_hero)
    d_intro.text(((W - (t_bb[2] - t_bb[0])) // 2, 430), preview_info["title"], font=f_hero, fill=(255, 255, 255))

    s_bb = d_intro.textbbox((0, 0), preview_info["subtitle"], font=f_sub)
    d_intro.text(((W - (s_bb[2] - s_bb[0])) // 2, 510), preview_info["subtitle"], font=f_sub, fill=(203, 213, 225, 240))
    scenes.append((s_intro, 2.5))

    # 2. Chapters (7.5s each = 22.5s)
    for ch in preview_info["chapters"]:
        ch_scene = build_feature_scene(W, H, bg_img, ch, preview_info, f_title, f_callout, f_pill)
        scenes.append((ch_scene, ch["duration"]))

    # 3. Outro Slate (4.0s) -> Total = 2.5 + 22.5 + 4.0 = 29.0s!
    s_outro = bg_img.copy()
    ov_outro = Image.new("RGBA", (W, H), (8, 12, 22, 235))
    s_outro = Image.alpha_composite(s_outro, ov_outro)
    d_outro = ImageDraw.Draw(s_outro)

    d_outro.text((W // 2 - 180, 380), "GENIE", font=f_hero, fill=accent)
    d_outro.text((W // 2 - 320, 460), preview_info["outro_text"], font=f_sub, fill=(255, 255, 255))

    d_outro.rounded_rectangle([660, 560, 1260, 624], radius=22, fill=(22, 32, 54, 235), outline=accent, width=2)
    d_outro.text((710, 580), "100% NATIVE SWIFT & METAL • ZERO TELEMETRY", font=f_badge, fill=accent)
    scenes.append((s_outro, 4.0))

    # Save frames to temp directory
    frame_files = []
    for i, (sc, dur) in enumerate(scenes):
        fpath = TEMP_FRAMES / f"scene_{preview_info['id']}_{i}.png"
        sc.convert("RGB").save(fpath, "PNG")
        frame_files.append((fpath, dur))

    # Concat file for ffmpeg
    concat_txt = TEMP_FRAMES / f"concat_{preview_info['id']}.txt"
    with open(concat_txt, "w") as f:
        for fpath, dur in frame_files:
            f.write(f"file '{fpath}'\nduration {dur}\n")
        f.write(f"file '{frame_files[-1][0]}'\n")

    # Render MP4 via ffmpeg
    out_mp4_appstore = OUT_APPSTORE_VIDS / f"{name}.mp4"
    out_mp4_mkt = OUT_MKT_VIDS / f"{name}.mp4"
    out_mp4_web = OUT_WEB_VIDS / f"{name}.mp4"
    out_mp4_root = ROOT_VIDS / f"{name}.mp4"
    out_mp4_root_prev = ROOT_PREVIEWS / f"{name}.mp4"

    cmd = [
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", str(concat_txt),
        "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
        "-vf", "fps=30,scale=1920:1080:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-profile:v", "main", "-pix_fmt", "yuv420p", "-b:v", "6500k",
        "-c:a", "aac", "-b:a", "192k",
        "-t", "29.0",
        "-movflags", "+faststart",
        str(out_mp4_appstore)
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Sync to all output directories
    for dest in [out_mp4_mkt, out_mp4_web, out_mp4_root, out_mp4_root_prev]:
        dest.write_bytes(out_mp4_appstore.read_bytes())

    # Generate WebP & GIF loop
    out_webp = OUT_MKT_VIDS / f"{name}.webp"
    cmd_webp = [
        "ffmpeg", "-y",
        "-i", str(out_mp4_appstore),
        "-vf", "fps=15,scale=960:540:flags=lanczos",
        "-vcodec", "libwebp", "-lossless", "0", "-compression_level", "4", "-q:v", "75", "-loop", "0",
        "-t", "10.0",
        str(out_webp)
    ]
    subprocess.run(cmd_webp, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if out_webp.exists():
        (OUT_WEB_VIDS / f"{name}.webp").write_bytes(out_webp.read_bytes())
        (ROOT_PREVIEWS / f"{name}.webp").write_bytes(out_webp.read_bytes())

    # Poster thumbnail
    poster_path = OUT_MKT_VIDS / f"{name}_poster.png"
    scenes[1][0].convert("RGB").save(poster_path, "PNG")
    (OUT_WEB_VIDS / f"{name}_poster.png").write_bytes(poster_path.read_bytes())
    (ROOT_PREVIEWS / f"{name}_poster.png").write_bytes(poster_path.read_bytes())

    print(f"  ✓ Built 1080p MP4: {out_mp4_appstore.name} (29.0s, showcasing all chapters)")

def main():
    print("==========================================================")
    print("  RENDERING COMPREHENSIVE APP PREVIEWS SHOWCASING ALL FEATURES")
    print("==========================================================")
    for p in PREVIEWS:
        generate_preview_clip(p)
    print("\n✅ All 3 Comprehensive Previews rendered successfully with all 10 features!")

if __name__ == "__main__":
    main()
