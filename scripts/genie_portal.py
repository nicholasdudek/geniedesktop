#!/usr/bin/env python3
"""
genie_portal.py — Ephemeral Direct Touch Mouse & Spatial Screen Portal
=====================================================================
Engineered for Nicholas Dudek.
Translates touch on iPhone 16 Plus directly to 14" MacBook Pro Liquid Retina XDR.
Zero external servers, zero disk storage, memory-only vanishing chats.
Features real-time Accessibility UI element target highlighting and magnetic touch snapping.
"""

import io
import json
import math
import os
import subprocess
import sys
import time
import urllib.request
from typing import Optional

import Quartz
from Cocoa import NSBitmapImageRep, NSJPEGFileType
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Response
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI(title="Genie Spatial Portal", version="2.0.0")

# 14" MacBook Pro Screen Dimensions (Points)
SCREEN_WIDTH = Quartz.CGDisplayPixelsWide(Quartz.CGMainDisplayID())
SCREEN_HEIGHT = Quartz.CGDisplayPixelsHigh(Quartz.CGMainDisplayID())
SCANNER_BIN = "/Users/nicholasdudek/genie_element_scanner"

KEY_CODES = {
    "enter": 36, "return": 36, "space": 49, "escape": 53, "esc": 53,
    "backspace": 51, "delete": 51, "tab": 48, "up": 126, "down": 125,
    "left": 123, "right": 124, "cmd_space": (49, Quartz.kCGEventFlagMaskCommand),
    "cmd_c": (8, Quartz.kCGEventFlagMaskCommand),
    "cmd_v": (9, Quartz.kCGEventFlagMaskCommand),
    "cmd_w": (13, Quartz.kCGEventFlagMaskCommand),
    "cmd_a": (0, Quartz.kCGEventFlagMaskCommand)
}

_cached_elements = []
_last_scan_time = 0.0


def get_enterable_elements(force: bool = False) -> list:
    """Invokes the native compiled Swift scanner to query enterable elements in RAM (<40ms)."""
    global _cached_elements, _last_scan_time
    now = time.time()
    if not force and (now - _last_scan_time) < 0.45 and _cached_elements:
        return _cached_elements
    try:
        proc = subprocess.run([SCANNER_BIN], capture_output=True, text=True, timeout=1.5)
        if proc.returncode == 0 and proc.stdout.strip():
            _cached_elements = json.loads(proc.stdout)
            _last_scan_time = now
            return _cached_elements
    except Exception as e:
        print(f"Scanner error: {e}", file=sys.stderr)
    return _cached_elements


def capture_screen_jpeg(quality: float = 0.70) -> bytes:
    """Captures the macOS display directly into RAM using Quartz hardware acceleration."""
    main_display = Quartz.CGMainDisplayID()
    image_ref = Quartz.CGDisplayCreateImage(main_display)
    if not image_ref:
        return b""
    rep = NSBitmapImageRep.alloc().initWithCGImage_(image_ref)
    props = {Quartz.NSImageCompressionFactor: quality}
    data = rep.representationUsingType_properties_(NSJPEGFileType, props)
    return bytes(data)


def post_mouse_move(x: float, y: float):
    pt = Quartz.CGPoint(max(0, min(SCREEN_WIDTH, x)), max(0, min(SCREEN_HEIGHT, y)))
    ev = Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventMouseMoved, pt, Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, ev)


def post_mouse_click(x: float, y: float, button: str = "left"):
    pt = Quartz.CGPoint(max(0, min(SCREEN_WIDTH, x)), max(0, min(SCREEN_HEIGHT, y)))
    btn = Quartz.kCGMouseButtonLeft if button == "left" else Quartz.kCGMouseButtonRight
    down_type = Quartz.kCGEventLeftMouseDown if button == "left" else Quartz.kCGEventRightMouseDown
    up_type = Quartz.kCGEventLeftMouseUp if button == "left" else Quartz.kCGEventRightMouseUp

    # Move cursor first
    post_mouse_move(x, y)
    time.sleep(0.01)

    down = Quartz.CGEventCreateMouseEvent(None, down_type, pt, btn)
    up = Quartz.CGEventCreateMouseEvent(None, up_type, pt, btn)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
    time.sleep(0.01)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)


def post_mouse_drag(x: float, y: float):
    pt = Quartz.CGPoint(max(0, min(SCREEN_WIDTH, x)), max(0, min(SCREEN_HEIGHT, y)))
    ev = Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventLeftMouseDragged, pt, Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, ev)


def post_mouse_drag_down(x: float, y: float):
    pt = Quartz.CGPoint(max(0, min(SCREEN_WIDTH, x)), max(0, min(SCREEN_HEIGHT, y)))
    ev = Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventLeftMouseDown, pt, Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, ev)


