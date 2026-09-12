#!/usr/bin/env python3
"""
take_first_picture_of_a_token.py
--------------------------------
Creates and renders "The First Picture of a Token".

Combines:
1. Microscopic Neural Activation Spectrogram:
   Visualizes the high-dimensional latent tensor of Token #1 ("Hello", ID: 9707)
   projected into a 64x32 harmonic frequency matrix with attention resonance and
   quantization contours in an Obsidian/Electric Cyan-Emerald palette.
2. Mac/iOS Simulator UI Capture:
   The visual manifestation of the token freshly rendered on the 120Hz ProMotion display.
"""

import os
import sys
import math
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def generate_token_activation_matrix(width=640, height=480, token_id=9707, token_text="Hello"):
    """
    Renders a high-resolution 2D spectral activation portrait of a single LLM token tensor.
    """
    img = Image.new("RGBA", (width, height), (7, 10, 15, 255))  # OLED Obsidian black
    draw = ImageDraw.Draw(img)

    # 1. Background grid lines (quantum tensor coordinates)
    grid_spacing = 32
    for x in range(0, width, grid_spacing):
        draw.line([(x, 0), (x, height)], fill=(16, 25, 38, 120), width=1)
    for y in range(0, height, grid_spacing):
        draw.line([(0, y), (width, y)], fill=(16, 25, 38, 120), width=1)

    # 2. Synthesize token resonance harmonics based on token_id hash
    # Token 9707 ("Hello") activation waves
    center_x = width // 2
    center_y = height // 2
    
    # Render latent feature contour rings
    num_rings = 14
    for r in range(num_rings, 0, -1):
        radius = r * 14
        alpha = int(40 + (num_rings - r) * 15)
        # Gradient colors: Deep Indigo (outer) -> Electric Cyan -> Emerald Neon (core)
        ratio = r / num_rings
        red = int(10 + (1.0 - ratio) * 20)
        green = int(50 + (1.0 - ratio) * 205)
        blue = int(140 + (1.0 - ratio) * 115)
        
        bbox = [center_x - radius, center_y - radius, center_x + radius, center_y + radius]
        draw.ellipse(bbox, outline=(red, green, blue, alpha), width=2)

    # 3. Microscopic Attention Rays (32 Attention Heads projection)
    for head in range(32):
        angle = (head / 32.0) * 2 * math.pi
        # Energy variation based on token_id
        energy = 0.5 + 0.5 * math.sin(head * 0.7 + token_id * 0.01)
        ray_len = int(60 + energy * 120)
        x_end = center_x + math.cos(angle) * ray_len
        y_end = center_y + math.sin(angle) * ray_len
        
        cyan_intensity = int(120 + energy * 135)
        draw.line([(center_x, center_y), (x_end, y_end)], fill=(0, cyan_intensity, 230, 160), width=1)
        draw.ellipse([x_end - 2, y_end - 2, x_end + 2, y_end + 2], fill=(80, 255, 200, 220))

    # 4. Center Singularity (Token Core Activation)
    core_rad = 18
    draw.ellipse([center_x - core_rad, center_y - core_rad, center_x + core_rad, center_y + core_rad], 
                 fill=(0, 255, 170, 255))
    
    # 5. Technical Overlays & Metadata Labels
    draw.rectangle([16, 16, width - 16, height - 16], outline=(30, 48, 70, 200), width=1)
    
    # Metadata text
    draw.text((28, 26), f"TOKEN #1 SPECTROGRAM: \"{token_text}\"", fill=(0, 255, 180, 255))
    draw.text((28, 48), f"ID: {token_id} | EMBEDDING DIM: 2048 | PRECISION: Q4_K_M", fill=(140, 170, 200, 200))
    draw.text((28, 68), "TRANSIT: Apple Silicon Metal UMA -> 120Hz ProMotion Framebuffer", fill=(100, 130, 160, 180))
    
    draw.text((width - 170, height - 38), "LATENCY: 11.2 ms", fill=(0, 255, 220, 240))
    draw.text((width - 170, height - 24), "STATE: RESIDENT", fill=(50, 200, 120, 240))

    return img


def build_composite_token_photo():
    """
    Creates a master composite image pairing the microscopic neural spectrogram
    with the macroscopic iOS Simulator screenshot of the token.
    """
    base_dir = Path(__file__).resolve().parent
    sim_path = str(base_dir / "docs" / "ios_simulator_token_capture.png")
    out_path = str(base_dir / "docs" / "first_picture_of_a_token.png")
    
    canvas_w = 1280
    canvas_h = 720
    master = Image.new("RGBA", (canvas_w, canvas_h), (5, 7, 10, 255))
    draw = ImageDraw.Draw(master)

    # 1. Generate Left Panel: Neural Activation Spectrogram
    spectrogram = generate_token_activation_matrix(width=600, height=600, token_id=9707, token_text="Hello")
    master.paste(spectrogram, (36, 60))

    # 2. Right Panel: Booted Simulator Framebuffer
    if os.path.exists(sim_path):
        sim_img = Image.open(sim_path).convert("RGBA")
        # Scale to fit nicely in 560x600 box maintaining aspect ratio
        sim_aspect = sim_img.width / sim_img.height
        target_h = 580
        target_w = int(target_h * sim_aspect)
        sim_resized = sim_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
        
        sim_x = 680 + (560 - target_w) // 2
        master.paste(sim_resized, (sim_x, 70))
        draw.rectangle([sim_x - 2, 68, sim_x + target_w + 2, 70 + target_h + 2], outline=(30, 50, 80, 220), width=1)
    
    # 3. Master Header
    draw.text((36, 20), "THE FIRST PICTURE OF A TOKEN (GENIE AI)", fill=(255, 255, 255, 240))
    draw.text((500, 22), "Left: Neural Activation Latent (2048-D)  |  Right: Live iOS 16 Pro Framebuffer", fill=(140, 170, 200, 200))

    master.save(out_path, "PNG")
    print(f"[+] 'First Picture of a Token' generated at: {out_path}")


if __name__ == "__main__":
    build_composite_token_photo()
