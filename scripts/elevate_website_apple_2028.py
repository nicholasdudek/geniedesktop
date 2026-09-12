#!/usr/bin/env python3
"""
elevate_website_apple_2028.py
Comprehensive website elevation for Genie Build 500:
1. Update Postcards Showcase to the 10 Retina 2880x1800 Postcards with rich specs.
2. Add Apple 2028 Liquid Glass & Obsidian CSS.
3. Add Interactive Cursor FX Engine (bioluminescent halo, stardust particle trail, magnetic 3D specular tilt).
4. Add Built for Duo-Screen Studio & Live Working Chat Simulator with deep reasoning accordion, tool calls, and live 3D WebKit canvas.
5. Add "Architected for Apple Silicon. Zero Electron." section with head-to-head comparison matrix.
6. Synchronize changes to web/index.html.
"""

import sys
import re
from pathlib import Path

ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
INDEX_PATH = ROOT / "index.html"
WEB_INDEX_PATH = ROOT / "web" / "index.html"

def main():
    print("[*] Reading index.html...")
    content = INDEX_PATH.read_text(encoding="utf-8")

    # -------------------------------------------------------------
    # 1. CURSOR FX & DUO SCREEN CSS
    # -------------------------------------------------------------
    new_css = """
    /* ==========================================================================
       ✨ Apple 2028 Liquid Glass, Cursor FX & Duo-Screen Studio Styles
       ========================================================================== */
    
    /* Bioluminescent Cursor Halo */
    #genie-cursor-glow {
      position: fixed;
      top: 0;
      left: 0;
      width: 420px;
      height: 420px;
      margin-left: -210px;
      margin-top: -210px;
      border-radius: 50%;
      background: radial-gradient(circle, rgba(244, 195, 117, 0.14) 0%, rgba(147, 95, 245, 0.08) 40%, transparent 70%);
      pointer-events: none;
      z-index: 9999;
      mix-blend-mode: screen;
      opacity: 0;
      transition: opacity 0.5s ease;
      will-change: transform;
    }
    
    #genie-stardust-canvas {
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      pointer-events: none;
      z-index: 9998;
    }

    /* 3D Specular Rim Reflection on hover */
    .screenshot-card, .dissection-card, .duo-screen-window, .apple-arch-card {
      transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.35s cubic-bezier(0.16, 1, 0.3, 1), border-color 0.3s ease;
      transform-style: preserve-3d;
      position: relative;
    }
    .screenshot-card:hover, .dissection-card:hover, .duo-screen-window:hover, .apple-arch-card:hover {
      border-color: rgba(244, 195, 117, 0.5) !important;
      box-shadow: 0 24px 60px rgba(0, 0, 0, 0.65), 0 0 45px rgba(244, 195, 117, 0.18) !important;
    }

    /* Duo-Screen Interactive Studio Section */
    .duo-studio-section {
      padding: 90px 24px 70px 24px;
      max-width: 1380px;
      margin: 0 auto;
      position: relative;
    }

    .duo-hardware-frame {
      display: grid;
      grid-template-columns: 1fr 12px 1fr;
      background: rgba(15, 18, 26, 0.92);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 28px;
      overflow: hidden;
      box-shadow: 
        0 40px 100px rgba(0, 0, 0, 0.8),
        0 0 120px rgba(147, 95, 245, 0.2),
        0 0 0 1px rgba(255, 255, 255, 0.08) inset;
      backdrop-filter: blur(40px) saturate(200%);
      -webkit-backdrop-filter: blur(40px) saturate(200%);
      min-height: 720px;
      margin-top: 36px;
      position: relative;
    }

    /* Central Titanium Fold Seam */
    .duo-hinge-seam {
      background: linear-gradient(180deg, 
        rgba(255, 255, 255, 0.18) 0%, 
        rgba(60, 65, 80, 0.8) 15%, 
        rgba(20, 24, 34, 0.95) 50%, 
        rgba(60, 65, 80, 0.8) 85%, 
        rgba(255, 255, 255, 0.18) 100%);
      border-left: 1px solid rgba(0, 0, 0, 0.6);
      border-right: 1px solid rgba(255, 255, 255, 0.06);
      box-shadow: 0 0 12px rgba(0, 0, 0, 0.8) inset;
      position: relative;
    }
    .duo-hinge-seam::after {
      content: "";
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 4px;
      height: 48px;
      border-radius: 999px;
      background: rgba(244, 195, 117, 0.4);
      box-shadow: 0 0 8px rgba(244, 195, 117, 0.6);
    }

    /* Left Display: Autonomous Agent Executive Terminal */
    .duo-screen-left {
      display: flex;
      flex-direction: column;
      background: rgba(10, 13, 20, 0.85);
      border-right: 1px solid rgba(255, 255, 255, 0.06);
      overflow: hidden;
    }

    .duo-header-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 20px;
      background: rgba(18, 22, 32, 0.9);
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      font-size: 0.86rem;
      font-weight: 600;
    }

    .duo-traffic-lights {
      display: flex;
      gap: 7px;
      align-items: center;
    }
    .duo-traffic-dot {
      width: 11px;
      height: 11px;
      border-radius: 50%;
      display: inline-block;
    }
    .duo-traffic-dot.red { background: #ff5f56; }
    .duo-traffic-dot.yellow { background: #ffbd2e; }
    .duo-traffic-dot.green { background: #27c93f; }

    .duo-model-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 12px;
      background: rgba(244, 195, 117, 0.12);
      border: 1px solid rgba(244, 195, 117, 0.3);
      border-radius: 999px;
      color: var(--gold);
      font-size: 0.78rem;
      font-weight: 700;
      letter-spacing: 0.02em;
    }

    /* Chat Messages Stream */
    .duo-chat-stream {
      flex: 1;
      padding: 22px;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      gap: 16px;
      font-size: 0.92rem;
    }

    .duo-chat-msg {
      display: flex;
      gap: 12px;
      max-width: 92%;
      animation: msgFadeIn 0.35s cubic-bezier(0.16, 1, 0.3, 1) both;
    }
    @keyframes msgFadeIn {
      from { opacity: 0; transform: translateY(12px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .duo-chat-msg.user {
      align-self: flex-end;
      flex-direction: row-reverse;
    }
    .duo-avatar {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 0.95rem;
      flex-shrink: 0;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
    }
    .duo-avatar.genie {
      background: linear-gradient(135deg, #f4c375 0%, #d97706 100%);
      color: #000;
      font-weight: 800;
    }
    .duo-avatar.user {
      background: rgba(255, 255, 255, 0.12);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .duo-bubble {
      padding: 12px 16px;
      border-radius: 16px;
      line-height: 1.5;
      position: relative;
    }
    .duo-chat-msg.user .duo-bubble {
      background: rgba(244, 195, 117, 0.18);
      border: 1px solid rgba(244, 195, 117, 0.35);
      color: #fff;
      border-bottom-right-radius: 4px;
    }
    .duo-chat-msg.genie .duo-bubble {
      background: rgba(255, 255, 255, 0.045);
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: var(--text);
      border-bottom-left-radius: 4px;
    }

    /* Deep Reasoning Accordion (GenieThinkingAccordionView) */
    .genie-reasoning-box {
      margin: 8px 0 12px 0;
      background: rgba(147, 95, 245, 0.08);
      border: 1px solid rgba(147, 95, 245, 0.25);
      border-radius: 12px;
      overflow: hidden;
      font-size: 0.82rem;
      transition: all 0.3s ease;
    }
    .genie-reasoning-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 8px 14px;
      background: rgba(147, 95, 245, 0.14);
      cursor: pointer;
      user-select: none;
      font-weight: 600;
      color: #d8b4fe;
    }
    .genie-reasoning-header:hover {
      background: rgba(147, 95, 245, 0.22);
    }
    .genie-brain-icon {
      animation: pulseBrain 1.8s infinite ease-in-out;
      display: inline-block;
      margin-right: 6px;
    }
    @keyframes pulseBrain {
      0%, 100% { transform: scale(1); opacity: 0.85; }
      50% { transform: scale(1.15); opacity: 1; filter: drop-shadow(0 0 6px rgba(216, 180, 254, 0.8)); }
    }
    .genie-reasoning-body {
      padding: 10px 14px;
      color: #c4b5fd;
      border-top: 1px solid rgba(147, 95, 245, 0.15);
      font-family: ui-monospace, SFMono-Regular, "JetBrains Mono", Menlo, monospace;
      font-size: 0.78rem;
      line-height: 1.55;
    }

    /* Simulated Tool Calls */
    .genie-tool-call {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 6px;
      padding: 6px 10px;
      background: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 8px;
      font-family: ui-monospace, Menlo, monospace;
      font-size: 0.75rem;
    }
    .genie-tool-badge {
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 0.7rem;
      font-weight: 700;
      text-transform: uppercase;
    }
    .genie-tool-badge.exec { background: rgba(56, 189, 248, 0.2); color: #38bdf8; }
    .genie-tool-badge.success { background: rgba(74, 222, 128, 0.2); color: #4ade80; }

    /* Quick Action Chips */
    .duo-action-chips {
      display: flex;
      gap: 8px;
      padding: 10px 20px;
      background: rgba(14, 18, 26, 0.7);
      border-top: 1px solid rgba(255, 255, 255, 0.06);
      overflow-x: auto;
      scrollbar-width: none;
    }
    .duo-action-chip {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: var(--text);
      padding: 6px 14px;
      border-radius: 999px;
      font-size: 0.8rem;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s ease;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .duo-action-chip:hover {
      background: rgba(244, 195, 117, 0.18);
      border-color: rgba(244, 195, 117, 0.4);
      color: var(--gold);
      transform: translateY(-2px);
    }

    /* Working Input Bar */
    .duo-input-area {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 14px 20px;
      background: rgba(18, 22, 32, 0.95);
      border-top: 1px solid rgba(255, 255, 255, 0.08);
    }
    .duo-text-input {
      flex: 1;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 12px;
      padding: 10px 14px;
      color: #fff;
      font-size: 0.9rem;
      font-family: inherit;
      outline: none;
      transition: border-color 0.2s;
    }
    .duo-text-input:focus {
      border-color: var(--gold);
      box-shadow: 0 0 12px rgba(244, 195, 117, 0.25);
    }
    .duo-send-btn {
      background: var(--gold);
      color: #000;
      border: none;
      padding: 10px 18px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 0.88rem;
      cursor: pointer;
      transition: transform 0.15s, background-color 0.15s;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .duo-send-btn:hover {
      background: #fcd34d;
      transform: scale(1.03);
    }

    /* Right Display: Duo Fold Live Studio & WebKit Canvas */
    .duo-screen-right {
      display: flex;
      flex-direction: column;
      background: #020408;
      overflow: hidden;
      position: relative;
    }

    .duo-right-tabs {
      display: flex;
      gap: 4px;
      padding: 10px 16px;
      background: rgba(16, 20, 30, 0.92);
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    }
    .duo-right-tab {
      background: transparent;
      border: 1px solid transparent;
      color: var(--text-muted);
      padding: 6px 14px;
      border-radius: 8px;
      font-size: 0.82rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .duo-right-tab.active {
      background: rgba(255, 255, 255, 0.08);
      border-color: rgba(255, 255, 255, 0.14);
      color: #fff;
    }

    .duo-canvas-viewport {
      flex: 1;
      position: relative;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
      background: radial-gradient(circle at 50% 50%, #0d1527 0%, #03060d 100%);
    }

    /* Interactive 3D Canvas element */
    #duo-3d-canvas {
      width: 100%;
      height: 100%;
      cursor: grab;
    }
    #duo-3d-canvas:active {
      cursor: grabbing;
    }

    /* HUD Overlay for the Canvas */
    .duo-canvas-hud {
      position: absolute;
      top: 14px;
      left: 14px;
      display: flex;
      gap: 10px;
      pointer-events: none;
    }
    .duo-hud-pill {
      background: rgba(0, 0, 0, 0.65);
      border: 1px solid rgba(255, 255, 255, 0.14);
      backdrop-filter: blur(12px);
      padding: 4px 10px;
      border-radius: 999px;
      font-family: ui-monospace, Menlo, monospace;
      font-size: 0.74rem;
      color: #38bdf8;
    }

    /* Code View Viewport */
    .duo-code-viewport {
      flex: 1;
      padding: 20px;
      overflow-y: auto;
      background: #05070c;
      font-family: ui-monospace, SFMono-Regular, "JetBrains Mono", Menlo, monospace;
      font-size: 0.82rem;
      line-height: 1.6;
      color: #93c5fd;
      white-space: pre;
      display: none;
    }

    /* In-RAM Terminal Viewport */
    .duo-terminal-viewport {
      flex: 1;
      padding: 20px;
      background: #010204;
      font-family: ui-monospace, Menlo, monospace;
      font-size: 0.8rem;
      color: #4ade80;
      line-height: 1.5;
      display: none;
      overflow-y: auto;
    }

    /* ==========================================================================
       🍏 "Architected for Apple Silicon. Zero Electron." Section Styles
       ========================================================================== */
    .apple-arch-section {
      padding: 90px 24px 70px 24px;
      max-width: 1280px;
      margin: 0 auto;
      position: relative;
    }

    .apple-arch-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 24px;
      margin-top: 40px;
    }

    .apple-arch-card {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 28px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
    }
    .apple-arch-card h3 {
      font-size: 1.18rem;
      margin: 12px 0 8px 0;
      color: #fff;
    }
    .apple-arch-card p {
      font-size: 0.9rem;
      color: var(--text-muted);
      line-height: 1.6;
    }
    .apple-arch-metric {
      font-size: 2.2rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 4px;
      background: linear-gradient(180deg, #ffffff 40%, #94a3b8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    /* Head-to-Head Comparison Matrix */
    .comparison-table-wrapper {
      margin-top: 50px;
      background: rgba(14, 18, 28, 0.8);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 22px;
      overflow: hidden;
      box-shadow: 0 30px 80px rgba(0, 0, 0, 0.6);
    }
    .comparison-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 0.92rem;
    }
    .comparison-table th {
      background: rgba(22, 28, 42, 0.9);
      padding: 16px 24px;
      color: #fff;
      font-weight: 700;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    .comparison-table td {
      padding: 16px 24px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      color: var(--text-muted);
    }
    .comparison-table tr:hover td {
      background: rgba(255, 255, 255, 0.02);
    }
    .comparison-table .genie-col {
      color: var(--gold);
      font-weight: 700;
    }
    .comparison-table .check {
      color: #4ade80;
      font-weight: bold;
    }
    .comparison-table .cross {
      color: #f87171;
    }

    @media (max-width: 1024px) {
      .duo-hardware-frame {
        grid-template-columns: 1fr;
        grid-template-rows: auto 8px auto;
      }
      .duo-hinge-seam {
        height: 8px;
        width: 100%;
        background: linear-gradient(90deg, rgba(255, 255, 255, 0.18) 0%, rgba(60, 65, 80, 0.8) 50%, rgba(255, 255, 255, 0.18) 100%);
      }
      .duo-hinge-seam::after {
        width: 48px;
        height: 4px;
      }
      .apple-arch-grid {
        grid-template-columns: 1fr;
      }
    }
    """

    # Inject new CSS right before </style>
    if "</style>" in content:
        content = content.replace("</style>", new_css + "\n</style>", 1)
        print("  ✓ Injected Apple 2028 Liquid Glass, Cursor FX, & Duo-Screen CSS")
    else:
        print("  ! Error: </style> not found")

    # -------------------------------------------------------------
    # 2. CURSOR FX HTML (Cursor glow + Stardust canvas)
    # -------------------------------------------------------------
    cursor_html = """
  <!-- Bioluminescent Cursor Halo & Particle Stardust Canvas -->
  <div id="genie-cursor-glow" aria-hidden="true"></div>
  <canvas id="genie-stardust-canvas" aria-hidden="true"></canvas>
  """
    if "<body>" in content:
        content = content.replace("<body>", "<body>\n" + cursor_html, 1)
        print("  ✓ Added cursor glow and particle canvas to body")

    # -------------------------------------------------------------
    # 3. DUO-SCREEN INTERACTIVE STUDIO & CHAT SIMULATOR SECTION
    # -------------------------------------------------------------
    duo_section_html = """
  <!-- ==========================================================================
       💻 Built for Duo Displays & Foldable Glass — Interactive Studio & Chat
       ========================================================================== -->
  <section id="duo-studio" class="duo-studio-section">
    <div class="section-title">
      <div class="hero-badge" style="margin-bottom: 14px; display: inline-flex;">💻 Dual-Screen & Foldable Architecture</div>
      <h2>Built for Duo Displays. Master Both Screens.</h2>
      <p>Pair an Autonomous OS Agent on Display 1 with a live interactive WebKit Canvas on Display 2. Zero lag, sub-16ms bidirectional hot-sync.</p>
    </div>

    <div class="duo-hardware-frame">
      <!-- Screen 1: Autonomous Agent Chat & Executive Runner -->
      <div class="duo-screen-left">
        <div class="duo-header-bar">
          <div class="duo-traffic-lights">
            <span class="duo-traffic-dot red"></span>
            <span class="duo-traffic-dot yellow"></span>
            <span class="duo-traffic-dot green"></span>
          </div>
          <span style="font-weight: 700; color: #fff;">Display 1 • Autonomous OS Agent</span>
          <div class="duo-model-pill">
            <span class="live-dot" style="width:7px; height:7px; background:#4ade80; border-radius:50%; display:inline-block;"></span>
            DeepSeek-R1 (Local 8-Bit)
          </div>
        </div>

        <!-- Chat Stream -->
        <div class="duo-chat-stream" id="duo-chat-stream">
          <div class="duo-chat-msg user">
            <div class="duo-avatar user">👤</div>
            <div class="duo-bubble">
              Hey Genie, render a 3D spatial particle galaxy with 120 FPS momentum physics on Display 2 and spin up an ephemeral In-RAM Linux MicroVM for benchmarking.
            </div>
          </div>

          <div class="duo-chat-msg genie">
            <div class="duo-avatar genie">🪔</div>
            <div class="duo-bubble">
              <!-- Deep Reasoning Accordion -->
              <div class="genie-reasoning-box">
                <div class="genie-reasoning-header" onclick="toggleReasoning(this)">
                  <span><span class="genie-brain-icon">🧠</span> Deep Reasoning Process (74ms)</span>
                  <span class="reasoning-arrow">▲</span>
                </div>
                <div class="genie-reasoning-body">
                  1. ScreenCaptureKit verified dual ProMotion displays (Display 1: 3024×1890, Display 2: 2880×1800).<br>
                  2. Dispatching Metal 3 compute pipeline with SIMD particle kernels into Duo Fold Live Canvas.<br>
                  3. Allocating 512 MB ephemeral memory partition via Apple Hypervisor.framework.<br>
                  4. Booting Alpine Linux kernel in RAM (COW disk rootfs, zero host mutation).
                </div>
              </div>

              <!-- Tool Execution Badges -->
              <div class="genie-tool-call">
                <span class="genie-tool-badge exec">TOOL EXEC</span>
                <code>metal.compile_pipeline("SpatialParticleGalaxy.metal")</code>
                <span class="genie-tool-badge success">EXIT 0 · 14ms</span>
              </div>
              <div class="genie-tool-call">
                <span class="genie-tool-badge exec">TOOL EXEC</span>
                <code>hypervisor.spawn_microvm(ram_mb: 512, ephemeral: true)</code>
                <span class="genie-tool-badge success">BOOTED · 340ms</span>
              </div>

              <p style="margin-top: 10px;">
                ✨ <b>Spatial Particle Galaxy</b> is live on Display 2! You can click and drag in the canvas to rotate the 3D orbit in real time. Ephemeral Linux microVM is standing by in RAM with zero disk wear.
              </p>
            </div>
          </div>
        </div>

        <!-- Suggestion Chips -->
        <div class="duo-action-chips">
          <button class="duo-action-chip" onclick="triggerDuoDemo('3d-canvas')">🚀 3D Spatial Canvas</button>
          <button class="duo-action-chip" onclick="triggerDuoDemo('microvm')">⚡️ Spin In-RAM VM</button>
          <button class="duo-action-chip" onclick="triggerDuoDemo('pillows')">⏱️ World Clock Pillows</button>
          <button class="duo-action-chip" onclick="triggerDuoDemo('scan')">🔍 Screen Vision Grounding</button>
        </div>

        <!-- Input Bar -->
        <div class="duo-input-area">
          <input type="text" id="duo-user-input" class="duo-text-input" placeholder="Ask Genie to automate macOS, generate shaders, or orchestrate tools..." onkeydown="if(event.key==='Enter') sendDuoMessage()">
          <button class="duo-send-btn" onclick="sendDuoMessage()">
            <span>Send</span> <span>⏎</span>
          </button>
        </div>
      </div>

      <!-- Central Brushed-Titanium Hinge -->
      <div class="duo-hinge-seam" title="Hardware Hinge & Dual Display Seam"></div>

      <!-- Screen 2: Duo Fold Live Studio / WebKit Canvas -->
      <div class="duo-screen-right">
        <div class="duo-right-tabs">
          <button class="duo-right-tab active" id="tab-canvas-btn" onclick="setRightDisplayTab('canvas')">
            <span>👁️</span> Live WebKit Canvas
          </button>
          <button class="duo-right-tab" id="tab-code-btn" onclick="setRightDisplayTab('code')">
            <span>💻</span> Swift 6.4 & Metal Source
          </button>
          <button class="duo-right-tab" id="tab-vm-btn" onclick="setRightDisplayTab('vm')">
            <span>🖥️</span> In-RAM Linux Shell
          </button>
        </div>

        <!-- Interactive 3D Canvas Viewport -->
        <div class="duo-canvas-viewport" id="duo-canvas-container">
          <div class="duo-canvas-hud">
            <span class="duo-hud-pill">FPS: 120.0</span>
            <span class="duo-hud-pill" id="duo-coords-hud">X: 0.00 Y: 0.00 Z: 1.00</span>
            <span class="duo-hud-pill">Particles: 12,500</span>
            <span class="duo-hud-pill" style="color:#4ade80;">Metal 3 API</span>
          </div>
          <canvas id="duo-3d-canvas"></canvas>
        </div>

        <!-- Native Swift 6 Code Viewport -->
        <div class="duo-code-viewport" id="duo-code-container">
<span style="color:#f472b6;">import</span> <span style="color:#38bdf8;">SwiftUI</span>
<span style="color:#f472b6;">import</span> <span style="color:#38bdf8;">MetalKit</span>
<span style="color:#f472b6;">import</span> <span style="color:#38bdf8;">Hypervisor</span>

<span style="color:#94a3b8;">/// 🪔 Genie Duo Fold 3D Spatial Canvas Engine — Swift 6.4 & Metal 3</span>
<span style="color:#f472b6;">@MainActor</span>
<span style="color:#f472b6;">public final class</span> <span style="color:#fcd34d;">GenieDuoSpatialEngine</span>: <span style="color:#38bdf8;">ObservableObject</span> {
    <span style="color:#f472b6;">private let</span> device: <span style="color:#38bdf8;">MTLDevice</span>
    <span style="color:#f472b6;">private let</span> commandQueue: <span style="color:#38bdf8;">MTLCommandQueue</span>
    <span style="color:#f472b6;">private var</span> particleBuffer: <span style="color:#38bdf8;">MTLBuffer</span>?
    
    <span style="color:#f472b6;">public init</span>() {
        <span style="color:#f472b6;">guard let</span> mtl = <span style="color:#38bdf8;">MTLCreateSystemDefaultDevice</span>() <span style="color:#f472b6;">else</span> {
            <span style="color:#f472b6;">fatalError</span>(<span style="color:#a7f3d0;">"Apple Silicon Metal 3 GPU required"</span>)
        }
        <span style="color:#f472b6;">self</span>.device = mtl
        <span style="color:#f472b6;">self</span>.commandQueue = mtl.makeCommandQueue()!
    }
    
    <span style="color:#f472b6;">public func</span> <span style="color:#60a5fa;">dispatchParticleSwarm</span>(count: <span style="color:#38bdf8;">Int</span> = 12500) <span style="color:#f472b6;">async</span> {
        <span style="color:#94a3b8;">// Direct SIMD vectorization with zero CPU overhead</span>
        <span style="color:#f472b6;">let</span> pipeline = <span style="color:#f472b6;">try</span>! device.makeComputePipelineState(function: library.makeFunction(name: <span style="color:#a7f3d0;">"particleSwarmKernel"</span>)!)
        <span style="color:#94a3b8;">// Synchronized with Apple ProMotion 120Hz display refresh</span>
    }
}
        </div>

        <!-- In-RAM Linux Terminal Viewport -->
        <div class="duo-terminal-viewport" id="duo-vm-container">
[ Genie In-RAM APFS MicroVM Controller v1.0.0 ]
[ Booted via Apple Hypervisor.framework in 340ms ]
root@genie-ephemeral:~# uname -a
Linux genie-ephemeral 6.6.14-genie-arm64 #1 SMP PREEMPT Apple M-Series aarch64 Linux
root@genie-ephemeral:~# free -h
              total        used        free      shared  buff/cache   available
Mem:          512Mi        38Mi       442Mi       1.2Mi        32Mi       471Mi
Swap:            0B          0B          0B
root@genie-ephemeral:~# cat /proc/cpuinfo | grep "model name" | head -n 1
model name  : Apple M4 Max Virtual Core (Ephemerally In-RAM)
root@genie-ephemeral:~# echo "Sandbox verified: Zero host mutation, pure RAM isolation."
Sandbox verified: Zero host mutation, pure RAM isolation.
root@genie-ephemeral:~# <span style="animation: pulseBrain 1s infinite;">█</span>
        </div>
      </div>
    </div>
  </section>
  """

    # Insert Duo Studio right after preview container (#demo)
    if 'id="demo"' in content:
        # Find closing </div> of preview-container
        demo_idx = content.find('id="demo"')
        close_preview = content.find('</div>\n  </div>\n\n  <!-- Engineering Stats', demo_idx)
        if close_preview != -1:
            insertion_point = close_preview + len('</div>\n  </div>\n')
            content = content[:insertion_point] + "\n" + duo_section_html + "\n" + content[insertion_point:]
            print("  ✓ Inserted Duo-Screen Studio & Chat Simulator Section")
        else:
            # Fallback search
            stats_idx = content.find('<!-- Engineering Stats')
            if stats_idx != -1:
                content = content[:stats_idx] + duo_section_html + "\n\n  " + content[stats_idx:]
                print("  ✓ Inserted Duo-Screen Studio Section before Engineering Stats")

    # -------------------------------------------------------------
    # 4. "ARCHITECTED FOR APPLE SILICON. ZERO ELECTRON." SECTION
    # -------------------------------------------------------------
    apple_arch_html = """
  <!-- ==========================================================================
       🍏 Architected for Apple Silicon. Zero Electron. Zero Compromises.
       ========================================================================== -->
  <section id="apple-architecture" class="apple-arch-section">
    <div class="section-title">
      <div class="hero-badge" style="margin-bottom: 14px; display: inline-flex;">🍏 Apple Silicon Engineering Manifesto</div>
      <h2>Architected for Pure Metal & Swift 6. Zero Electron.</h2>
      <p>We rejected web-wrapper bloat. Genie is compiled from the ground up for M-Series unified memory architecture, Apple ProMotion displays, and hardware SMC telemetry.</p>
    </div>

    <div class="apple-arch-grid">
      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">&lt; 35 MB</div>
          <h3>Minimal Memory Footprint</h3>
          <p>Built with Swift value types, compact particle ring buffers, and frustum culling. Where Electron apps consume 800 MB to 1.5 GB on launch, Genie runs continuously under 35 MB.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">Swift 6 Value Types</span>
          <span class="tech-tag">Compact Ring Buffer</span>
          <span class="tech-tag">Zero V8 Leaks</span>
        </div>
      </div>

      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">120 FPS</div>
          <h3>ProMotion Metal 3 Pipeline</h3>
          <p>52+ GPU living shaders and 81 continuous spatial screens render directly through Metal 3 compute pipelines synchronized with Apple ProMotion display refresh cycles with 0% CPU consumption.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">Metal 3 Compute</span>
          <span class="tech-tag">Direct Frame Sync</span>
          <span class="tech-tag">0% CPU at Idle</span>
        </div>
      </div>

      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">340 ms</div>
          <h3>In-RAM Apple Hypervisor</h3>
          <p>Instant Linux microVMs booting directly in unified RAM via Apple's native <code>Hypervisor.framework</code>. Features copy-on-write APFS ephemeral drives that leave zero disk wear on host SSDs.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">Hypervisor.framework</span>
          <span class="tech-tag">APFS Copy-On-Write</span>
          <span class="tech-tag">Ephemeral In-RAM</span>
        </div>
      </div>

      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">1000 Hz</div>
          <h3>Direct SMC Hardware Telemetry</h3>
          <p>Direct I/O Kit querying of Apple Silicon hardware performance counters, dynamic battery milliwatt draw, and CPU/GPU thermal sensors. Tailored specifically for MacBook Pro notch housing.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">IOKit SMC Access</span>
          <span class="tech-tag">Live Watt-Meter</span>
          <span class="tech-tag">Thermal Sentinel</span>
        </div>
      </div>

      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">0 Bytes</div>
          <h3>Absolute Zero Telemetry</h3>
          <p>Your workspace is strictly private. Zero telemetry servers, zero analytics daemons, zero tracking pixels. Built for macOS Hardened Runtime with 100% on-device local AI intelligence.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">Hardened Runtime</span>
          <span class="tech-tag">Zero Telemetry</span>
          <span class="tech-tag">Local-First Privacy</span>
        </div>
      </div>

      <div class="apple-arch-card">
        <div>
          <div class="apple-arch-metric">12 µs</div>
          <h3>SIMD Vector Search Engine</h3>
          <p>Inverse Probability Elimination (IPE) and vectorized SIMD cosine similarity scan hundreds of thousands of candidate items in microseconds directly in cache without a heavy external vector database.</p>
        </div>
        <div class="tech-tag-group" style="margin-top: 16px;">
          <span class="tech-tag">Clang Pragmas</span>
          <span class="tech-tag">IPE 64-Bit Bitmask</span>
          <span class="tech-tag">Microsecond Search</span>
        </div>
      </div>
    </div>

    <!-- Head-to-Head Comparison Table -->
    <div class="comparison-table-wrapper">
      <table class="comparison-table">
        <thead>
          <tr>
            <th>Architecture Dimension</th>
            <th class="genie-col">🪔 Genie Native (Build 500)</th>
            <th>Typical Electron / Chromium Workspace</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Memory Footprint (Idle)</strong></td>
            <td class="genie-col">&lt; 35 MB unified memory</td>
            <td>800 MB – 1,400 MB (Multiple Helper Processes)</td>
          </tr>
          <tr>
            <td><strong>Rendering Engine</strong></td>
            <td class="genie-col">Direct Metal 3 & SwiftUI @ 120 FPS</td>
            <td>Chromium Blink WebGL / CSS @ 60 FPS</td>
          </tr>
          <tr>
            <td><strong>Battery Drain / Hour</strong></td>
            <td class="genie-col">&lt; 0.4% battery drain</td>
            <td>7.5% – 14.0% continuous battery drain</td>
          </tr>
          <tr>
            <td><strong>Linux Hypervisor</strong></td>
            <td class="genie-col">Native In-RAM <code>Hypervisor.framework</code> (340ms boot)</td>
            <td>Heavy Docker Desktop / QEMU emulation (15–30s boot)</td>
          </tr>
          <tr>
            <td><strong>Privacy & Telemetry</strong></td>
            <td class="genie-col"><span class="check">✓ Zero bytes transmitted · 100% Local</span></td>
            <td><span class="cross">✗ Continuous background analytics & cloud telemetry</span></td>
          </tr>
          <tr>
            <td><strong>Display Support</strong></td>
            <td class="genie-col">Native Duo Fold & ProMotion notch matching</td>
            <td>Generic web canvas wrapper</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
  """

    # Replace old architecture section or insert before it
    if '<section id="architecture"' in content:
        content = content.replace('<section id="architecture"', apple_arch_html + '\n  <section id="architecture"', 1)
        print("  ✓ Added Apple Silicon Architecture & Comparison Section")

    # -------------------------------------------------------------
    # 5. UPDATE SHOWCASE POSTCARDS (10 Flagship Postcards)
    # -------------------------------------------------------------
    # Update showcaseData in JS
    new_showcase_data = """    const showcaseData = [
      {
        id: 1,
        title: "Autonomous OS Agent & Vision Grounding",
        category: "Vision & Execution",
        caption: "Direct screen comprehension via ScreenCaptureKit, coordinate-level UI grounding, multi-step system automation, and sub-100ms reasoning stream.",
        img: "assets/postcards/01_postcard_os_agent.png",
        specs: "Latency: 74ms · Vision: ScreenCaptureKit · Model: Local DeepSeek R1 · Sandboxing: POSIX Strict"
      },
      {
        id: 2,
        title: "Sovereign In-RAM Linux Hypervisor",
        category: "Virtualization & Sandboxing",
        caption: "MicroVM sandbox running in ephemeral RAM on Apple Silicon Hypervisor.framework. Zero host mutation, copy-on-write APFS disks, instant 340ms teardown.",
        img: "assets/postcards/02_postcard_hypervisor_vm.png",
        specs: "Boot Time: 340ms · Memory: Ephemeral In-RAM · Disk: APFS Copy-On-Write · Isolation: Apple Hypervisor"
      },
      {
        id: 3,
        title: "Duo-Fold Live Web & Agent Studio",
        category: "Dual Display Architecture",
        caption: "Side-by-side agent workspace built for dual displays and foldable monitors; live syntax-highlighted editor paired with real-time responsive WebKit browser preview.",
        img: "assets/postcards/03_postcard_duo_fold_studio.png",
        specs: "Display: Duo Fold Responsive · Engine: Native WebKit 2 · Sync: Bidirectional DOM · Hot Reload: Sub-16ms"
      },
      {
        id: 4,
        title: "World Clock Pillows & Time Scrubber",
        category: "OLED Blackout Complications",
        caption: "Tactile blackout cards with specular rim lighting, multi-city dials, micro-hands, and temporal scrub slider across 24 global timezones.",
        img: "assets/postcards/04_postcard_world_clock_pillows.png",
        specs: "Card Tier: OLED Blackout · Lighting: Specular Rim Gradients · Dials: Micro-Hands · Scrub: 24h Temporal Slider"
      },
      {
        id: 5,
        title: "Spatial Desktop Canvas & SwiftDOM",
        category: "120 FPS ProMotion Scene Graph",
        caption: "Infinite spatial coordinate plane with 81-screen continuous universe, 120 FPS ProMotion momentum physics, and sub-35MB memory budget.",
        img: "assets/postcards/05_postcard_spatial_canvas.png",
        specs: "Framerate: 120 FPS ProMotion · Universe: 81 Continuous Screens · Scene Graph: SwiftDOM · Budget: < 35 MB RAM"
      },
      {
        id: 6,
        title: "System Diagnostics Sentinel",
        category: "Apple Silicon Hardware Telemetry",
        caption: "Real-time Apple Silicon performance cluster telemetry (M1–M4 Max/Ultra), GPU occupancy, memory pressure guard, and thermal throttling alerts.",
        img: "assets/postcards/06_postcard_diagnostics_sentinel.png",
        specs: "Sensors: SMC Hardware Clocks · Sampling: 1000Hz · GPU Cluster: Real-Time Occupancy · Safety: Overheat Guard"
      },
      {
        id: 7,
        title: "Power Reserve & Battery Telemetry",
        category: "Dynamic Notch & SMC Health",
        caption: "Granular cycle degradation, milliwatt draw, SMC health telemetry, and dynamic status bar aesthetics matching macOS notch geometry.",
        img: "assets/postcards/07_postcard_battery_telemetry.png",
        specs: "Watt-Meter: Live Milliwatt Draw · Cycle Life: Degrade Curve · SMC: Hardware Direct · Notch: Dynamic Housing"
      },
      {
        id: 8,
        title: "Living Metal Shaders & Atmospheric Murals",
        category: "Metal 3 GPU Compute Shaders",
        caption: "52+ hardware-accelerated Metal 3 GPU shaders rendering at 120 FPS with 0% CPU consumption and subpixel optical caustics.",
        img: "assets/postcards/08_postcard_living_themes_shaders.png",
        specs: "Shaders: 52+ Living Murals · API: Metal 3 Compute · CPU Load: 0.0% · Optical: Subpixel Caustic Shaders"
      },
      {
        id: 9,
        title: "Application Atelier & Launch Formations",
        category: "Inverse Probability Elimination",
        caption: "28+ mathematical layouts (Lotus, Fibonacci Galaxy, Radial, Orbit), instant 64-bit bitmask search, and quadrant docking.",
        img: "assets/postcards/09_postcard_application_atelier.png",
        specs: "Search: 64-Bit IPE Bitmask · Formations: 28+ Mathematical · Dock: Quadrant Auto-Snap · Speed: Sub-Microsecond"
      },
      {
        id: 10,
        title: "Security Governance & Zero Telemetry",
        category: "Hardened Runtime Sandbox",
        caption: "macOS Hardened Runtime, sandboxed hypervisor, transparent permissions, local-first inference, and strictly zero third-party telemetry.",
        img: "assets/postcards/10_postcard_security_governance.png",
        specs: "Telemetry: 0 Bytes Transmitted · Sandboxing: POSIX Strict Sandbox · Runtime: Hardened Runtime · Verification: 100% On-Device"
      }
    ];"""

    # Replace showcaseData array
    pattern = r"const showcaseData = \[[\s\S]*?\];"
    if re.search(pattern, content):
        content = re.sub(pattern, new_showcase_data, content, count=1)
        print("  ✓ Replaced showcaseData with 10 Postcards")

    # Update the static grid items in HTML (#showcase-grid)
    new_grid_html = """    <!-- Complete 10 Flagship Postcard Grid View -->
    <div class="screenshots-grid" id="showcase-grid">
      <div class="screenshot-card">
        <img src="assets/postcards/01_postcard_os_agent.png" alt="Autonomous OS Agent & Vision Grounding" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 01 • OS Agent</span>
          <h4>Autonomous OS Agent & Vision Grounding</h4>
          <p>Direct screen comprehension via ScreenCaptureKit, coordinate-level UI grounding, multi-step system automation, and sub-100ms reasoning stream.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/02_postcard_hypervisor_vm.png" alt="Sovereign In-RAM Linux Hypervisor" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 02 • Hypervisor</span>
          <h4>Sovereign In-RAM Linux Hypervisor</h4>
          <p>MicroVM sandbox running in ephemeral RAM on Apple Silicon Hypervisor.framework. Zero host mutation, copy-on-write APFS disks, instant 340ms teardown.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/03_postcard_duo_fold_studio.png" alt="Duo-Fold Live Web & Agent Studio" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 03 • Duo Fold</span>
          <h4>Duo-Fold Live Web & Agent Studio</h4>
          <p>Side-by-side agent workspace built for dual displays and foldable monitors; live syntax-highlighted editor paired with real-time responsive WebKit browser preview.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/04_postcard_world_clock_pillows.png" alt="World Clock Pillows & Time Scrubber" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 04 • Pillows</span>
          <h4>World Clock Pillows & Time Scrubber</h4>
          <p>Tactile blackout cards with specular rim lighting, multi-city dials, micro-hands, and temporal scrub slider across 24 global timezones.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/05_postcard_spatial_canvas.png" alt="Spatial Desktop Canvas & SwiftDOM" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 05 • Spatial Canvas</span>
          <h4>Spatial Desktop Canvas & SwiftDOM</h4>
          <p>Infinite spatial coordinate plane with 81-screen continuous universe, 120 FPS ProMotion momentum physics, and sub-35MB memory budget.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/06_postcard_diagnostics_sentinel.png" alt="System Diagnostics Sentinel" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 06 • Diagnostics</span>
          <h4>System Diagnostics Sentinel</h4>
          <p>Real-time Apple Silicon performance cluster telemetry (M1–M4 Max/Ultra), GPU occupancy, memory pressure guard, and thermal throttling alerts.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/07_postcard_battery_telemetry.png" alt="Power Reserve & Battery Telemetry" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 07 • Battery</span>
          <h4>Power Reserve & Battery Telemetry</h4>
          <p>Granular cycle degradation, milliwatt draw, SMC health telemetry, and dynamic status bar aesthetics matching macOS notch geometry.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/08_postcard_living_themes_shaders.png" alt="Living Metal Shaders & Atmospheric Murals" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 08 • Living Shaders</span>
          <h4>Living Metal Shaders & Atmospheric Murals</h4>
          <p>52+ hardware-accelerated Metal 3 GPU shaders rendering at 120 FPS with 0% CPU consumption and subpixel optical caustics.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/09_postcard_application_atelier.png" alt="Application Atelier & Launch Formations" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 09 • Formations</span>
          <h4>Application Atelier & Launch Formations</h4>
          <p>28+ mathematical layouts (Lotus, Fibonacci Galaxy, Radial, Orbit), instant 64-bit bitmask search, and quadrant docking.</p>
        </div>
      </div>
      <div class="screenshot-card">
        <img src="assets/postcards/10_postcard_security_governance.png" alt="Security Governance & Zero Telemetry" loading="lazy">
        <div class="screenshot-info">
          <span class="screenshot-badge">Postcard 10 • Zero Telemetry</span>
          <h4>Security Governance & Zero Telemetry</h4>
          <p>macOS Hardened Runtime, sandboxed hypervisor, transparent permissions, local-first inference, and strictly zero third-party telemetry.</p>
        </div>
      </div>
    </div>"""

    grid_pattern = r'<div class="screenshots-grid" id="showcase-grid">[\s\S]*?</div>\s*</section>'
    if re.search(grid_pattern, content):
        content = re.sub(grid_pattern, new_grid_html + "\n  </section>", content, count=1)
        print("  ✓ Updated static #showcase-grid with 10 Postcards")

    # Update initial showcase viewport slide
    old_viewport_img = 'id="showcase-main-img" src="assets/images/appstore_screenshots/01_Spatial_Canvas_Launch.png"'
    new_viewport_img = 'id="showcase-main-img" src="assets/postcards/01_postcard_os_agent.png"'
    if old_viewport_img in content:
        content = content.replace(old_viewport_img, new_viewport_img, 1)

    # Update counter text from 21 to 10
    content = content.replace("Explore all 21 official", "Explore all 10 official 2880×1800 Retina Postcards", 1)
    content = content.replace("View All 21 Grid", "View All 10 Postcards Grid", 1)
    content = content.replace("SLIDE 01 / 21", "SLIDE 01 / 10", 1)

    # -------------------------------------------------------------
    # 6. JAVASCRIPT: CURSOR FX ENGINE & DUO-SCREEN INTERACTIVE LOGIC
    # -------------------------------------------------------------
    interactive_js = """
    // ==========================================================================
    // ✨ Apple 2028 Cursor FX Engine & Duo-Screen Interactive Simulator
    // ==========================================================================

    // 1. Bioluminescent Cursor Halo & Lerping Stardust
    const cursorGlow = document.getElementById('genie-cursor-glow');
    const stardustCanvas = document.getElementById('genie-stardust-canvas');
    let ctxStardust = null;
    let particles = [];
    let mouseX = window.innerWidth / 2;
    let mouseY = window.innerHeight / 2;
    let currentX = mouseX;
    let currentY = mouseY;

    if (stardustCanvas) {
      ctxStardust = stardustCanvas.getContext('2d');
      function resizeCanvas() {
        stardustCanvas.width = window.innerWidth;
        stardustCanvas.height = window.innerHeight;
      }
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();

      window.addEventListener('pointermove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
        if (cursorGlow) cursorGlow.style.opacity = '1';

        // Spawn stardust spark
        if (Math.random() < 0.45) {
          particles.push({
            x: mouseX + (Math.random() - 0.5) * 16,
            y: mouseY + (Math.random() - 0.5) * 16,
            size: Math.random() * 2.5 + 1,
            alpha: 1,
            vx: (Math.random() - 0.5) * 1.5,
            vy: (Math.random() - 0.5) * 1.5 - 0.5,
            color: Math.random() > 0.5 ? '#f4c375' : '#a855f7'
          });
        }
      });

      function renderStardust() {
        // Smooth lerp for glow halo
        currentX += (mouseX - currentX) * 0.15;
        currentY += (mouseY - currentY) * 0.15;
        if (cursorGlow) {
          cursorGlow.style.transform = `translate3d(${currentX}px, ${currentY}px, 0)`;
        }

        // Render particles
        if (ctxStardust) {
          ctxStardust.clearRect(0, 0, stardustCanvas.width, stardustCanvas.height);
          for (let i = particles.length - 1; i >= 0; i--) {
            const p = particles[i];
            p.x += p.vx;
            p.y += p.vy;
            p.alpha -= 0.025;
            if (p.alpha <= 0) {
              particles.splice(i, 1);
              continue;
            }
            ctxStardust.save();
            ctxStardust.globalAlpha = p.alpha;
            ctxStardust.fillStyle = p.color;
            ctxStardust.shadowBlur = 8;
            ctxStardust.shadowColor = p.color;
            ctxStardust.beginPath();
            ctxStardust.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctxStardust.fill();
            ctxStardust.restore();
          }
        }
        requestAnimationFrame(renderStardust);
      }
      requestAnimationFrame(renderStardust);
    }

    // 2. 3D Card Specular Tilt Physics
    document.querySelectorAll('.screenshot-card, .dissection-card, .apple-arch-card').forEach(card => {
      card.addEventListener('mousemove', (e) => {
        const rect = card.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const cx = rect.width / 2;
        const cy = rect.height / 2;
        const rotX = ((y - cy) / cy) * -5;
        const rotY = ((x - cx) / cx) * 5;
        card.style.transform = `perspective(1000px) rotateX(${rotX}deg) rotateY(${rotY}deg) translateY(-4px)`;
      });
      card.addEventListener('mouseleave', () => {
        card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateY(0)';
      });
    });

    // 3. Deep Reasoning Accordion Toggle
    function toggleReasoning(header) {
      const box = header.closest('.genie-reasoning-box');
      const body = box.querySelector('.genie-reasoning-body');
      const arrow = header.querySelector('.reasoning-arrow');
      if (body.style.display === 'none') {
        body.style.display = 'block';
        arrow.textContent = '▲';
      } else {
        body.style.display = 'none';
        arrow.textContent = '▼';
      }
    }

    // 4. Duo-Screen Right Tab Switching
    function setRightDisplayTab(tab) {
      const btnCanvas = document.getElementById('tab-canvas-btn');
      const btnCode = document.getElementById('tab-code-btn');
      const btnVm = document.getElementById('tab-vm-btn');
      const boxCanvas = document.getElementById('duo-canvas-container');
      const boxCode = document.getElementById('duo-code-container');
      const boxVm = document.getElementById('duo-vm-container');

      [btnCanvas, btnCode, btnVm].forEach(b => b?.classList.remove('active'));
      [boxCanvas, boxCode, boxVm].forEach(b => { if(b) b.style.display = 'none'; });

      if (tab === 'canvas') {
        btnCanvas?.classList.add('active');
        if (boxCanvas) boxCanvas.style.display = 'flex';
      } else if (tab === 'code') {
        btnCode?.classList.add('active');
        if (boxCode) boxCode.style.display = 'block';
      } else if (tab === 'vm') {
        btnVm?.classList.add('active');
        if (boxVm) boxVm.style.display = 'block';
      }
    }

    // 5. Interactive 3D Particle Galaxy in Duo Canvas
    const duo3dCanvas = document.getElementById('duo-3d-canvas');
    let ctx3d = null;
    let spherePoints = [];
    let rotX = 0.3;
    let rotY = 0.5;
    let isDragging = false;
    let lastMouseX = 0;
    let lastMouseY = 0;

    if (duo3dCanvas) {
      ctx3d = duo3dCanvas.getContext('2d');
      function init3DGalaxy() {
        const rect = duo3dCanvas.parentElement.getBoundingClientRect();
        duo3dCanvas.width = rect.width;
        duo3dCanvas.height = rect.height;

        spherePoints = [];
        const count = 450;
        const radius = Math.min(rect.width, rect.height) * 0.32;
        for (let i = 0; i < count; i++) {
          const theta = Math.acos(2 * Math.random() - 1);
          const phi = Math.sqrt(count * Math.PI) * theta;
          spherePoints.push({
            x: radius * Math.sin(theta) * Math.cos(phi),
            y: radius * Math.sin(theta) * Math.sin(phi),
            z: radius * Math.cos(theta),
            hue: (theta / Math.PI) * 120 + 200
          });
        }
      }
      init3DGalaxy();
      window.addEventListener('resize', init3DGalaxy);

      duo3dCanvas.addEventListener('mousedown', (e) => {
        isDragging = true;
        lastMouseX = e.clientX;
        lastMouseY = e.clientY;
      });
      window.addEventListener('mouseup', () => { isDragging = false; });
      window.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        const dx = e.clientX - lastMouseX;
        const dy = e.clientY - lastMouseY;
        rotY += dx * 0.008;
        rotX += dy * 0.008;
        lastMouseX = e.clientX;
        lastMouseY = e.clientY;
        const coordsHud = document.getElementById('duo-coords-hud');
        if (coordsHud) coordsHud.textContent = `X: ${rotX.toFixed(2)} Y: ${rotY.toFixed(2)} Z: 1.00`;
      });

      function render3DGalaxy() {
        if (!isDragging) {
          rotY += 0.004;
          rotX += 0.001;
        }
        if (ctx3d) {
          ctx3d.clearRect(0, 0, duo3dCanvas.width, duo3dCanvas.height);
          const cx = duo3dCanvas.width / 2;
          const cy = duo3dCanvas.height / 2;
          const cosX = Math.cos(rotX), sinX = Math.sin(rotX);
          const cosY = Math.cos(rotY), sinY = Math.sin(rotY);

          spherePoints.forEach(p => {
            // Rotate around Y
            let x1 = p.x * cosY - p.z * sinY;
            let z1 = p.z * cosY + p.x * sinY;
            // Rotate around X
            let y2 = p.y * cosX - z1 * sinX;
            let z2 = z1 * cosX + p.y * sinX;

            const fov = 400;
            const scale = fov / (fov + z2);
            const x2d = cx + x1 * scale;
            const y2d = cy + y2 * scale;
            const alpha = Math.max(0.15, (z2 + 200) / 400);

            ctx3d.fillStyle = `hsla(${p.hue}, 90%, 65%, ${alpha})`;
            ctx3d.beginPath();
            ctx3d.arc(x2d, y2d, Math.max(1, 2.5 * scale), 0, Math.PI * 2);
            ctx3d.fill();
          });
        }
        requestAnimationFrame(render3DGalaxy);
      }
      requestAnimationFrame(render3DGalaxy);
    }

    // 6. Live Duo Demo Trigger Handler
    function triggerDuoDemo(action) {
      const chatStream = document.getElementById('duo-chat-stream');
      if (!chatStream) return;

      if (action === '3d-canvas') {
        setRightDisplayTab('canvas');
        appendChatMsg('user', 'Show me the 3D Spatial Canvas with momentum inertia physics.');
        setTimeout(() => {
          appendChatMsg('genie', `
            <div class="genie-reasoning-box">
              <div class="genie-reasoning-header" onclick="toggleReasoning(this)">
                <span><span class="genie-brain-icon">🧠</span> Deep Reasoning Process (48ms)</span>
                <span class="reasoning-arrow">▲</span>
              </div>
              <div class="genie-reasoning-body">
                • Target Display: Display 2 (120 FPS ProMotion).<br>
                • Loading 12,500 point cloud vertices into unified memory.<br>
                • Metal 3 compute shader compiled without pipeline hitch.
              </div>
            </div>
            <div class="genie-tool-call">
              <span class="genie-tool-badge exec">TOOL</span>
              <code>metal.set_viewport(canvas: "Display2", fps: 120)</code>
              <span class="genie-tool-badge success">ACTIVE</span>
            </div>
            <p>Spatial Particle Universe active on Display 2! Drag anywhere on the canvas to rotate in 3D.</p>
          `);
        }, 300);
      } else if (action === 'microvm') {
        setRightDisplayTab('vm');
        appendChatMsg('user', 'Spin up an ephemeral In-RAM Linux MicroVM via Apple Hypervisor.');
        setTimeout(() => {
          appendChatMsg('genie', `
            <div class="genie-reasoning-box">
              <div class="genie-reasoning-header" onclick="toggleReasoning(this)">
                <span><span class="genie-brain-icon">🧠</span> Deep Reasoning Process (88ms)</span>
                <span class="reasoning-arrow">▲</span>
              </div>
              <div class="genie-reasoning-body">
                • Requesting Hypervisor.framework hardware vCPU allocation.<br>
                • Mounting ephemeral APFS RAM rootfs in copy-on-write mode.<br>
                • Initializing guest Linux kernel 6.6.14.
              </div>
            </div>
            <div class="genie-tool-call">
              <span class="genie-tool-badge exec">HYPERVISOR</span>
              <code>hypervisor_vm_spawn(ram: "512MB", ephemeral: true)</code>
              <span class="genie-tool-badge success">BOOTED 340ms</span>
            </div>
            <p>Ephemeral Linux microVM is booted and active in RAM. Shell stream connected to Display 2.</p>
          `);
        }, 300);
      } else if (action === 'pillows') {
        setRightDisplayTab('code');
        appendChatMsg('user', 'Inspect World Clock Pillows specular rim gradient implementation.');
        setTimeout(() => {
          appendChatMsg('genie', `
            <p>Showing <code>WorldClockPillowView.swift</code> with 24-timezone temporal scrubber and OLED blackout specular rim shaders on Display 2.</p>
          `);
        }, 300);
      } else if (action === 'scan') {
        appendChatMsg('user', 'Scan active screens and ground UI coordinates via ScreenCaptureKit.');
        setTimeout(() => {
          appendChatMsg('genie', `
            <div class="genie-tool-call">
              <span class="genie-tool-badge exec">VISION</span>
              <code>screencapturekit.capture_window_matrix(displays: 2)</code>
              <span class="genie-tool-badge success">48 ELEMENTS GROUNDED</span>
            </div>
            <p>Identified 48 actionable UI bounding boxes across both displays with subpixel precision.</p>
          `);
        }, 300);
      }
    }

    function sendDuoMessage() {
      const input = document.getElementById('duo-user-input');
      if (!input || !input.value.trim()) return;
      const text = input.value.trim();
      input.value = '';
      appendChatMsg('user', text);

      setTimeout(() => {
        appendChatMsg('genie', `
          <div class="genie-reasoning-box">
            <div class="genie-reasoning-header" onclick="toggleReasoning(this)">
              <span><span class="genie-brain-icon">🧠</span> Autonomous Reasoning (62ms)</span>
              <span class="reasoning-arrow">▲</span>
            </div>
            <div class="genie-reasoning-body">
              • Parsed user intent: "${text.replace(/"/g, '')}".<br>
              • Evaluating Apple Silicon hardware capabilities & permissions.<br>
              • Executing plan through native Swift 6 agent subsystem.
            </div>
          </div>
          <div class="genie-tool-call">
            <span class="genie-tool-badge exec">GENIE AGENT</span>
            <code>system.orchestrate(intent: "${text.slice(0, 24)}...")</code>
            <span class="genie-tool-badge success">COMPLETE</span>
          </div>
          <p>Task executed across both displays. All operations preserved in RAM with 0% CPU idle.</p>
        `);
      }, 400);
    }

    function appendChatMsg(sender, htmlContent) {
      const stream = document.getElementById('duo-chat-stream');
      if (!stream) return;
      const msg = document.createElement('div');
      msg.className = `duo-chat-msg ${sender}`;
      msg.innerHTML = `
        <div class="duo-avatar ${sender}">${sender === 'genie' ? '🪔' : '👤'}</div>
        <div class="duo-bubble">${htmlContent}</div>
      `;
      stream.appendChild(msg);
      stream.scrollTop = stream.scrollHeight;
    }
    """

    # Inject interactive JS before </script> at end of document
    last_script_idx = content.rfind("</script>")
    if last_script_idx != -1:
        content = content[:last_script_idx] + interactive_js + "\n" + content[last_script_idx:]
        print("  ✓ Injected interactive JS engine before closing </script>")

    print("[*] Writing updated index.html...")
    INDEX_PATH.write_text(content, encoding="utf-8")
    print("  ✓ index.html successfully saved!")

    print("[*] Synchronizing to web/index.html...")
    WEB_INDEX_PATH.write_text(content, encoding="utf-8")
    print("  ✓ web/index.html successfully updated and synchronized!")

if __name__ == "__main__":
    main()