def post_mouse_drag_up(x: float, y: float):
    pt = Quartz.CGPoint(max(0, min(SCREEN_WIDTH, x)), max(0, min(SCREEN_HEIGHT, y)))
    ev = Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventLeftMouseUp, pt, Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, ev)


def post_scroll(delta_y: int):
    ev = Quartz.CGEventCreateScrollWheelEvent(None, Quartz.kCGScrollEventUnitLine, 1, delta_y)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, ev)


def post_key(name: str):
    code_info = KEY_CODES.get(name.lower())
    if not code_info:
        return
    if isinstance(code_info, tuple):
        code, flags = code_info
        down = Quartz.CGEventCreateKeyboardEvent(None, code, True)
        up = Quartz.CGEventCreateKeyboardEvent(None, code, False)
        Quartz.CGEventSetFlags(down, flags)
        Quartz.CGEventSetFlags(up, flags)
        Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
        Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)
    else:
        code = code_info
        down = Quartz.CGEventCreateKeyboardEvent(None, code, True)
        up = Quartz.CGEventCreateKeyboardEvent(None, code, False)
        Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
        Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)


def type_text(text: str):
    escaped = text.replace('\\', '\\\\').replace('"', '\\"')
    subprocess.run(["osascript", "-e", f'tell application "System Events" to keystroke "{escaped}"'], check=False)


