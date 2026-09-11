#!/usr/bin/env python3
"""
render_10_postcards.py
Generates 10 flagship marketing postcards for Genie 4.0 in:
1. Retina 2880x1800 (App Store Connect Showcase & Postcard Suite)
2. 1920x1080 Full HD Postcard format with luxury stamp, border, and feature callouts.
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO_ROOT = Path("/Users/nicholasdudek/Desktop/Genie")
GOLDGATE_ROOT = REPO_ROOT / "GoldGate"
WALLPAPERS_DIR = GOLDGATE_ROOT / "Wallpapers"
SCREENSHOTS_DIR = GOLDGATE_ROOT / "web" / "assets" / "screenshots"

OUTPUT_DIRS = [
    REPO_ROOT / "Marketing" / "Genie_AppStore_Suite",
    REPO_ROOT / "Marketing" / "AppStore_Connect_Assets" / "App_Store_Connect_Uploads_Build14" / "1_Retina_Screenshots_2880x1800",
    REPO_ROOT / "Marketing" / "Postcards_Showcase_Suite",
    GOLDGATE_ROOT / "web" / "assets" / "postcards",
]

for d in OUTPUT_DIRS:
    d.mkdir(parents=True, exist_ok=True)

POSTCARDS = [
    {
        "id": "01",
        "slug": "01_postcard_spatial_canvas",
        "appstore_name": "01_AppStore_2880x1800_Spatial_Desktop_Canvas.png",
        "title": "SPATIAL DESKTOP CANVAS",
        "subtitle": "Continuous 3x3 to 9x9 multi-space desktop matrix with frustum-culled 120 FPS navigation.",
        "badge": "EDITION 01 • SPATIAL MATRIX",
        "pills": ["81-Screen Universe", "Sub-35MB RAM", "Zero Telemetry"],
        "capture": "21_spatial_desktop_grid.png",
        "wallpaper": "GenieAerial4K.jpg",
        "accent_color": (244, 195, 117), # Champagne Gold
        "is_fullscreen": True,
    },
    {
        "id": "02",
        "slug": "02_postcard_ai_agent_studio",
        "appstore_name": "02_AppStore_2880x1800_Genie_Chat_AI_Agent.png",
        "title": "AUTONOMOUS LOCAL AI AGENT",
        "subtitle": "Integrated vision intelligence with real-time tool execution and live split-screen preview.",
        "badge": "EDITION 02 • LOCAL INTELLIGENCE",
        "pills": ["Vision Guided", "Live HTML/CSS Preview", "Ollama & Apple Silicon"],
        "capture": "19_chat_dual_tab_preview.png",
        "wallpaper": "GoldenGateSunset.jpg",
        "accent_color": (96, 165, 250), # Electric Blue
        "is_fullscreen": True,
    },
    {
        "id": "03",
        "slug": "03_postcard_world_clock_pillows",
        "appstore_name": "03_AppStore_2880x1800_World_Clock_Pillows.png",
        "title": "OLED WORLD CLOCK PILLOWS",
        "subtitle": "Blackout specular rim gradient cards with analog sweep hands, alarms & time travel scrubber.",
        "badge": "EDITION 03 • TIME MATRIX",
        "pills": ["Time Travel Scrubber", "Looping Chimes", "Multi-Zone Clocks"],
        "capture": "17_world_clock_pillows.png",
        "wallpaper": "iMacPurple.jpg",
        "accent_color": (192, 132, 252), # Iris Violet
        "is_fullscreen": False,
    },
    {
        "id": "04",
        "slug": "04_postcard_hypervisor_vm",
        "appstore_name": "04_AppStore_2880x1800_AI_Stations_Hypervisor.png",
        "title": "SOVEREIGN LINUX HYPERVISOR",
        "subtitle": "Direct Apple Silicon virtualization kernel with millisecond micro-clones and zero cloud dependencies.",
        "badge": "EDITION 04 • KERNEL HYPERVISOR",
        "pills": ["Native Virtualization", "Virtio-FS Fast Bridge", "Zero Cloud Overhead"],
        "capture": "18_hypervisor_ai_stations.png",
        "wallpaper": "SonomaHorizon.jpg",
        "accent_color": (52, 211, 153), # Emerald Green
        "is_fullscreen": False,
    },
    {
        "id": "05",
        "slug": "05_postcard_living_themes_shaders",
        "appstore_name": "05_AppStore_2880x1800_Living_Themes_Shaders.png",
        "title": "LIVING THEMES & METAL SHADERS",
        "subtitle": "120 FPS Metal fluid dynamics, frosted vitreous glass, and dynamic 4K aerial murals.",
        "badge": "EDITION 05 • METAL ATMOSPHERES",
        "pills": ["120 FPS Metal Shaders", "Vitreous Glass", "Day/Night Transitions"],
        "capture": "02_atmospheric_murals_shaders.png",
        "wallpaper": "GoldenGateDynamic.jpg",
        "accent_color": (251, 146, 60), # Amber Sunset
        "is_fullscreen": False,
    },
    {
        "id": "06",
        "slug": "06_postcard_battery_telemetry",
        "appstore_name": "06_AppStore_2880x1800_Dynamic_Battery_Telemetry.png",
        "title": "DYNAMIC BATTERY TELEMETRY",
        "subtitle": "Live wattage breakdown, charging state glyphs, minimal pills, and clamshell stay-awake.",
        "badge": "EDITION 06 • POWER TELEMETRY",
        "pills": ["Live Wattage Draw", "Clamshell Stay-Awake", "Health Degradation Metrics"],
        "capture": "01_power_reserve_battery.png",
        "wallpaper": "iMacOrange.jpg",
        "accent_color": (74, 222, 128), # Battery Green
        "is_fullscreen": False,
    },
    {
        "id": "07",
        "slug": "07_postcard_application_atelier",
        "appstore_name": "07_AppStore_2880x1800_Application_Atelier.png",
        "title": "APPLICATION ATELIER & FORMATIONS",
        "subtitle": "Responsive Grid, Fibonacci Galaxy, Halfpipe Arc, Bottom Shelf and instant drag organization.",
        "badge": "EDITION 07 • SPATIAL GEOMETRY",
        "pills": ["Fibonacci Galaxy", "Responsive Grid", "Drag-to-Dock Hub"],
        "capture": "07_application_atelier.png",
        "wallpaper": "iMacBlue.jpg",
        "accent_color": (56, 189, 248), # Sky Cyan
        "is_fullscreen": False,
    },
    {
        "id": "08",
        "slug": "08_postcard_haute_bezels_snuggies",
        "appstore_name": "08_AppStore_2880x1800_Window_Housings_Snuggies.png",
        "title": "HAUTE BEZELS & NOTCH SNUGGIES",
        "subtitle": "Precision window frames, camera notch integration, and tactile acoustic audio signatures.",
        "badge": "EDITION 08 • BESPOKE FINISHES",
        "pills": ["Notch Snuggie Dock", "Luxury Frame Bezels", "Tactile Audio Feedback"],
        "capture": "08_haute_bezels_snuggies.png",
        "wallpaper": "SonomaHorizon.jpg",
        "accent_color": (244, 195, 117), # Gold
        "is_fullscreen": False,
    },
    {
        "id": "09",
        "slug": "09_postcard_pets_complications",
        "appstore_name": "09_AppStore_2880x1800_Interactive_Widgets_Pets.png",
        "title": "INTERACTIVE PETS & COMPLICATIONS",
        "subtitle": "Desktop companions, 2D rigid body physics pinball, and spatial kinetic complications.",
        "badge": "EDITION 09 • KINETIC PHYSICS",
        "pills": ["Rigid Body Physics", "Desktop Companions", "Spatial Glider Complications"],
        "capture": "13_spatial_pets_pinball.png",
        "wallpaper": "RadialSkyBlue.jpg",
        "accent_color": (244, 114, 182), # Rose Pink
        "is_fullscreen": False,
    },
    {
        "id": "10",
        "slug": "10_postcard_diagnostics_hud",
        "appstore_name": "10_AppStore_2880x1800_System_Diagnostics_HUD.png",
        "title": "CONTINUOUS DIAGNOSTICS HUD",
        "subtitle": "Real-time parallel thread sentinel, zero-investigation memory headroom, and system health.",
        "badge": "EDITION 10 • SYSTEM SENTINEL",
        "pills": ["Parallel Thread Sentinel", "Memory Headroom Guard", "Zero Telemetry Attestation"],
        "capture": "20_system_diagnostics_sentinel.png",
        "wallpaper": "Macintosh.jpg",
        "accent_color": (148, 163, 184), # Platinum Steel
        "is_fullscreen": True,
    }
]

def load_fonts(scale=1.0):
    font_path = "/System/Library/Fonts/HelveticaNeue.ttc"
    try:
        title = ImageFont.truetype(font_path, int(54 * scale), index=1)   # Bold
        sub = ImageFont.truetype(font_path, int(26 * scale), index=10)     # Medium
        badge = ImageFont.truetype(font_path, int(18 * scale), index=1)    # Bold
        pill = ImageFont.truetype(font_path, int(20 * scale), index=10)    # Medium
        stamp = ImageFont.truetype(font_path, int(15 * scale), index=1)   # Bold
        watermark = ImageFont.truetype(font_path, int(22 * scale), index=1) # Bold
    except Exception:
        default = ImageFont.load_default()
        return default, default, default, default, default, default
    return title, sub, badge, pill, stamp, watermark

def render_postcard(item, width, height, is_retina_appstore=True):
    scale = width / 2880.0
    f_title, f_sub, f_badge, f_pill, f_stamp, f_watermark = load_fonts(scale)
    
    # 1. Base Wallpaper
    canvas = Image.new("RGBA", (width, height), (10, 14, 22, 255))
    wp_file = WALLPAPERS_DIR / item["wallpaper"]
    if not wp_file.exists():
        wp_file = WALLPAPERS_DIR / "GoldenGateDynamic.jpg"
    
    if wp_file.exists():
        wp = Image.open(wp_file).convert("RGBA")
        wp_ratio = wp.width / wp.height
        target_ratio = width / height
        if wp_ratio > target_ratio:
            nh = height
            nw = int(height * wp_ratio)
        else:
            nw = width
            nh = int(width / wp_ratio)
        wp_resized = wp.resize((nw, nh), Image.Resampling.LANCZOS)
        x_off = (nw - width) // 2
        y_off = (nh - height) // 2
        canvas.paste(wp_resized.crop((x_off, y_off, x_off + width, y_off + height)), (0, 0))

    # 2. Dark Luxury Vignette & Vitreous Lighting
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    
    top_bar_h = int(270 * scale)
    for y in range(top_bar_h):
        factor = (1.0 - (y / float(top_bar_h))) ** 1.3
        alpha = int(225 * factor)
        ov_draw.line([(0, y), (width, y)], fill=(8, 12, 20, alpha))
        
    bottom_bar_h = int(140 * scale)
    for y in range(height - bottom_bar_h, height):
        factor = (y - (height - bottom_bar_h)) / float(bottom_bar_h)
        alpha = int(210 * factor)
        ov_draw.line([(0, y), (width, y)], fill=(8, 12, 20, alpha))
        
    canvas = Image.alpha_composite(canvas, overlay)
    draw = ImageDraw.Draw(canvas)

    # 3. Postcard Stamp (Upper Right Badge)
    stamp_text = item["badge"]
    bbox_st = draw.textbbox((0, 0), stamp_text, font=f_stamp)
    stw, sth = bbox_st[2] - bbox_st[0], bbox_st[3] - bbox_st[1]
    st_pad_x, st_pad_y = int(24 * scale), int(10 * scale)
    st_x = width - stw - st_pad_x * 2 - int(60 * scale)
    st_y = int(40 * scale)
    
    # Stamp card container
    accent = item["accent_color"]
    draw.rounded_rectangle(
        [st_x, st_y, st_x + stw + st_pad_x * 2, st_y + sth + st_pad_y * 2],
        radius=int(14 * scale),
        fill=(15, 23, 42, 190),
        outline=(accent[0], accent[1], accent[2], 160),
        width=max(1, int(2 * scale))
    )
    draw.text((st_x + st_pad_x, st_y + st_pad_y), stamp_text, font=f_stamp, fill=(accent[0], accent[1], accent[2], 255))

    # 4. Upper Left Brand Mark
    brand_text = "GENIE 4.0 • MACOS SOVEREIGN WORKSPACE"
    draw.text((int(70 * scale), int(42 * scale)), brand_text, font=f_stamp, fill=(203, 213, 225, 220))

    # 5. Header Title & Subtitle (Centered)
    title_text = item["title"]
    sub_text = item["subtitle"]
    
    bbox_ti = draw.textbbox((0, 0), title_text, font=f_title)
    ti_w = bbox_ti[2] - bbox_ti[0]
    ti_x = (width - ti_w) // 2
    ti_y = int(82 * scale)
    draw.text((ti_x, ti_y), title_text, font=f_title, fill=(255, 255, 255, 255))

    bbox_su = draw.textbbox((0, 0), sub_text, font=f_sub)
    su_w = bbox_su[2] - bbox_su[0]
    su_x = (width - su_w) // 2
    su_y = ti_y + int(66 * scale)
    draw.text((su_x, su_y), sub_text, font=f_sub, fill=(215, 225, 240, 230))

    # 6. Feature Screenshot Placement
    cap_file = SCREENSHOTS_DIR / item["capture"]
    if cap_file.exists():
        cap_img = Image.open(cap_file).convert("RGBA")
        
        if item["is_fullscreen"]:
            target_w = int(2480 * scale)
            ratio = target_w / float(cap_img.width)
            target_h = int(cap_img.height * ratio)
            max_h = int(1420 * scale)
            if target_h > max_h:
                target_h = max_h
                ratio = target_h / float(cap_img.height)
                target_w = int(cap_img.width * ratio)
        else:
            target_w = int(min(2120 * scale, cap_img.width * 1.15 * scale))
            ratio = target_w / float(cap_img.width)
            target_h = int(cap_img.height * ratio)
            max_h = int(1360 * scale)
            if target_h > max_h:
                target_h = max_h
                ratio = target_h / float(cap_img.height)
                target_w = int(cap_img.width * ratio)

        cap_resized = cap_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
        
        # Rounded mask
        radius = int(28 * scale)
        mask = Image.new("L", (target_w, target_h), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.rounded_rectangle([0, 0, target_w, target_h], radius=radius, fill=255)
        
        # Drop Shadow
        pad = int(50 * scale)
        shadow_canvas = Image.new("RGBA", (target_w + pad * 2, target_h + pad * 2), (0, 0, 0, 0))
        sh_draw = ImageDraw.Draw(shadow_canvas)
        sh_draw.rounded_rectangle(
            [pad, pad + int(14 * scale), pad + target_w, pad + target_h + int(14 * scale)],
            radius=radius,
            fill=(0, 0, 0, 195)
        )
        shadow_blur = shadow_canvas.filter(ImageFilter.GaussianBlur(int(28 * scale)))
        
        px = (width - target_w) // 2
        py = int(220 * scale) + (height - int(220 * scale) - int(90 * scale) - target_h) // 2

        canvas.paste(shadow_blur, (px - pad, py - pad), shadow_blur)
        canvas.paste(cap_resized, (px, py), mask)

        # Vitreous Edge Rim Highlight
        rim_draw = ImageDraw.Draw(canvas)
        rim_draw.rounded_rectangle(
            [px, py, px + target_w, py + target_h],
            radius=radius,
            outline=(accent[0], accent[1], accent[2], 110),
            width=max(1, int(2 * scale))
        )

    # 7. Bottom Highlights Pill Bar
    pills = item["pills"]
    pill_boxes = []
    total_pills_w = 0
    pill_pad_x = int(22 * scale)
    pill_pad_y = int(8 * scale)
    pill_spacing = int(20 * scale)
    
    for p_text in pills:
        bbox = draw.textbbox((0, 0), p_text, font=f_pill)
        pw, ph = bbox[2] - bbox[0], bbox[3] - bbox[1]
        pill_w = pw + pill_pad_x * 2
        pill_boxes.append((p_text, pw, ph, pill_w))
        total_pills_w += pill_w
    total_pills_w += pill_spacing * (len(pills) - 1)
    
    cur_x = (width - total_pills_w) // 2
    cur_y = height - int(68 * scale)
    
    for p_text, pw, ph, pill_w in pill_boxes:
        draw.rounded_rectangle(
            [cur_x, cur_y, cur_x + pill_w, cur_y + ph + pill_pad_y * 2],
            radius=int(16 * scale),
            fill=(15, 23, 42, 205),
            outline=(255, 255, 255, 50),
            width=max(1, int(1 * scale))
        )
        # Bullet dot
        dot_r = int(4 * scale)
        dot_x = cur_x + int(14 * scale)
        dot_y = cur_y + (ph + pill_pad_y * 2) // 2
        draw.ellipse([dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r], fill=accent)
        
        draw.text((dot_x + int(10 * scale), cur_y + pill_pad_y), p_text, font=f_pill, fill=(241, 245, 249, 240))
        cur_x += pill_w + pill_spacing

    return canvas.convert("RGB")

def main():
    print("==========================================================")
    print("  RENDERING 10 FLAGSHIP GENIE POSTCARD MARKETING CARDS")
    print("==========================================================")

    for idx, item in enumerate(POSTCARDS, 1):
        print(f"[{idx}/10] Rendering '{item['title']}'...")
        
        # 1. 2880x1800 Retina App Store & Showcase Postcard
        img_retina = render_postcard(item, 2880, 1800, is_retina_appstore=True)
        
        # Save to AppStore Suite
        path_appstore = REPO_ROOT / "Marketing" / "Genie_AppStore_Suite" / item["appstore_name"]
        img_retina.save(path_appstore, "PNG", optimize=True)
        
        # Save to App Store Connect Build 14 Uploads
        path_b14 = REPO_ROOT / "Marketing" / "AppStore_Connect_Assets" / "App_Store_Connect_Uploads_Build14" / "1_Retina_Screenshots_2880x1800" / item["appstore_name"]
        img_retina.save(path_b14, "PNG", optimize=True)
        
        # Save to Postcards Showcase Suite
        path_pc_2880 = REPO_ROOT / "Marketing" / "Postcards_Showcase_Suite" / f"{item['slug']}_2880x1800.png"
        img_retina.save(path_pc_2880, "PNG", optimize=True)
        
        # 2. 1920x1080 Postcard format
        img_1080 = render_postcard(item, 1920, 1080, is_retina_appstore=False)
        path_pc_1080 = REPO_ROOT / "Marketing" / "Postcards_Showcase_Suite" / f"{item['slug']}_1080p.png"
        img_1080.save(path_pc_1080, "PNG", optimize=True)
        
        # Also copy to web assets postcards folder
        path_web_pc = GOLDGATE_ROOT / "web" / "assets" / "postcards" / f"{item['slug']}.png"
        img_1080.save(path_web_pc, "PNG", optimize=True)
        
        print(f"  ✓ Built 2880x1800 & 1080p Postcards: {item['slug']}")

    # Canonical aliases in Genie_AppStore_Suite
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
        src = REPO_ROOT / "Marketing" / "Genie_AppStore_Suite" / canonical
        if src.exists():
            dest = REPO_ROOT / "Marketing" / "Genie_AppStore_Suite" / alias
            dest.write_bytes(src.read_bytes())

    print("\n✅ All 10 Postcard Marketing Images rendered in both 2880x1800 and 1920x1080!")

if __name__ == "__main__":
    main()