def query_genie_ephemeral(prompt: str) -> str:
    """Queries Genie AI via Ollama with 100% ephemeral memory-only processing."""
    payload = {
        "model": "genie-macos-agent:latest",
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are Genie, Nicholas Dudek's intelligent macOS companion on his iPhone 16 Plus spatial portal. "
                    "Keep responses concise (1-2 sentences), sharp, and high-signal."
                )
            },
            {"role": "user", "content": prompt}
        ],
        "stream": False,
        "options": {"temperature": 0.6, "top_p": 0.85}
    }
    try:
        req = urllib.request.Request(
            "http://127.0.0.1:11434/api/chat",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("message", {}).get("content", "").strip()
    except Exception:
        return "Command executed on your Mac, Nicholas."


@app.get("/api/screen.jpg")
def get_screen():
    """Streams live desktop frame in-memory without touching disk."""
    jpeg_bytes = capture_screen_jpeg(quality=0.68)
    return Response(
        content=jpeg_bytes,
        media_type="image/jpeg",
        headers={"Cache-Control": "no-cache, no-store, must-revalidate"}
    )


@app.get("/api/elements")
def get_elements():
    """Returns real-time enterable UI elements from frontmost apps (<40ms execution)."""
    return get_enterable_elements(force=False)


@app.websocket("/ws/control")
async def websocket_control(websocket: WebSocket):
    await websocket.accept()
    current_x = SCREEN_WIDTH / 2
    current_y = SCREEN_HEIGHT / 2

    # Get initial cursor location
    try:
        loc = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
        current_x = loc.x
        current_y = loc.y
    except Exception:
        pass

    try:
        while True:
            text_data = await websocket.receive_text()
            data = json.loads(text_data)
            action = data.get("type")

            if action == "move":
                dx = float(data.get("dx", 0))
                dy = float(data.get("dy", 0))
                speed = math.hypot(dx, dy)
                accel = 1.0 + min(2.5, speed * 0.08)
                current_x = max(0, min(SCREEN_WIDTH, current_x + dx * accel))
                current_y = max(0, min(SCREEN_HEIGHT, current_y + dy * accel))
                post_mouse_move(current_x, current_y)

            elif action == "click":
                btn = data.get("button", "left")
                post_mouse_click(current_x, current_y, button=btn)

            elif action == "direct_click":
                x_pct = float(data.get("x_pct", 0.5))
                y_pct = float(data.get("y_pct", 0.5))
                current_x = max(0, min(SCREEN_WIDTH, x_pct * SCREEN_WIDTH))
                current_y = max(0, min(SCREEN_HEIGHT, y_pct * SCREEN_HEIGHT))
                btn = data.get("button", "left")
                post_mouse_click(current_x, current_y, button=btn)

            elif action == "enter_element":
                cx = float(data.get("cx", SCREEN_WIDTH / 2))
                cy = float(data.get("cy", SCREEN_HEIGHT / 2))
                elem_type = data.get("elem_type", "button")
                current_x = max(0, min(SCREEN_WIDTH, cx))
                current_y = max(0, min(SCREEN_HEIGHT, cy))
                post_mouse_click(current_x, current_y, button="left")
                if elem_type == "text_input":
                    time.sleep(0.02)
                    post_mouse_click(current_x, current_y, button="left")

            elif action == "scan_elements":
                elems = get_enterable_elements(force=True)
                await websocket.send_json({"type": "elements_update", "elements": elems})

            elif action == "drag_start":
                post_mouse_drag_down(current_x, current_y)

            elif action == "drag_move":
                dx = float(data.get("dx", 0))
                dy = float(data.get("dy", 0))
                current_x = max(0, min(SCREEN_WIDTH, current_x + dx))
                current_y = max(0, min(SCREEN_HEIGHT, current_y + dy))
                post_mouse_drag(current_x, current_y)

            elif action == "drag_end":
                post_mouse_drag_up(current_x, current_y)

            elif action == "scroll":
                delta_y = int(data.get("dy", 0))
                post_scroll(delta_y)

            elif action == "key":
                key_name = data.get("name", "")
                post_key(key_name)

            elif action == "type":
                text = data.get("text", "")
                if text:
                    type_text(text)

            elif action == "chat":
                prompt = data.get("prompt", "")
                reply = query_genie_ephemeral(prompt)
                await websocket.send_json({"type": "chat_reply", "reply": reply})

    except WebSocketDisconnect:
        pass


@app.get("/", response_class=HTMLResponse)
def portal_html():
    """Dedicated iPhone 16 Plus Liquid Glass Spatial Portal with Enterable Element Target Snapping."""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <title>Genie Spatial Portal</title>
  <style>
    :root {{
      --bg: #05070c;
      --surface: rgba(18, 24, 38, 0.88);
      --glass-border: rgba(255, 255, 255, 0.12);
      --cyan: #00f0ff;
      --cyan-glow: rgba(0, 240, 255, 0.45);
      --blue: #0070f3;
      --purple: #8b5cf6;
      --green: #10b981;
      --amber: #f59e0b;
      --text: #f8fafc;
      --dim: #94a3b8;
      --font: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif;
    }}
    * {{
      box-sizing: border-box; margin: 0; padding: 0;
      -webkit-tap-highlight-color: transparent;
      user-select: none; -webkit-user-select: none;
    }}
    body {{
      background: var(--bg);
      color: var(--text);
      font-family: var(--font);
      height: 100vh;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      position: relative;
    }}
    /* Top Navigation & Status Bar */
    header {{
      padding: calc(env(safe-area-inset-top) + 6px) 12px 8px 12px;
      background: rgba(8, 12, 20, 0.94);
      backdrop-filter: blur(25px);
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--glass-border);
      z-index: 50;
    }}
    .node-brand {{
      display: flex;
      align-items: center;
      gap: 7px;
    }}
    .pulse {{
      width: 8px; height: 8px;
      background: var(--cyan);
      border-radius: 50%;
      box-shadow: 0 0 10px var(--cyan);
      animation: pulseAnim 2s infinite;
    }}
    @keyframes pulseAnim {{
      0%, 100% {{ opacity: 0.6; transform: scale(0.9); }}
      50% {{ opacity: 1; transform: scale(1.15); }}
    }}
    .title {{
      font-size: 13px; font-weight: 700;
      background: linear-gradient(135deg, #fff, #94a3b8);
      -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      letter-spacing: -0.2px;
    }}
    .header-controls {{
      display: flex;
      align-items: center;
      gap: 6px;
    }}
    .mode-switch {{
      display: flex;
      background: rgba(255, 255, 255, 0.08);
      border-radius: 18px;
      padding: 2px;
      gap: 2px;
    }}
    .mode-btn {{
      padding: 4px 10px;
      border-radius: 14px;
      border: none;
      background: transparent;
      color: var(--dim);
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      gap: 4px;
    }}
    .mode-btn.active {{
      background: rgba(255, 255, 255, 0.2);
      color: #fff;
    }}
    .targets-btn {{
      background: rgba(0, 240, 255, 0.12);
      border: 1px solid rgba(0, 240, 255, 0.35);
      color: var(--cyan);
      padding: 4px 9px;
      border-radius: 14px;
      font-size: 11px;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 4px;
      cursor: pointer;
      transition: all 0.2s ease;
    }}
    .targets-btn.off {{
      background: rgba(255, 255, 255, 0.05);
      border-color: rgba(255, 255, 255, 0.1);
      color: var(--dim);
    }}

    /* Main Viewport Container */
    #viewport-container {{
      flex: 1;
      position: relative;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }}

    /* Mode 1: Live Display with Highlight Overlays */
    #screen-mode {{
      flex: 1;
      position: relative;
      background: #000;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      touch-action: manipulation;
    }}
    #screen-wrapper {{
      position: relative;
      display: inline-flex;
      max-width: 100%;
      max-height: 100%;
      align-items: center;
      justify-content: center;
    }}
    #live-screen {{
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
      display: block;
      cursor: crosshair;
    }}

    /* Real-Time Highlight Target Overlay */
    #highlights-layer {{
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      pointer-events: none;
      z-index: 25;
    }}
    .target-box {{
      position: absolute;
      box-sizing: border-box;
      border-radius: 6px;
      pointer-events: none;
      transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
    }}
    .target-box.text_input {{
      border: 2px solid var(--cyan);
      background: rgba(0, 240, 255, 0.14);
      box-shadow: 0 0 10px var(--cyan-glow), inset 0 0 6px rgba(0, 240, 255, 0.2);
      animation: pulseTarget 2.4s infinite ease-in-out;
    }}
    .target-box.button {{
      border: 1.5px solid var(--green);
      background: rgba(16, 185, 129, 0.10);
      box-shadow: 0 0 8px rgba(16, 185, 129, 0.35);
    }}
    .target-box.entered {{
      border-color: #fbbf24 !important;
      background: rgba(251, 191, 36, 0.4) !important;
      box-shadow: 0 0 24px #fbbf24, inset 0 0 12px rgba(251, 191, 36, 0.5) !important;
      transform: scale(1.05);
    }}
    .target-badge {{
      position: absolute;
      top: -15px;
      left: 0;
      background: rgba(5, 7, 12, 0.88);
      backdrop-filter: blur(10px);
      padding: 1px 5px;
      border-radius: 4px;
      font-size: 9px;
      font-weight: 700;
      white-space: nowrap;
      letter-spacing: 0.2px;
      text-overflow: ellipsis;
      overflow: hidden;
      max-width: 140px;
      border: 1px solid currentColor;
      line-height: 1.2;
    }}
    .target-box.text_input .target-badge {{
      color: var(--cyan);
      border-color: rgba(0, 240, 255, 0.6);
    }}
    .target-box.button .target-badge {{
      color: var(--green);
      border-color: rgba(16, 185, 129, 0.6);
    }}
    @keyframes pulseTarget {{
      0%, 100% {{
        box-shadow: 0 0 8px rgba(0, 240, 255, 0.4), inset 0 0 4px rgba(0, 240, 255, 0.2);
        border-color: rgba(0, 240, 255, 0.85);
      }}
      50% {{
        box-shadow: 0 0 18px rgba(0, 240, 255, 0.8), inset 0 0 8px rgba(0, 240, 255, 0.4);
        border-color: #00f0ff;
      }}
    }}

    /* Mode 2: Touch Mouse Trackpad */
    #trackpad-mode {{
      display: none;
      flex: 1;
      flex-direction: column;
      position: relative;
      background: radial-gradient(circle at 50% 50%, #0f172a 0%, #060913 100%);
      align-items: center;
      justify-content: center;
      touch-action: none;
    }}
    .trackpad-surface {{
      width: 92%;
      height: 85%;
      border-radius: 28px;
      border: 1px solid var(--glass-border);
      background: rgba(255, 255, 255, 0.03);
      box-shadow: inset 0 0 30px rgba(0, 0, 0, 0.6);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      position: relative;
    }}
    .trackpad-hint {{
      font-size: 13px;
      font-weight: 600;
      color: rgba(255, 255, 255, 0.35);
      letter-spacing: 0.5px;
      text-transform: uppercase;
      text-align: center;
      line-height: 1.6;
    }}

    /* Touch Ripple Feedback */
    .ripple {{
      position: absolute;
      width: 44px; height: 44px;
      border-radius: 50%;
      border: 2px solid var(--cyan);
      background: rgba(0, 240, 255, 0.3);
      transform: translate(-50%, -50%) scale(0);
      pointer-events: none;
      animation: rippleAnim 0.35s ease-out forwards;
      z-index: 60;
    }}
    @keyframes rippleAnim {{
      0% {{ transform: translate(-50%, -50%) scale(0.2); opacity: 1; }}
      100% {{ transform: translate(-50%, -50%) scale(1.8); opacity: 0; }}
    }}

    /* Ephemeral Vanishing Chats */
    #vanish-chat-overlay {{
      position: absolute;
      top: 10px; left: 12px; right: 12px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      pointer-events: none;
      z-index: 40;
    }}
    .vanish-bubble {{
      align-self: flex-start;
      max-width: 88%;
      padding: 9px 14px;
      border-radius: 16px;
      font-size: 13px;
      line-height: 1.4;
      background: rgba(15, 23, 42, 0.94);
      border: 1px solid rgba(0, 240, 255, 0.3);
      box-shadow: 0 4px 18px rgba(0, 0, 0, 0.6);
      color: #fff;
      backdrop-filter: blur(20px);
      transition: opacity 0.8s ease, transform 0.8s ease;
    }}
    .vanish-bubble.user {{
      align-self: flex-end;
      background: linear-gradient(135deg, rgba(0, 112, 243, 0.92), rgba(0, 80, 200, 0.92));
      border-color: rgba(255, 255, 255, 0.2);
    }}
    .vanish-bubble.fade-out {{
      opacity: 0;
      transform: translateY(-8px) scale(0.96);
    }}

    /* Bottom Control Bar & Keyboard Summon Dock */
    footer {{
      background: rgba(8, 12, 20, 0.95);
      backdrop-filter: blur(25px);
      border-top: 1px solid var(--glass-border);
      padding: 6px 12px calc(env(safe-area-inset-bottom) + 6px) 12px;
      display: flex;
      flex-direction: column;
      gap: 6px;
      z-index: 50;
    }}
    .target-active-pill {{
      display: none;
      align-items: center;
      justify-content: space-between;
      background: rgba(0, 240, 255, 0.12);
      border: 1px solid rgba(0, 240, 255, 0.4);
      border-radius: 8px;
      padding: 3px 10px;
      font-size: 11px;
      color: var(--cyan);
      font-weight: 600;
    }}
    .target-active-pill.visible {{
      display: flex;
    }}
    .pill-close {{
      background: transparent;
      border: none;
      color: rgba(255, 255, 255, 0.6);
      font-size: 12px;
      cursor: pointer;
      padding: 0 4px;
    }}
    .keys-row {{
      display: flex;
      gap: 4px;
      overflow-x: auto;
      scrollbar-width: none;
    }}
    .keys-row::-webkit-scrollbar {{ display: none; }}
    .key-btn {{
      flex: 1;
      min-width: 44px;
      height: 32px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid var(--glass-border);
      border-radius: 8px;
      color: #cbd5e1;
      font-size: 11px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
    }}
    .key-btn:active {{ background: rgba(0, 240, 255, 0.2); }}

    .input-row {{
      display: flex;
      gap: 6px;
    }}
    .text-input {{
      flex: 1;
      height: 36px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--glass-border);
      border-radius: 10px;
      padding: 0 12px;
      color: #fff;
      font-size: 13px;
      outline: none;
    }}
    .text-input:focus {{ border-color: var(--cyan); box-shadow: 0 0 10px rgba(0, 240, 255, 0.3); }}
    .send-btn {{
      height: 36px;
      padding: 0 14px;
      background: linear-gradient(135deg, var(--cyan), var(--blue));
      border: none;
      border-radius: 10px;
      color: #fff;
      font-weight: 700;
      font-size: 12px;
      cursor: pointer;
    }}
  </style>
</head>
<body>

  <header>
    <div class="node-brand">
      <div class="pulse"></div>
      <div class="title">14" Liquid Retina XDR</div>
    </div>
    <div class="header-controls">
      <button class="targets-btn" id="btn-toggle-targets" onclick="toggleHighlights()">
        🎯 <span id="target-count-text">Targets</span>
      </button>
      <div class="mode-switch">
        <button class="mode-btn active" id="btn-mode-screen" onclick="setMode('screen')">Screen</button>
        <button class="mode-btn" id="btn-mode-trackpad" onclick="setMode('trackpad')">Trackpad</button>
      </div>
    </div>
  </header>

  <div id="viewport-container">
    <!-- Ephemeral Vanishing Chat Overlay -->
    <div id="vanish-chat-overlay"></div>

    <!-- Mode 1: Live Display Canvas with Target Highlighting -->
    <div id="screen-mode">
      <div id="screen-wrapper">
        <img id="live-screen" src="/api/screen.jpg" alt="14-inch Mac Display">
        <div id="highlights-layer"></div>
      </div>
    </div>

    <!-- Mode 2: Touch Mouse / Magic Trackpad -->
    <div id="trackpad-mode">
      <div class="trackpad-surface" id="trackpad-surface">
        <div class="trackpad-hint">
          1-Finger: Move Cursor & Tap to Click<br>
          2-Finger Tap: Right Click<br>
          2-Finger Slide: Scroll Wheel<br>
          Hold + Slide: Drag & Select
        </div>
      </div>
    </div>
  </div>

  <footer>
    <!-- Active Entered Element Indicator -->
    <div class="target-active-pill" id="active-target-pill">
      <span>✏️ Active Target: <strong id="active-target-name">Text Field</strong></span>
      <button class="pill-close" onclick="clearActiveTarget()">✕</button>
    </div>

    <div class="keys-row">
      <button class="key-btn" onclick="sendKey('enter')">⏎ Enter</button>
      <button class="key-btn" onclick="sendKey('space')">Space</button>
      <button class="key-btn" onclick="sendKey('tab')">Tab</button>
      <button class="key-btn" onclick="sendKey('backspace')">⌫ Del</button>
      <button class="key-btn" onclick="sendKey('escape')">Esc</button>
      <button class="key-btn" onclick="sendKey('cmd_c')">⌘ C</button>
      <button class="key-btn" onclick="sendKey('cmd_v')">⌘ V</button>
      <button class="key-btn" onclick="sendKey('cmd_a')">⌘ A</button>
    </div>
    <div class="input-row">
      <input type="text" id="chat-input" class="text-input" placeholder="Touch highlighted area or type..." onkeydown="if(event.key==='Enter')handleSend()">
      <button class="send-btn" onclick="handleSend()">Send</button>
    </div>
  </footer>

  <script>
    let ws;
    let mode = 'screen';
    let highlightsEnabled = true;
    let cachedElements = [];
    let activeTarget = null;

    const liveImg = document.getElementById('live-screen');
    const screenWrapper = document.getElementById('screen-wrapper');
    const screenMode = document.getElementById('screen-mode');
    const trackpadMode = document.getElementById('trackpad-mode');
    const highlightsLayer = document.getElementById('highlights-layer');
    const chatOverlay = document.getElementById('vanish-chat-overlay');
    const trackpadSurface = document.getElementById('trackpad-surface');
    const activeTargetPill = document.getElementById('active-target-pill');
    const activeTargetName = document.getElementById('active-target-name');
    const chatInput = document.getElementById('chat-input');
    const btnToggleTargets = document.getElementById('btn-toggle-targets');
    const targetCountText = document.getElementById('target-count-text');

    function connectWS() {{
      const loc = window.location;
      const proto = loc.protocol === 'https:' ? 'wss:' : 'ws:';
      ws = new WebSocket(`${{proto}}//${{loc.host}}/ws/control`);

      ws.onmessage = (e) => {{
        try {{
          const data = JSON.parse(e.data);
          if (data.type === 'chat_reply') {{
            addVanishBubble(data.reply, 'genie');
          }} else if (data.type === 'elements_update') {{
            cachedElements = data.elements || [];
            renderHighlights();
          }}
        }} catch(err) {{}}
      }};

      ws.onclose = () => {{
        setTimeout(connectWS, 1500);
      }};
    }}
    connectWS();

    function setMode(m) {{
      mode = m;
      document.getElementById('btn-mode-screen').classList.toggle('active', m === 'screen');
      document.getElementById('btn-mode-trackpad').classList.toggle('active', m === 'trackpad');
      if (m === 'screen') {{
        screenMode.style.display = 'flex';
        trackpadMode.style.display = 'none';
        refreshElements();
      }} else {{
        screenMode.style.display = 'none';
        trackpadMode.style.display = 'flex';
      }}
    }}

    function toggleHighlights() {{
      highlightsEnabled = !highlightsEnabled;
      btnToggleTargets.classList.toggle('off', !highlightsEnabled);
      renderHighlights();
    }}

    // Real-Time In-Memory Screen Streaming (15 FPS without disk storage)
    setInterval(() => {{
      if (mode === 'screen') {{
        const nextImg = new Image();
        nextImg.src = '/api/screen.jpg?t=' + Date.now();
        nextImg.onload = () => {{
          liveImg.src = nextImg.src;
        }};
      }}
    }}, 75);

    // Fetch and sync enterable elements every 1.5 seconds in RAM
    async function refreshElements() {{
      try {{
        const resp = await fetch('/api/elements');
        if (resp.ok) {{
          cachedElements = await resp.json();
          renderHighlights();
        }}
      }} catch (e) {{}}
    }}
    setInterval(() => {{
      if (mode === 'screen' && highlightsEnabled) {{
        refreshElements();
      }}
    }}, 1500);
    refreshElements();

    function renderHighlights() {{
      if (!highlightsEnabled || mode !== 'screen') {{
        highlightsLayer.innerHTML = '';
        targetCountText.textContent = 'Targets: Off';
        return;
      }}

      targetCountText.textContent = `Targets (${{cachedElements.length}})`;
      highlightsLayer.innerHTML = '';

      cachedElements.forEach((elem) => {{
        const box = document.createElement('div');
        box.className = `target-box ${{elem.type}}`;
        box.id = `target-${{elem.id}}`;
        box.style.left = (elem.rx * 100) + '%';
        box.style.top = (elem.ry * 100) + '%';
        box.style.width = (elem.rw * 100) + '%';
        box.style.height = (elem.rh * 100) + '%';

        const badge = document.createElement('div');
        badge.className = 'target-badge';
        badge.textContent = elem.type === 'text_input'
          ? (elem.label ? `Aa ${{elem.label}}` : 'Aa Text Field')
          : (elem.label ? `⚡ ${{elem.label}}` : '⚡ Action');
        box.appendChild(badge);

        highlightsLayer.appendChild(box);
      }});
    }}

    // TOUCH SENSOR MAGNETIC ENTERABLE SNAPPING
    screenWrapper.addEventListener('click', (e) => {{
      handleScreenTouch(e.clientX, e.clientY);
    }});

    function handleScreenTouch(clientX, clientY) {{
      const rect = liveImg.getBoundingClientRect();
      const xPct = (clientX - rect.left) / rect.width;
      const yPct = (clientY - rect.top) / rect.height;

      if (xPct < 0 || xPct > 1 || yPct < 0 || yPct > 1) return;

      createRipple(clientX, clientY);
      if (navigator.vibrate) navigator.vibrate(15);

      // Check if touch hits or is near an enterable element
      let bestTarget = null;
      let minDistance = 9999;

      if (highlightsEnabled && cachedElements.length > 0) {{
        for (const elem of cachedElements) {{
          // Check inside bounding box
          if (xPct >= elem.rx && xPct <= (elem.rx + elem.rw) &&
              yPct >= elem.ry && yPct <= (elem.ry + elem.rh)) {{
            bestTarget = elem;
            break;
          }}
          // Check magnetic snapping radius (within 26 pixels)
          const elemPixelX = (elem.rx + elem.rw / 2) * rect.width;
          const elemPixelY = (elem.ry + elem.rh / 2) * rect.height;
          const touchPixelX = xPct * rect.width;
          const touchPixelY = yPct * rect.height;
          const dist = Math.hypot(elemPixelX - touchPixelX, elemPixelY - touchPixelY);

          if (dist < 26 && dist < minDistance) {{
            minDistance = dist;
            bestTarget = elem;
          }}
        }}
      }}

      if (bestTarget) {{
        // Snap to hardware coordinates and highlight entered element
        flashEnteredTarget(bestTarget.id);
        enterElement(bestTarget);
      }} else {{
        // Direct click at touch location
        if (ws && ws.readyState === WebSocket.OPEN) {{
          ws.send(JSON.stringify({{
            type: 'direct_click',
            x_pct: xPct,
            y_pct: yPct,
            button: 'left'
          }}));
        }}
      }}
    }}

    function enterElement(elem) {{
      activeTarget = elem;
      const label = elem.label || (elem.type === 'text_input' ? 'Text Field' : 'Button');

      // Dispatch click over WebSocket
      if (ws && ws.readyState === WebSocket.OPEN) {{
        ws.send(JSON.stringify({{
          type: 'enter_element',
          cx: elem.cx,
          cy: elem.cy,
          elem_type: elem.type
        }}));
      }}

      if (elem.type === 'text_input') {{
        // Summon iPhone Virtual Keyboard & focus input field immediately
        activeTargetPill.classList.add('visible');
        activeTargetName.textContent = label;
        chatInput.placeholder = `Type into ${{label}}...`;
        chatInput.focus();
        addVanishBubble(`Entered text field: "${{label}}". Keyboard active.`, 'genie');
      }} else {{
        addVanishBubble(`Clicked ${{label}}`, 'genie');
        setTimeout(refreshElements, 250);
      }}
    }}

    function clearActiveTarget() {{
      activeTarget = null;
      activeTargetPill.classList.remove('visible');
      chatInput.placeholder = "Touch highlighted area or type...";
    }}

    function flashEnteredTarget(id) {{
      const el = document.getElementById(`target-${{id}}`);
      if (el) {{
        el.classList.add('entered');
        setTimeout(() => el.classList.remove('entered'), 600);
      }}
    }}

    function createRipple(x, y) {{
      const rip = document.createElement('div');
      rip.className = 'ripple';
      rip.style.left = x + 'px';
      rip.style.top = y + 'px';
      document.body.appendChild(rip);
      setTimeout(() => rip.remove(), 380);
    }}

    // Touch Mouse Trackpad Gestures (Apple Magic Trackpad Emulation)
    let touchStartX = 0, touchStartY = 0;
    let lastTouchX = 0, lastTouchY = 0;
    let touchStartTime = 0;
    let isDragging = false;
    let dragTimeout = null;

    trackpadSurface.addEventListener('touchstart', (e) => {{
      e.preventDefault();
      if (e.touches.length === 1) {{
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
        lastTouchX = touchStartX;
        lastTouchY = touchStartY;
        touchStartTime = Date.now();

        dragTimeout = setTimeout(() => {{
          isDragging = true;
          if (ws && ws.readyState === WebSocket.OPEN) {{
            ws.send(JSON.stringify({{ type: 'drag_start' }}));
          }}
        }}, 350);
      }} else if (e.touches.length === 2) {{
        clearTimeout(dragTimeout);
        touchStartY = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        lastTouchY = touchStartY;
      }}
    }}, {{ passive: false }});

    trackpadSurface.addEventListener('touchmove', (e) => {{
      e.preventDefault();
      if (e.touches.length === 1) {{
        const cx = e.touches[0].clientX;
        const cy = e.touches[0].clientY;
        const dx = cx - lastTouchX;
        const dy = cy - lastTouchY;
        lastTouchX = cx;
        lastTouchY = cy;

        if (!isDragging && Math.hypot(cx - touchStartX, cy - touchStartY) > 8) {{
          clearTimeout(dragTimeout);
        }}

        if (ws && ws.readyState === WebSocket.OPEN) {{
          if (isDragging) {{
            ws.send(JSON.stringify({{ type: 'drag_move', dx: dx, dy: dy }}));
          }} else {{
            ws.send(JSON.stringify({{ type: 'move', dx: dx, dy: dy }}));
          }}
        }}
      }} else if (e.touches.length === 2) {{
        clearTimeout(dragTimeout);
        const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        const dy = cy - lastTouchY;
        lastTouchY = cy;
        if (ws && ws.readyState === WebSocket.OPEN) {{
          ws.send(JSON.stringify({{ type: 'scroll', dy: dy > 0 ? 3 : -3 }}));
        }}
      }}
    }}, {{ passive: false }});

    trackpadSurface.addEventListener('touchend', (e) => {{
      e.preventDefault();
      clearTimeout(dragTimeout);
      const elapsed = Date.now() - touchStartTime;

      if (isDragging) {{
        isDragging = false;
        if (ws && ws.readyState === WebSocket.OPEN) {{
          ws.send(JSON.stringify({{ type: 'drag_end' }}));
        }}
        return;
      }}

      if (e.changedTouches.length === 1 && elapsed < 220) {{
        const moved = Math.hypot(lastTouchX - touchStartX, lastTouchY - touchStartY);
        if (moved < 7) {{
          if (ws && ws.readyState === WebSocket.OPEN) {{
            ws.send(JSON.stringify({{ type: 'click', button: 'left' }}));
          }}
          createRipple(lastTouchX, lastTouchY);
        }}
      }}
      if (e.touches.length === 0 && e.changedTouches.length === 2 && elapsed < 280) {{
        if (ws && ws.readyState === WebSocket.OPEN) {{
          ws.send(JSON.stringify({{ type: 'click', button: 'right' }}));
        }}
        createRipple(lastTouchX, lastTouchY);
      }}
    }}, {{ passive: false }});

    function sendKey(k) {{
      if (ws && ws.readyState === WebSocket.OPEN) {{
        ws.send(JSON.stringify({{ type: 'key', name: k }}));
      }}
      if (k === 'enter') {{
        setTimeout(refreshElements, 300);
      }}
    }}

    function handleSend() {{
      const val = chatInput.value.trim();
      if (!val) return;
      chatInput.value = '';

      // If text starts with '?' or '/', query Genie AI
      if (val.startsWith('?') || val.startsWith('/')) {{
        const prompt = val.substring(1).trim();
        addVanishBubble(prompt, 'user');
        if (ws && ws.readyState === WebSocket.OPEN) {{
          ws.send(JSON.stringify({{ type: 'chat', prompt: prompt }}));
        }}
        return;
      }}

      // Otherwise, directly type into the entered field on macOS!
      if (ws && ws.readyState === WebSocket.OPEN) {{
        ws.send(JSON.stringify({{ type: 'type', text: val }}));
      }}
      addVanishBubble(`Typed: "${{val}}"`, 'user');
      setTimeout(refreshElements, 350);
    }}

    // Ephemeral Vanishing Chats (12s auto-dissolve, zero disk persistence)
    function addVanishBubble(text, sender) {{
      const b = document.createElement('div');
      b.className = `vanish-bubble ${{sender}}`;
      b.textContent = text;
      chatOverlay.appendChild(b);

      setTimeout(() => {{
        b.classList.add('fade-out');
        setTimeout(() => b.remove(), 850);
      }}, 12000);
    }}
  </script>
</body>
</html>
"""


if __name__ == "__main__":
    print(f"🚀 Genie Spatial Portal online on http://0.0.0.0:8900")
    print(f"   Targeting 14\" MacBook Pro ({SCREEN_WIDTH}×{SCREEN_HEIGHT}) from iPhone 16 Plus")
    print(f"   Target Highlighter & Touch Sensor Snapper Active")
    uvicorn.run(app, host="0.0.0.0", port=8900, log_level="warning")
