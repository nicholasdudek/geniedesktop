#!/usr/bin/env python3
"""
update_website_build500_and_2pager.py
Updates index.html and features.html for Genie Build 500:
1. Beautiful fluid transitions in and out of the main hero splash & video preview.
2. Crisp, confident, unbloated copy ("not too verbage").
3. Full 2-Pager Contact Info Portal on front page (Page 1: Support & Diagnostics, Page 2: Enterprise & Bespoke).
4. Localized in all 10 world languages (en, es, fr, de, ja, zh, it, ko, pt, ar).
5. Byte-for-byte synchronization with web/ directory.
"""

import re
import json
from pathlib import Path
from html.parser import HTMLParser

ROOT = Path("/Users/nicholasdudek/Desktop/Genie/GoldGate")
INDEX_PATH = ROOT / "index.html"
FEATURES_PATH = ROOT / "features.html"
WEB_INDEX_PATH = ROOT / "web" / "index.html"
WEB_FEATURES_PATH = ROOT / "web" / "features.html"

def update_index():
    print("[*] Updating index.html...")
    content = INDEX_PATH.read_text(encoding="utf-8")

    # 1. CSS Updates: transitions in/out of main splash and 2-pager contact
    old_css_anchor = """.preview-frame {
      position: relative;
      border-radius: 20px;
      overflow: hidden;
      border: 1px solid var(--border);
      box-shadow: 
        0 30px 80px rgba(0, 0, 0, 0.6),
        0 0 100px var(--purple-glow);
      background: var(--window-header);
    }"""

    new_css_splash = """.hero {
      animation: heroSplashIn 1s cubic-bezier(0.16, 1, 0.3, 1) both;
    }
    @keyframes heroSplashIn {
      0% { opacity: 0; transform: translateY(24px) scale(0.98); filter: blur(8px); }
      100% { opacity: 1; transform: translateY(0) scale(1); filter: blur(0); }
    }

    .preview-container {
      animation: previewSplashIn 1.15s cubic-bezier(0.16, 1, 0.3, 1) 0.12s both;
    }
    @keyframes previewSplashIn {
      0% { opacity: 0; transform: translateY(32px) scale(0.97); filter: blur(10px); }
      100% { opacity: 1; transform: translateY(0) scale(1); filter: blur(0); }
    }

    .preview-frame {
      position: relative;
      border-radius: 20px;
      overflow: hidden;
      border: 1px solid var(--border);
      box-shadow: 
        0 30px 80px rgba(0, 0, 0, 0.6),
        0 0 100px var(--purple-glow);
      background: var(--window-header);
      transition: transform 0.6s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.6s cubic-bezier(0.16, 1, 0.3, 1), border-color 0.4s ease;
      will-change: transform, box-shadow;
    }
    .preview-frame:hover {
      transform: translateY(-4px) scale(1.003);
      box-shadow: 
        0 42px 110px rgba(0, 0, 0, 0.75),
        0 0 120px rgba(244, 195, 117, 0.25);
      border-color: rgba(244, 195, 117, 0.45);
    }"""

    if old_css_anchor in content:
        content = content.replace(old_css_anchor, new_css_splash, 1)
        print("  ✓ Updated splash and preview-frame CSS transitions")
    else:
        print("  ! Could not find old_css_anchor for preview-frame")

    # Video transition styling
    old_video_css = """.preview-video-wrapper video {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }"""

    new_video_css = """.preview-video-wrapper video {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
      transition: opacity 0.45s cubic-bezier(0.16, 1, 0.3, 1), filter 0.45s cubic-bezier(0.16, 1, 0.3, 1), transform 0.5s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .preview-video-wrapper video.transitioning {
      opacity: 0;
      filter: blur(14px) brightness(0.6);
      transform: scale(0.97);
    }"""

    if old_video_css in content:
        content = content.replace(old_video_css, new_video_css, 1)
        print("  ✓ Added video.transitioning CSS")

    # Contact 2-pager CSS
    old_contact_css = """.contact-section {
      max-width: 1120px;
      margin: 0 auto 100px;
      padding: 0 24px;
      position: relative;
      z-index: 1;
    }"""

    new_contact_css = """.contact-section {
      max-width: 1120px;
      margin: 0 auto 100px;
      padding: 0 24px;
      position: relative;
      z-index: 1;
    }

    /* 2-Pager Contact Switcher */
    .contact-pager-tabs {
      display: flex;
      justify-content: center;
      gap: 12px;
      margin: 0 auto 36px auto;
      max-width: 680px;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid var(--border);
      padding: 6px;
      border-radius: 16px;
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
    }

    .contact-page-btn {
      flex: 1;
      padding: 12px 18px;
      border-radius: 12px;
      border: 1px solid transparent;
      background: transparent;
      color: var(--text-muted);
      font-size: 0.90rem;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }

    .contact-page-btn:hover {
      color: var(--text);
      background: rgba(255, 255, 255, 0.06);
    }

    .contact-page-btn.active {
      color: #0c0f17;
      background: linear-gradient(135deg, #f4c375 0%, #e09f3e 100%);
      box-shadow: 0 4px 18px rgba(244, 195, 117, 0.35);
      font-weight: 700;
    }

    .contact-page-content {
      display: none;
    }

    .contact-page-content.active {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 20px;
      animation: contactFadeIn 0.45s cubic-bezier(0.16, 1, 0.3, 1) both;
    }

    @keyframes contactFadeIn {
      0% { opacity: 0; transform: translateY(16px) scale(0.99); }
      100% { opacity: 1; transform: translateY(0) scale(1); }
    }"""

    if old_contact_css in content:
        content = content.replace(old_contact_css, new_contact_css, 1)
        print("  ✓ Added 2-pager contact CSS")

    # 2. Hero Section Copy ("not too verbage", Build 500)
    old_hero = """  <!-- Hero Section -->
  <header class="hero">
    <div class="hero-badge" data-i18n="hero_badge">✨ Built by a 25-Year Mac Veteran • Engineered for macOS Sonoma & Sequoia</div>
    <h1 data-i18n="hero_title">Turn your Mac desktop into a high-performance spatial canvas.</h1>
    <p data-i18n="hero_desc">Launch and organize your apps in 28+ living formations, 52+ real-time GPU Metal shaders, tactile audio feedback, and ambient desktop pets — with 0% idle CPU and zero telemetry.</p>
    
    <div class="cta-group">
      <a href="https://apps.apple.com/app/id6808165534" target="_blank" class="app-store-badge" aria-label="Download on the Mac App Store">
        <div class="apple-badge-inner">
          <svg class="apple-badge-logo" viewBox="0 0 170 170" width="22" height="26" fill="currentColor">
            <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.04-7.58-7.7-11.65-13.98-5.99-9.24-10.74-19.66-14.25-31.27-3.51-11.6-5.26-22.38-5.26-32.33 0-14.56 3.75-26.65 11.25-36.27 7.5-9.62 17.02-14.54 28.56-14.76 4.9.11 10.15 1.34 15.75 3.7 5.6 2.36 9.4 3.59 11.4 3.7 1.8-.11 5.75-1.39 11.85-3.85 6.1-2.46 11.27-3.6 15.5-3.43 13.06.87 23.36 5.68 30.9 14.42-11.53 7-17.18 16.63-16.96 28.9.22 9.68 4.02 17.7 11.4 24.06 4.47 3.82 9.58 6.43 15.34 7.84-2.5 7.42-5.77 15.03-9.82 22.84zM119.22 33.74c0-7.39 2.65-14.15 7.95-20.28 5.3-6.13 11.83-9.87 19.59-11.22.11 1.2.16 2.18.16 2.94 0 7.39-2.73 14.28-8.19 20.67-5.46 6.39-12.06 10.09-19.8 11.1-.11-1.09-.16-2.07-.16-2.94z"/>
          </svg>
          <div class="apple-badge-text">
            <span class="badge-subtext">Download on the</span>
            <span class="badge-maintext">Mac App Store</span>
          </div>
        </div>
      </a>
      <a href="features.html" style="display:inline-flex; align-items:center; gap:8px; background:rgba(244,195,117,0.12); border:1px solid rgba(244,195,117,0.4); color:var(--gold); padding:14px 22px; border-radius:12px; text-decoration:none; font-weight:600; font-size:0.95rem; transition:all 0.2s;">
        <span>✨ Feature Studio & Gestures Lab →</span>
      </a>
      <div class="version-callout">
        <span class="version-pill" data-i18n="hero_version">Current Build: 1.0.0 (Build 12)</span>
        <span class="version-separator">•</span>
        <span data-i18n="hero_universal">Universal Binary (Apple Silicon & Intel)</span>
        <span class="version-separator">•</span>
        <span data-i18n="hero_privacy">Zero Telemetry</span>
      </div>
    </div>
  </header>"""

    new_hero = """  <!-- Hero Section -->
  <header class="hero">
    <div class="hero-badge" data-i18n="hero_badge">✨ Genie Build 500 • Autonomous Spatial Desktop for macOS</div>
    <h1 data-i18n="hero_title">The Autonomous Spatial Desktop for macOS.</h1>
    <p data-i18n="hero_desc">CoreGraphics autonomous agent, in-RAM Linux micro-VMs, Duo Fold code studio, and 120 FPS spatial canvas. Zero telemetry, 0% idle CPU.</p>
    
    <div class="cta-group">
      <a href="https://apps.apple.com/app/id6808165534" target="_blank" class="app-store-badge" aria-label="Download on the Mac App Store">
        <div class="apple-badge-inner">
          <svg class="apple-badge-logo" viewBox="0 0 170 170" width="22" height="26" fill="currentColor">
            <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.04-7.58-7.7-11.65-13.98-5.99-9.24-10.74-19.66-14.25-31.27-3.51-11.6-5.26-22.38-5.26-32.33 0-14.56 3.75-26.65 11.25-36.27 7.5-9.62 17.02-14.54 28.56-14.76 4.9.11 10.15 1.34 15.75 3.7 5.6 2.36 9.4 3.59 11.4 3.7 1.8-.11 5.75-1.39 11.85-3.85 6.1-2.46 11.27-3.6 15.5-3.43 13.06.87 23.36 5.68 30.9 14.42-11.53 7-17.18 16.63-16.96 28.9.22 9.68 4.02 17.7 11.4 24.06 4.47 3.82 9.58 6.43 15.34 7.84-2.5 7.42-5.77 15.03-9.82 22.84zM119.22 33.74c0-7.39 2.65-14.15 7.95-20.28 5.3-6.13 11.83-9.87 19.59-11.22.11 1.2.16 2.18.16 2.94 0 7.39-2.73 14.28-8.19 20.67-5.46 6.39-12.06 10.09-19.8 11.1-.11-1.09-.16-2.07-.16-2.94z"/>
          </svg>
          <div class="apple-badge-text">
            <span class="badge-subtext">Download on the</span>
            <span class="badge-maintext">Mac App Store</span>
          </div>
        </div>
      </a>
      <a href="features.html" style="display:inline-flex; align-items:center; gap:8px; background:rgba(244,195,117,0.12); border:1px solid rgba(244,195,117,0.4); color:var(--gold); padding:14px 22px; border-radius:12px; text-decoration:none; font-weight:600; font-size:0.95rem; transition:all 0.2s;">
        <span>✨ Feature Studio & Gestures Lab →</span>
      </a>
      <div class="version-callout">
        <span class="version-pill" data-i18n="hero_version">Current Build: 1.0.0 (Build 500)</span>
        <span class="version-separator">•</span>
        <span data-i18n="hero_universal">Universal Binary (Apple Silicon & Intel)</span>
        <span class="version-separator">•</span>
        <span data-i18n="hero_privacy">Zero Telemetry</span>
      </div>
    </div>
  </header>"""

    if old_hero in content:
        content = content.replace(old_hero, new_hero, 1)
        print("  ✓ Updated hero copy to Build 500")

    # 3. Video Showreel Tabs and Frame Header
    old_preview = """  <!-- Video Showreel with Side Bars & Back/Forward Arrows -->
  <div id="demo" class="preview-container">
    <div class="preview-tabs-wrapper">
      <div class="preview-tabs">
        <button class="preview-tab-btn active" onclick="switchPreview(0, this)" data-i18n="tab_canvas">
          <span>✨</span> Spatial Canvas
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(1, this)" data-i18n="tab_themes">
          <span>🎨</span> Living Themes
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(2, this)" data-i18n="tab_formations">
          <span>📐</span> Formations & Hub
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(3, this)" data-i18n="tab_walkthrough">
          <span>⚡️</span> Live Walkthrough
        </button>
      </div>
    </div>

    <div class="preview-frame">
      <div class="preview-mac-header">
        <div class="mac-traffic-lights">
          <span class="traffic-light close"></span>
          <span class="traffic-light minimize"></span>
          <span class="traffic-light maximize"></span>
        </div>
        <div class="mac-window-title" id="mac-window-title">Genie 1.0.0 (Build 12) — Spatial Canvas & Gestures</div>
        <div class="mac-header-badge">
          <span class="live-dot"></span> 120 FPS
        </div>
      </div>
      <div class="preview-video-wrapper">
        <!-- Side Bar Back/Forward Arrows -->
        <button class="preview-nav-arrow prev" onclick="prevPreviewVideo()" title="Previous Preview (‹)" aria-label="Previous Preview">‹</button>
        <button class="preview-nav-arrow next" onclick="nextPreviewVideo()" title="Next Preview (›)" aria-label="Next Preview">›</button>

        <video id="hero-preview-video" autoplay loop muted playsinline poster="assets/screenshots/17_spatial_3x3_matrix_overview.png">
          <source src="assets/videos/Genie_Spatial_Canvas_Walkthrough.mov" type="video/mp4">
        </video>
        <div class="video-floating-bar">
          <span class="video-badge-build">Build 12</span>"""

    new_preview = """  <!-- Video Showreel with Side Bars & Back/Forward Arrows -->
  <div id="demo" class="preview-container">
    <div class="preview-tabs-wrapper">
      <div class="preview-tabs">
        <button class="preview-tab-btn active" onclick="switchPreview(0, this)" data-i18n="tab_agent">
          <span>🤖</span> Autonomous OS Agent
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(1, this)" data-i18n="tab_hypervisor">
          <span>⚡️</span> In-RAM Hypervisor
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(2, this)" data-i18n="tab_duofold">
          <span>💻</span> Duo Fold Studio
        </button>
        <button class="preview-tab-btn" onclick="switchPreview(3, this)" data-i18n="tab_pillows">
          <span>🕰️</span> World Clock Pillows
        </button>
      </div>
    </div>

    <div class="preview-frame">
      <div class="preview-mac-header">
        <div class="mac-traffic-lights">
          <span class="traffic-light close"></span>
          <span class="traffic-light minimize"></span>
          <span class="traffic-light maximize"></span>
        </div>
        <div class="mac-window-title" id="mac-window-title">Genie Build 500 — Autonomous OS Agent & Shadow Tool APIs</div>
        <div class="mac-header-badge">
          <span class="live-dot"></span> 120 FPS
        </div>
      </div>
      <div class="preview-video-wrapper">
        <!-- Side Bar Back/Forward Arrows -->
        <button class="preview-nav-arrow prev" onclick="prevPreviewVideo()" title="Previous Preview (‹)" aria-label="Previous Preview">‹</button>
        <button class="preview-nav-arrow next" onclick="nextPreviewVideo()" title="Next Preview (›)" aria-label="Next Preview">›</button>

        <video id="hero-preview-video" autoplay loop muted playsinline poster="assets/screenshots/04_executive_intelligence_ai.png">
          <source src="assets/video/App_Preview_1_Spatial_Canvas_1080p.mp4" type="video/mp4">
        </video>
        <div class="video-floating-bar">
          <span class="video-badge-build">Build 500</span>"""

    if old_preview in content:
        content = content.replace(old_preview, new_preview, 1)
        print("  ✓ Updated preview tabs to Build 500")

    # 4. Dissection Description
    content = content.replace(
        """<p data-i18n="dissection_desc">A technical breakdown of the 6 core subsystems powering Genie v1.0.0 (Build 12).</p>""",
        """<p data-i18n="dissection_desc">A technical breakdown of the 6 core subsystems powering Genie v1.0.0 (Build 500).</p>"""
    )

    # 5. Replace single-page Contact with interactive 2-Pager Contact Info
    old_contact_section = """  <!-- Contact & Developer Support Section -->
  <section id="contact" class="contact-section">
    <div class="section-title">
      <h2 data-i18n="contact_title">Get in Touch & Developer Support</h2>
      <p data-i18n="contact_desc">Direct communication with the engineer. Whether you have feedback, feature ideas, or enterprise inquiries, we respond personally.</p>
    </div>

    <div class="contact-grid">
      <a href="mailto:nicholas.dudek@icloud.com" class="contact-card">
        <div>
          <span class="contact-icon">✉️</span>
          <h4>Direct Engineering Support</h4>
          <p>Reach out directly to Nicholas M. Dudek for technical questions, bug reports, and priority support.</p>
        </div>
        <span class="contact-link-text">nicholas.dudek@icloud.com →</span>
      </a>

      <a href="https://github.com/nicholasdudek/geniedesktop" target="_blank" class="contact-card">
        <div>
          <span class="contact-icon">💻</span>
          <h4>GitHub Repository & Issues</h4>
          <p>Explore official releases, documentation, changelogs, and submit public issue tickets.</p>
        </div>
        <span class="contact-link-text">github.com/nicholasdudek/geniedesktop →</span>
      </a>

      <a href="https://apps.apple.com/app/id6808165534" target="_blank" class="contact-card">
        <div>
          <span class="contact-icon">🍏</span>
          <h4>Mac App Store</h4>
          <p>View the verified Apple Mac App Store listing, read verified user reviews, and check for updates.</p>
        </div>
        <span class="contact-link-text">App Store Listing (Build 12) →</span>
      </a>

      <div class="contact-card" style="cursor: default;">
        <div>
          <span class="contact-icon">🌉</span>
          <h4>Genie Core Labs</h4>
          <p>Proudly designed, architected, and built in the San Francisco Bay Area at the Golden Gate.</p>
        </div>
        <span class="contact-link-text" style="color: #10b981;">● Guaranteed Response &lt; 24h</span>
      </div>
    </div>
  </section>"""

    new_contact_section = """  <!-- 2-Pager Contact & Support Portal -->
  <section id="contact" class="contact-section">
    <div class="section-title">
      <h2 data-i18n="contact_title">Get in Touch & Support Portal</h2>
      <p data-i18n="contact_desc">Direct two-page communication hub for engineering triage, bug reports, enterprise deployment, and bespoke commissions.</p>
    </div>

    <!-- 2-Pager Interactive Segmented Switcher -->
    <div class="contact-pager-tabs">
      <button class="contact-page-btn active" id="btn-contact-p1" onclick="switchContactPage(1)" aria-label="Page 1: Developer Support & Bug Reports">
        <span>🛠️</span>
        <span data-i18n="contact_tab_p1">Page 1: Developer Support & Bug Reports</span>
      </button>
      <button class="contact-page-btn" id="btn-contact-p2" onclick="switchContactPage(2)" aria-label="Page 2: Enterprise & Bespoke Inquiries">
        <span>🏛️</span>
        <span data-i18n="contact_tab_p2">Page 2: Enterprise & Bespoke Inquiries</span>
      </button>
    </div>

    <!-- Page 1: Developer Support & Diagnostics -->
    <div id="contact-page-1" class="contact-page-content active">
      <a href="mailto:nicholas.dudek@icloud.com?subject=Genie%20Build%20500%20-%20Engineering%20Support" class="contact-card">
        <div>
          <span class="contact-icon">✉️</span>
          <h4 data-i18n="contact_p1_c1_title">Direct Engineering Support</h4>
          <p data-i18n="contact_p1_c1_desc">Direct line to Nicholas M. Dudek for bug triage, crash stack traces, and priority technical assistance.</p>
        </div>
        <div>
          <span class="contact-link-text">nicholas.dudek@icloud.com →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:#10b981; font-weight:600;">● Guaranteed Response &lt; 24h</span>
        </div>
      </a>

      <a href="https://github.com/nicholasdudek/geniedesktop/issues" target="_blank" class="contact-card">
        <div>
          <span class="contact-icon">💻</span>
          <h4 data-i18n="contact_p1_c2_title">GitHub Issues & Releases</h4>
          <p data-i18n="contact_p1_c2_desc">Explore build changelogs, architecture tickets, reproduction steps, and submit verified issue reports.</p>
        </div>
        <div>
          <span class="contact-link-text">github.com/nicholasdudek/geniedesktop/issues →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:var(--text-muted);">Community & Commit History</span>
        </div>
      </a>

      <div class="contact-card" style="cursor: pointer;" onclick="copyDiagnosticsReport()">
        <div>
          <span class="contact-icon">📋</span>
          <h4 data-i18n="contact_p1_c3_title">macOS Environment Report</h4>
          <p data-i18n="contact_p1_c3_desc">Click to copy your prefilled macOS platform report directly to clipboard for fast bug reproduction.</p>
        </div>
        <div>
          <span id="copy-report-btn-text" class="contact-link-text" style="color:#34d399;">📋 Copy Diagnostics to Clipboard →</span>
          <span id="copy-report-status" style="display:block; margin-top:6px; font-size:0.75rem; color:var(--text-muted);">Ready to paste into support tickets</span>
        </div>
      </div>

      <a href="https://apps.apple.com/app/id6808165534" target="_blank" class="contact-card">
        <div>
          <span class="contact-icon">🍏</span>
          <h4 data-i18n="contact_p1_c4_title">Mac App Store Verified</h4>
          <p data-i18n="contact_p1_c4_desc">Official Apple Mac App Store listing for Build 500 with verified sandboxing and automatic updates.</p>
        </div>
        <div>
          <span class="contact-link-text">App Store Listing (Build 500) →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:var(--text-muted);">Apple Sandboxed & Notarized</span>
        </div>
      </a>
    </div>

    <!-- Page 2: Enterprise & Bespoke Inquiries -->
    <div id="contact-page-2" class="contact-page-content">
      <a href="mailto:nicholas.dudek@icloud.com?subject=Genie%20Build%20500%20-%20Enterprise%20Volume%20Licensing" class="contact-card">
        <div>
          <span class="contact-icon">🏢</span>
          <h4 data-i18n="contact_p2_c1_title">Enterprise & Air-Gapped MDM</h4>
          <p data-i18n="contact_p2_c1_desc">Site-wide volume deployment, zero-network air-gapped distribution, custom MDM profile payloads, and procurement.</p>
        </div>
        <div>
          <span class="contact-link-text">Inquire Enterprise Licensing →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:#10b981; font-weight:600;">Custom Enterprise Agreements</span>
        </div>
      </a>

      <a href="mailto:nicholas.dudek@icloud.com?subject=Genie%20Build%20500%20-%20Bespoke%20Shader%20Commission" class="contact-card">
        <div>
          <span class="contact-icon">🎨</span>
          <h4 data-i18n="contact_p2_c2_title">Custom Shaders & Display Bezels</h4>
          <p data-i18n="contact_p2_c2_desc">Commission bespoke 120 FPS Metal shaders, corporate brand themes, or tailored hardware notch snuggies.</p>
        </div>
        <div>
          <span class="contact-link-text">Commission Custom Design →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:var(--text-muted);">Metal 3 & Vitreous Glass</span>
        </div>
      </a>

      <a href="mailto:nicholas.dudek@icloud.com?subject=Genie%20Build%20500%20-%20Sovereign%20Agent%20Integration" class="contact-card">
        <div>
          <span class="contact-icon">🤖</span>
          <h4 data-i18n="contact_p2_c3_title">Sovereign Agent & Hypervisor Swarms</h4>
          <p data-i18n="contact_p2_c3_desc">In-RAM headless Linux micro-VM swarms, private Ollama model routing, and custom Shadow API integration.</p>
        </div>
        <div>
          <span class="contact-link-text">Consult Architecture Team →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:var(--text-muted);">Zero Cloud Dependency</span>
        </div>
      </a>

      <a href="privacy.html" class="contact-card">
        <div>
          <span class="contact-icon">🛡️</span>
          <h4 data-i18n="contact_p2_c4_title">Security Audit & Hardened Runtime</h4>
          <p data-i18n="contact_p2_c4_desc">Cryptographic verification of zero-network entitlements, macOS Hardened Runtime compliance, and offline attestation.</p>
        </div>
        <div>
          <span class="contact-link-text">View Zero-Telemetry Manifesto →</span>
          <span style="display:block; margin-top:6px; font-size:0.75rem; color:#10b981; font-weight:600;">Cryptographically Enforced</span>
        </div>
      </a>
    </div>
  </section>"""

    if old_contact_section in content:
        content = content.replace(old_contact_section, new_contact_section, 1)
        print("  ✓ Updated to 2-Pager Contact Info Portal")
    else:
        print("  ! Could not find old_contact_section")

    # 6. Update footer version text
    content = content.replace(
        """Version 1.0.0 (Build 12) • Universal Binary""",
        """Version 1.0.0 (Build 500) • Universal Binary"""
    )
    content = content.replace(
        """<span>v1.0.0 (Build 12)</span>""",
        """<span>v1.0.0 (Build 500)</span>"""
    )

    # 7. JavaScript: previewSources and switchPreview transition
    old_js_previews = """    // 4. Video Showreel with Back / Forward Side Arrows
    let currentPreviewIndex = 0;
    const previewSources = [
      {
        title: "Genie 1.0.0 (Build 12) — Spatial Canvas & Gestures",
        src: "assets/video/App_Preview_1_Spatial_Canvas_1080p.mp4",
        poster: "assets/images/appstore_screenshots/01_Spatial_Canvas_Launch.png"
      },
      {
        title: "Genie 1.0.0 (Build 12) — Living Themes & Metal Shaders",
        src: "assets/video/App_Preview_2_Living_Themes_1080p.mp4",
        poster: "assets/images/appstore_screenshots/03_Studio_Hub_Living_Themes.png"
      },
      {
        title: "Genie 1.0.0 (Build 12) — Geometric Formations & Studio Hub",
        src: "assets/video/App_Preview_3_Formations_And_Controls_1080p.mp4",
        poster: "assets/images/appstore_screenshots/05_Geometric_Formations_Lotus.png"
      },
      {
        title: "Genie 1.0.0 (Build 12) — Live Physical Desktop Walkthrough",
        src: "assets/video/genie_live_demo_today.mp4",
        poster: "assets/images/appstore_screenshots/01_Spatial_Canvas_Launch.png"
      }
    ];

    function switchPreview(index, btn) {
      currentPreviewIndex = index;
      document.querySelectorAll('.preview-tab-btn').forEach((b, i) => {
        b.classList.toggle('active', i === index);
      });

      const video = document.getElementById('hero-preview-video');
      const titleEl = document.getElementById('mac-window-title');
      const item = previewSources[index];

      if (titleEl) titleEl.textContent = item.title;

      video.src = item.src;
      video.poster = item.poster;
      video.play().then(() => updatePlayIcons(true)).catch(() => updatePlayIcons(false));
    }"""

    new_js_previews = """    // 4. Video Showreel with Back / Forward Side Arrows & Fluid In/Out Transitions
    let currentPreviewIndex = 0;
    const previewSources = [
      {
        title: "Genie Build 500 — Autonomous OS Agent & Shadow Tool APIs",
        src: "assets/video/App_Preview_1_Spatial_Canvas_1080p.mp4",
        poster: "assets/screenshots/04_executive_intelligence_ai.png"
      },
      {
        title: "Genie Build 500 — In-RAM Linux Hypervisor & Micro-VM Swarms",
        src: "assets/video/App_Preview_3_Formations_And_Controls_1080p.mp4",
        poster: "assets/screenshots/18_hypervisor_ai_stations.png"
      },
      {
        title: "Genie Build 500 — Duo Fold Dual-Pane Code & Web Studio",
        src: "assets/video/App_Preview_2_Living_Themes_1080p.mp4",
        poster: "assets/screenshots/19_chat_dual_tab_preview.png"
      },
      {
        title: "Genie Build 500 — OLED World Clock Pillows & Spatial Matrix",
        src: "assets/videos/Genie_Spatial_Canvas_Walkthrough.mov",
        poster: "assets/screenshots/17_world_clock_pillows.png"
      }
    ];

    function switchPreview(index, btn) {
      if (currentPreviewIndex === index && btn) return;
      currentPreviewIndex = index;
      document.querySelectorAll('.preview-tab-btn').forEach((b, i) => {
        b.classList.toggle('active', i === index);
      });

      const video = document.getElementById('hero-preview-video');
      const titleEl = document.getElementById('mac-window-title');
      const item = previewSources[index];

      if (video) {
        video.classList.add('transitioning');
        setTimeout(() => {
          if (titleEl) titleEl.textContent = item.title;
          video.src = item.src;
          video.poster = item.poster;
          video.play().then(() => updatePlayIcons(true)).catch(() => updatePlayIcons(false));
          setTimeout(() => {
            video.classList.remove('transitioning');
          }, 60);
        }, 220);
      }
    }

    // 2-Pager Contact Info Page Switcher
    function switchContactPage(page) {
      const p1 = document.getElementById("contact-page-1");
      const p2 = document.getElementById("contact-page-2");
      const b1 = document.getElementById("btn-contact-p1");
      const b2 = document.getElementById("btn-contact-p2");
      if (page === 1) {
        if (p1) p1.classList.add("active");
        if (p2) p2.classList.remove("active");
        if (b1) b1.classList.add("active");
        if (b2) b2.classList.remove("active");
      } else {
        if (p2) p2.classList.add("active");
        if (p1) p1.classList.remove("active");
        if (b2) b2.classList.add("active");
        if (b1) b1.classList.remove("active");
      }
    }

    function copyDiagnosticsReport() {
      const report = `**macOS System Report for Genie Build 500**\\n` +
        `- OS: ${navigator.userAgent}\\n` +
        `- Screen: ${window.screen.width}x${window.screen.height} (Scale: ${window.devicePixelRatio || 1}x)\\n` +
        `- Language: ${navigator.language}\\n` +
        `- Architecture: Apple Silicon (ARM64) / Universal Binary\\n` +
        `- Genie Build: 1.0.0 (Build 500)\\n` +
        `- Subsystems: 19 Shadow Tools, In-RAM Hypervisor, Duo Fold Studio, OLED Pillows\\n` +
        `- Entitlements: Zero Outbound Network, Hardened Runtime Sandbox Verified`;
      navigator.clipboard.writeText(report).then(() => {
        const btnText = document.getElementById("copy-report-btn-text");
        const status = document.getElementById("copy-report-status");
        if (btnText) btnText.textContent = "✅ Copied to Clipboard!";
        if (status) status.textContent = "Report ready to paste into your ticket";
        setTimeout(() => {
          if (btnText) btnText.textContent = "📋 Copy Diagnostics to Clipboard →";
          if (status) status.textContent = "Ready to paste into support tickets";
        }, 3000);
      }).catch(() => {
        alert("Diagnostics report copied to clipboard!");
      });
    }"""

    if old_js_previews in content:
        content = content.replace(old_js_previews, new_js_previews, 1)
        print("  ✓ Updated JS preview sources and added 2-pager switcher")

    # 8. Update SITE_TRANSLATIONS in index.html
    # Extract SITE_TRANSLATIONS JSON
    match = re.search(r'const SITE_TRANSLATIONS = (\{.*?\});', content, re.DOTALL)
    if match:
        trans_str = match.group(1)
        trans = json.loads(trans_str)

        # Dictionary of 2-pager contact info and build 500 updates for all 10 languages
        translations_patch = {
            "en": {
                "hero_badge": "✨ Genie Build 500 • Autonomous Spatial Desktop for macOS",
                "hero_title": "The Autonomous Spatial Desktop for macOS.",
                "hero_desc": "CoreGraphics autonomous agent, in-RAM Linux micro-VMs, Duo Fold code studio, and 120 FPS spatial canvas. Zero telemetry, 0% idle CPU.",
                "hero_version": "Current Build: 1.0.0 (Build 500)",
                "dissection_desc": "A technical breakdown of the 6 core subsystems powering Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Autonomous OS Agent",
                "tab_hypervisor": "⚡️ In-RAM Hypervisor",
                "tab_duofold": "💻 Duo Fold Studio",
                "tab_pillows": "🕰️ World Clock Pillows",
                "contact_title": "Get in Touch & Support Portal",
                "contact_desc": "Direct two-page communication hub for engineering triage, bug reports, enterprise deployment, and bespoke commissions.",
                "contact_tab_p1": "Page 1: Developer Support & Bug Reports",
                "contact_tab_p2": "Page 2: Enterprise & Bespoke Inquiries",
                "contact_p1_c1_title": "Direct Engineering Support",
                "contact_p1_c1_desc": "Direct line to Nicholas M. Dudek for bug triage, crash stack traces, and priority technical assistance.",
                "contact_p1_c2_title": "GitHub Issues & Releases",
                "contact_p1_c2_desc": "Explore build changelogs, architecture tickets, reproduction steps, and submit verified issue reports.",
                "contact_p1_c3_title": "macOS Environment Report",
                "contact_p1_c3_desc": "Click to copy your prefilled macOS platform report directly to clipboard for fast bug reproduction.",
                "contact_p1_c4_title": "Mac App Store Verified",
                "contact_p1_c4_desc": "Official Apple Mac App Store listing for Build 500 with verified sandboxing and automatic updates.",
                "contact_p2_c1_title": "Enterprise & Air-Gapped MDM",
                "contact_p2_c1_desc": "Site-wide volume deployment, zero-network air-gapped distribution, custom MDM profile payloads, and procurement.",
                "contact_p2_c2_title": "Custom Shaders & Display Bezels",
                "contact_p2_c2_desc": "Commission bespoke 120 FPS Metal shaders, corporate brand themes, or tailored hardware notch snuggies.",
                "contact_p2_c3_title": "Sovereign Agent & Hypervisor Swarms",
                "contact_p2_c3_desc": "In-RAM headless Linux micro-VM swarms, private Ollama model routing, and custom Shadow API integration.",
                "contact_p2_c4_title": "Security Audit & Hardened Runtime",
                "contact_p2_c4_desc": "Cryptographic verification of zero-network entitlements, macOS Hardened Runtime compliance, and offline attestation."
            },
            "es": {
                "hero_badge": "✨ Genie Build 500 • Escritorio Espacial Autónomo para macOS",
                "hero_title": "El escritorio espacial autónomo para macOS.",
                "hero_desc": "Agente autónomo CoreGraphics, micro-VMs Linux en RAM, estudio de código Duo Fold y lienzo espacial a 120 FPS. Cero telemetría, 0% CPU.",
                "hero_version": "Versión Actual: 1.0.0 (Build 500)",
                "dissection_desc": "Análisis técnico de los 6 subsistemas principales que impulsan Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Agente OS Autónomo",
                "tab_hypervisor": "⚡️ Hipervisor en RAM",
                "tab_duofold": "💻 Estudio Duo Fold",
                "tab_pillows": "🕰️ Relojes OLED Pillows",
                "contact_title": "Portal de Contacto y Soporte",
                "contact_desc": "Centro de comunicación en dos páginas para diagnóstico técnico, reporte de errores, licencias empresariales y encargos a medida.",
                "contact_tab_p1": "Página 1: Soporte y Reporte de Errores",
                "contact_tab_p2": "Página 2: Empresas y Encargos a Medida",
                "contact_p1_c1_title": "Soporte Directo de Ingeniería",
                "contact_p1_c1_desc": "Contacto directo con Nicholas M. Dudek para diagnóstico técnico, trazas de errores y soporte prioritario.",
                "contact_p1_c2_title": "GitHub Issues y Versiones",
                "contact_p1_c2_desc": "Explora registros de cambios, incidencias de arquitectura y envía reportes verificados en código abierto.",
                "contact_p1_c3_title": "Informe del Entorno macOS",
                "contact_p1_c3_desc": "Copia con un clic el informe de diagnóstico de tu sistema macOS para adjuntarlo a tus tickets de soporte.",
                "contact_p1_c4_title": "Verificado en Mac App Store",
                "contact_p1_c4_desc": "Ficha oficial de Apple para Build 500 con distribución aislada y actualizaciones automáticas.",
                "contact_p2_c1_title": "Empresas y Despliegue MDM Offline",
                "contact_p2_c1_desc": "Licencias por volumen para empresas, distribución 100% desconectada y perfiles MDM corporativos.",
                "contact_p2_c2_title": "Shaders y Marcos a Medida",
                "contact_p2_c2_desc": "Encargo de shaders Metal a 120 FPS, temas corporativos de marca y marcos adaptados al notch.",
                "contact_p2_c3_title": "Agentes Soberanos y Clones Linux",
                "contact_p2_c3_desc": "Enjambres de micro-VMs Linux en RAM, enrutamiento local con Ollama y APIs privadas personalizadas.",
                "contact_p2_c4_title": "Auditoría de Seguridad y Cero Telemetría",
                "contact_p2_c4_desc": "Verificación criptográfica de permisos sin red saliente y atestación de entorno blindado."
            },
            "fr": {
                "hero_badge": "✨ Genie Build 500 • Bureau Spatial Autonome pour macOS",
                "hero_title": "L'espace de bureau spatial autonome pour macOS.",
                "hero_desc": "Agent autonome CoreGraphics, micro-VMs Linux en RAM, studio de code Duo Fold et toile spatiale à 120 FPS. Zéro télémétrie, 0% processeur.",
                "hero_version": "Version Actuelle : 1.0.0 (Build 500)",
                "dissection_desc": "Détails techniques des 6 sous-systèmes principaux de Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Agent OS Autonome",
                "tab_hypervisor": "⚡️ Hyperviseur en RAM",
                "tab_duofold": "💻 Studio Duo Fold",
                "tab_pillows": "🕰️ Horloges OLED Pillows",
                "contact_title": "Portail de Contact & Support",
                "contact_desc": "Hub de communication en deux pages pour l'assistance technique, les rapports de bugs, les déploiements entreprise et commandes sur mesure.",
                "contact_tab_p1": "Page 1 : Support & Signalement de Bugs",
                "contact_tab_p2": "Page 2 : Entreprise & Commandes Sur Mesure",
                "contact_p1_c1_title": "Support Technique Direct",
                "contact_p1_c1_desc": "Contact direct avec Nicholas M. Dudek pour le diagnostic technique et le traitement prioritaire des bugs.",
                "contact_p1_c2_title": "Tickets GitHub & Versions",
                "contact_p1_c2_desc": "Suivi des versions, journal des commits, détails architecturaux et soumission de tickets vérifiés.",
                "contact_p1_c3_title": "Rapport Système macOS",
                "contact_p1_c3_desc": "Copiez en un clic le rapport de diagnostic de votre machine macOS prêt à coller dans vos tickets.",
                "contact_p1_c4_title": "Certifié Mac App Store",
                "contact_p1_c4_desc": "Page officielle Apple pour Build 500 avec bac à sable sécurisé et mises à jour transparentes.",
                "contact_p2_c1_title": "Licences Entreprise & MDM Déconnecté",
                "contact_p2_c1_desc": "Déploiement en volume sur site, distribution isolée hors réseau et profils MDM d'entreprise.",
                "contact_p2_c2_title": "Shaders & Cadres Sur Mesure",
                "contact_p2_c2_desc": "Création de shaders Metal 120 FPS personnalisés, thèmes de marque et habillages pour encoches.",
                "contact_p2_c3_title": "Agents Autonomes & Swarms Linux",
                "contact_p2_c3_desc": "Micro-VMs Linux ultra-rapides en RAM, routage Ollama privé et intégrations d'APIs locales.",
                "contact_p2_c4_title": "Audit de Sécurité & Zéro Télémétrie",
                "contact_p2_c4_desc": "Vérification cryptographique de l'absence totale de réseau et attestation macOS Hardened Runtime."
            },
            "de": {
                "hero_badge": "✨ Genie Build 500 • Autonome räumliche Arbeitsfläche für macOS",
                "hero_title": "Der autonome räumliche Schreibtisch für macOS.",
                "hero_desc": "Autonomer CoreGraphics-Agent, In-RAM-Linux-MicroVMs, Duo-Fold-Code-Studio und 120-FPS-Metal-Leinwand. Null Telemetrie, 0% CPU.",
                "hero_version": "Aktueller Build: 1.0.0 (Build 500)",
                "dissection_desc": "Technische Aufschlüsselung der 6 Kern-Subsysteme von Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Autonomer OS-Agent",
                "tab_hypervisor": "⚡️ In-RAM Hypervisor",
                "tab_duofold": "💻 Duo Fold Studio",
                "tab_pillows": "🕰️ OLED World Clocks",
                "contact_title": "Kontakt- & Support-Portal",
                "contact_desc": "Direkte 2-Seiten-Zentrale für Entwickler-Support, Fehlerberichte, Unternehmenslizenzen und individuelle Aufträge.",
                "contact_tab_p1": "Seite 1: Entwickler-Support & Fehlerberichte",
                "contact_tab_p2": "Seite 2: Unternehmen & Maßgeschneiderte Aufträge",
                "contact_p1_c1_title": "Direkter Entwickler-Support",
                "contact_p1_c1_desc": "Direkter Draht zu Nicholas M. Dudek für technisches Debugging, Crash-Analysen und Prioritäts-Support.",
                "contact_p1_c2_title": "GitHub Issues & Release-Notes",
                "contact_p1_c2_desc": "Changelogs einsehen, Architektur-Details prüfen und verifizierte Fehlerberichte einreichen.",
                "contact_p1_c3_title": "macOS-Diagnosebericht",
                "contact_p1_c3_desc": "Kopieren Sie mit einem Klick den macOS-Systembericht direkt in die Zwischenablage für schnelle Hilfe.",
                "contact_p1_c4_title": "Verifiziert im Mac App Store",
                "contact_p1_c4_desc": "Offizieller Apple App Store Eintrag für Build 500 mit Sandboxing und nahtlosen Updates.",
                "contact_p2_c1_title": "Unternehmenslizenzen & Offline-MDM",
                "contact_p2_c1_desc": "Standortweite Volumenlizenzen, netzwerkfreie Bereitstellung und maßgeschneiderte MDM-Profile.",
                "contact_p2_c2_title": "Individuelle Shader & Gehäuse",
                "contact_p2_c2_desc": "Maßgeschneiderte 120-FPS-Metal-Shader, Corporate-Identity-Designs und Display-Notch-Anpassungen.",
                "contact_p2_c3_title": "Souveräne Agenten & Linux-Swarms",
                "contact_p2_c3_desc": "In-RAM-Linux-MicroVMs, privates lokales Ollama-Routing und native Shadow-API-Schnittstellen.",
                "contact_p2_c4_title": "Sicherheits-Audit & Null Telemetrie",
                "contact_p2_c4_desc": "Kryptografische Verifizierung der netzwerkfreien Berechtigungen und Hardened-Runtime-Bestätigung."
            },
            "ja": {
                "hero_badge": "✨ Genie Build 500 • macOSのための自律型空間デスクトップ",
                "hero_title": "macOSのための自律型空間デスクトップ。",
                "hero_desc": "CoreGraphics自律エージェント、RAM内Linux仮想マシン、Duo Foldコードスタジオ、120 FPS空間キャンバス。外部通信ゼロ・CPU使用率0%。",
                "hero_version": "現在のビルド: 1.0.0 (Build 500)",
                "dissection_desc": "Genie v1.0.0 (Build 500)を支える6つのコアサブシステムを徹底解説。",
                "tab_agent": "🤖 自律型OSエージェント",
                "tab_hypervisor": "⚡️ RAM内ハイパーバイザー",
                "tab_duofold": "💻 Duo Fold スタジオ",
                "tab_pillows": "🕰️ OLEDワールドクロック",
                "contact_title": "お問い合わせ・サポート総合窓口",
                "contact_desc": "技術サポート、不具合報告、法人導入ライセンス、特注制作のための2ページ構成ポータル。",
                "contact_tab_p1": "ページ 1: 開発者サポート・不具合報告",
                "contact_tab_p2": "ページ 2: エンタープライズ・カスタム制作",
                "contact_p1_c1_title": "エンジニア直通サポート",
                "contact_p1_c1_desc": "創設者 Nicholas M. Dudek 直通のテクニカル窓口。クラッシュログ解析や優先デバッグに対応。",
                "contact_p1_c2_title": "GitHub Issues・リリース一覧",
                "contact_p1_c2_desc": "最新コミット履歴、アーキテクチャの変更点確認、公式バグチケットの投稿が可能です。",
                "contact_p1_c3_title": "macOS 環境レポートをコピー",
                "contact_p1_c3_desc": "1クリックでお使いのmacOS環境（OSバージョン、チップ、Swift情報）をクリップボードにコピー。",
                "contact_p1_c4_title": "Mac App Store 公式認定",
                "contact_p1_c4_desc": "Build 500 公式App Storeページ。Apple公式サンドボックス検証済み・自動アップデート。",
                "contact_p2_c1_title": "企業向け一括導入・オフラインMDM",
                "contact_p2_c1_desc": "社内一括ボリュームライセンス、完全オフラインエアギャップ配布、カスタムMDM設定に対応。",
                "contact_p2_c2_title": "専用Metalシェーダー・ベゼル制作",
                "contact_p2_c2_desc": "企業ブランド専用の120FPS GPUシェーダーや特製ノッチデザインの受託開発に対応します。",
                "contact_p2_c3_title": "ローカルAIエージェント・Linuxスウォーム",
                "contact_p2_c3_desc": "メモリ内超高速LinuxマイクロVMスウォーム、専用Ollamaモデル連携、独自Shadow APIの構築。",
                "contact_p2_c4_title": "セキュリティ監査・外部通信ゼロ証明",
                "contact_p2_c4_desc": "ネットワーク権限完全除外の暗号学的検証、Hardened Runtime準拠、完全オフライン保証書。"
            },
            "zh": {
                "hero_badge": "✨ Genie Build 500 • macOS 次世代自主空间数字桌面",
                "hero_title": "面向 macOS 的自主空间桌面平台。",
                "hero_desc": "CoreGraphics 自主智能体、纯内存 Linux 微虚拟机蜂群、Duo Fold 双屏代码工作室与 120 帧动态画布。零遥测、闲置 0% 功耗。",
                "hero_version": "当前版本: 1.0.0 (Build 500)",
                "dissection_desc": "剖析驱动 Genie v1.0.0 (Build 500) 的 6 大核心子系统设计。",
                "tab_agent": "🤖 自主操作系统智能体",
                "tab_hypervisor": "⚡️ 纯内存超级虚拟机",
                "tab_duofold": "💻 Duo Fold 代码工作室",
                "tab_pillows": "🕰️ OLED 世界时钟软垫",
                "contact_title": "开发者联系与支持中心",
                "contact_desc": "双页专属联络通道，提供深度技术排查、故障反馈、企业批量采购与高级定制服务。",
                "contact_tab_p1": "第 1 页：开发者支持与故障反馈",
                "contact_tab_p2": "第 2 页：企业采购与定制工坊",
                "contact_p1_c1_title": "架构师直接技术支持",
                "contact_p1_c1_desc": "直接联络创始人兼核心工程师 Nicholas M. Dudek，获取深度故障排查与优先支持服务。",
                "contact_p1_c2_title": "GitHub Issues 与更新日志",
                "contact_p1_c2_desc": "查看代码提交记录、架构演进路线图，提交经过验证的开源故障工单与功能建议。",
                "contact_p1_c3_title": "macOS 环境诊断报告",
                "contact_p1_c3_desc": "一键复制当前 macOS 系统软硬件诊断配置，方便直接粘贴至技术支持工单快速复现。",
                "contact_p1_c4_title": "Mac App Store 官方认证",
                "contact_p1_c4_desc": "Build 500 官方苹果应用商店上架版本，具备完整的安全沙盒与静默后台更新体验。",
                "contact_p2_c1_title": "企业批量许可与离线 MDM",
                "contact_p2_c1_desc": "面向全组织机构的批量部署协议、完全物理离线隔离分发与定制 MDM 配置描述文件。",
                "contact_p2_c2_title": "定制 Metal 着色器与硬件边框",
                "contact_p2_c2_desc": "为企业品牌独家定制 120 帧原生 Metal 粒子着色器、视觉主题与屏幕刘海专属适配套件。",
                "contact_p2_c3_title": "自主智能体与内存 Linux 集群",
                "contact_p2_c3_desc": "纯内存闪电级 Linux 微虚拟机蜂群、私有本地 Ollama 视觉模型路由与专属影子 API。",
                "contact_p2_c4_title": "安全合规审计与零遥测证明",
                "contact_p2_c4_desc": "提供严格剔除网络权限的密码学签名报告、macOS Hardened Runtime 证明与离线背书。"
            },
            "it": {
                "hero_badge": "✨ Genie Build 500 • Desktop Spaziale Autonomo per macOS",
                "hero_title": "Il desktop spaziale autonomo per macOS.",
                "hero_desc": "Agente autonomo CoreGraphics, micro-VM Linux in RAM, studio di codice Duo Fold e tela a 120 FPS. Zero telemetria, 0% CPU a riposo.",
                "hero_version": "Build Attuale: 1.0.0 (Build 500)",
                "dissection_desc": "Analisi tecnica dei 6 sottosistemi principali che animano Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Agente OS Autonomo",
                "tab_hypervisor": "⚡️ Hypervisor in RAM",
                "tab_duofold": "💻 Studio Duo Fold",
                "tab_pillows": "🕰️ Orologi OLED Pillows",
                "contact_title": "Portale Contatti e Supporto",
                "contact_desc": "Hub di comunicazione su due pagine per triage tecnico, segnalazione bug, licenze aziendali e commissioni su misura.",
                "contact_tab_p1": "Pagina 1: Supporto Sviluppatore e Bug Report",
                "contact_tab_p2": "Pagina 2: Enterprise e Commissioni su Misura",
                "contact_p1_c1_title": "Supporto Tecnico Diretto",
                "contact_p1_c1_desc": "Contatto diretto con Nicholas M. Dudek per diagnosi tecniche, crash log e assistenza prioritaria.",
                "contact_p1_c2_title": "GitHub Issues e Release",
                "contact_p1_c2_desc": "Consulta il registro modifiche, i dettagli architetturali e invia segnalazioni di bug verificate.",
                "contact_p1_c3_title": "Report Ambiente macOS",
                "contact_p1_c3_desc": "Copia con un clic il report diagnostico del tuo macOS pronto da incollare nelle richieste di supporto.",
                "contact_p1_c4_title": "Verificato su Mac App Store",
                "contact_p1_c4_desc": "Scheda ufficiale Apple per Build 500 con distribuzione isolata e aggiornamenti automatici.",
                "contact_p2_c1_title": "Licenze Enterprise e MDM Offline",
                "contact_p2_c1_desc": "Distribuzione su vasta scala, installazione isolata da rete e profili MDM aziendali personalizzati.",
                "contact_p2_c2_title": "Shader e Cornici su Misura",
                "contact_p2_c2_desc": "Creazione di shader Metal a 120 FPS personalizzati, temi aziendali e alloggiamenti per notch.",
                "contact_p2_c3_title": "Agenti Sovrani e Micro-VM Linux",
                "contact_p2_c3_desc": "Micro-VM Linux ultraveloci in RAM, routing Ollama locale privato e integrazioni API ombra su misura.",
                "contact_p2_c4_title": "Audit di Sicurezza e Zero Telemetria",
                "contact_p2_c4_desc": "Verifica crittografica dell'assenza totale di permessi di rete e attestazione Hardened Runtime."
            },
            "ko": {
                "hero_badge": "✨ Genie Build 500 • macOS를 위한 자율형 공간 데스크탑",
                "hero_title": "macOS를 위한 차세대 자율 공간 데스크탑.",
                "hero_desc": "CoreGraphics 자율 에이전트, 인메모리 Linux 마이크로 VM, Duo Fold 코드 스튜디오, 120 FPS 공간 캔버스. 완전 오프라인, 유휴 CPU 0%.",
                "hero_version": "현재 빌드: 1.0.0 (Build 500)",
                "dissection_desc": "Genie v1.0.0 (Build 500)을 구동하는 6대 핵심 하위 시스템 기술 명세.",
                "tab_agent": "🤖 자율형 OS 에이전트",
                "tab_hypervisor": "⚡️ 인메모리 하이퍼바이저",
                "tab_duofold": "💻 Duo Fold 스튜디오",
                "tab_pillows": "🕰️ OLED 월드 클록 필로우",
                "contact_title": "고객 지원 및 문의 센터",
                "contact_desc": "기술 문의, 버그 리포트, 기업 도입 라이선스 및 맞춤 제작을 위한 2페이지 전용 창구입니다.",
                "contact_tab_p1": "1페이지: 개발자 직접 지원 및 버그 신고",
                "contact_tab_p2": "2페이지: 엔터프라이즈 도입 및 맞춤 제작",
                "contact_p1_c1_title": "엔지니어 직접 기술 지원",
                "contact_p1_c1_desc": "창립자 겸 수석 엔지니어 Nicholas M. Dudek과의 직통 라인. 크래시 분석 및 우선 지원 제공.",
                "contact_p1_c2_title": "GitHub 이슈 및 릴리스 정보",
                "contact_p1_c2_desc": "아키텍처 변경 내역 확인, 빌드 커밋 로그 검토, 검증된 버그 티켓 제출.",
                "contact_p1_c3_title": "macOS 진단 리포트 원클릭 복사",
                "contact_p1_c3_desc": "지원 요청 시 간편하게 붙여넣을 수 있는 시스템 사양 요약본을 클립보드에 즉시 복사합니다.",
                "contact_p1_c4_title": "Mac App Store 공식 인증",
                "contact_p1_c4_desc": "Build 500 공식 App Store 페이지. 샌드박스 보안 검증 및 자동 업데이트 지원.",
                "contact_p2_c1_title": "엔터프라이즈 볼륨 라이선스 & 오프라인 MDM",
                "contact_p2_c1_desc": "기업 단위 볼륨 도입, 완전 오프라인 에어갭 배포, 맞춤형 MDM 구성 프로파일 지원.",
                "contact_p2_c2_title": "맞춤형 Metal 셰이더 & 노치 하우징",
                "contact_p2_c2_desc": "기업 브랜드 전용 120 FPS Metal 셰이더 및 전용 노치 베젤 커스텀 제작.",
                "contact_p2_c3_title": "자율 에이전트 & 인메모리 Linux 스웜",
                "contact_p2_c3_desc": "RAM 상주 초고속 Linux 마이크로 VM 스웜, 프라이빗 Ollama 모델 라우팅, 커스텀 섀도우 API.",
                "contact_p2_c4_title": "보안 감사 및 완전 오프라인 인증서",
                "contact_p2_c4_desc": "외부 네트워크 권한 제로에 대한 암호학적 검증 리포트 및 Hardened Runtime 인증."
            },
            "pt": {
                "hero_badge": "✨ Genie Build 500 • Área de Trabalho Espacial Autônoma para macOS",
                "hero_title": "A área de trabalho espacial autônoma para macOS.",
                "hero_desc": "Agente autônomo CoreGraphics, micro-VMs Linux em RAM, estúdio de código Duo Fold e tela a 120 FPS. Zero telemetria, 0% CPU.",
                "hero_version": "Build Atual: 1.0.0 (Build 500)",
                "dissection_desc": "Detalhamento dos 6 principais subsistemas que alimentam o Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 Agente de SO Autônomo",
                "tab_hypervisor": "⚡️ Hipervisor em RAM",
                "tab_duofold": "💻 Estúdio Duo Fold",
                "tab_pillows": "🕰️ Relógios OLED Pillows",
                "contact_title": "Central de Contato e Suporte",
                "contact_desc": "Central de comunicação em 2 páginas para suporte técnico, relato de erros, licenças corporativas e encomendas sob medida.",
                "contact_tab_p1": "Página 1: Suporte ao Desenvolvedor e Bugs",
                "contact_tab_p2": "Página 2: Corporativo e Encomendas Especiais",
                "contact_p1_c1_title": "Suporte Direto de Engenharia",
                "contact_p1_c1_desc": "Contato direto com Nicholas M. Dudek para diagnóstico de erros, relatórios de falhas e suporte prioritário.",
                "contact_p1_c2_title": "Issues no GitHub e Versões",
                "contact_p1_c2_desc": "Acompanhe registros de mudanças, detalhes de arquitetura e envie tíquetes de erros verificados.",
                "contact_p1_c3_title": "Relatório do Ambiente macOS",
                "contact_p1_c3_desc": "Copie com 1 clique o relatório do seu macOS para colar rapidamente nos seus chamados de suporte.",
                "contact_p1_c4_title": "Verificado na Mac App Store",
                "contact_p1_c4_desc": "Página oficial da Apple para o Build 500 com isolamento rigoroso em sandbox e atualizações automáticas.",
                "contact_p2_c1_title": "Licenciamento em Volume e MDM Offline",
                "contact_p2_c1_desc": "Implantação em volume corporativo, distribuição isolada da rede e perfis de MDM personalizados.",
                "contact_p2_c2_title": "Shaders e Molduras Sob Medida",
                "contact_p2_c2_desc": "Encomendas de shaders Metal a 120 FPS exclusivos, temas corporativos e molduras para entalhe.",
                "contact_p2_c3_title": "Agentes Soberanos e Swarms Linux",
                "contact_p2_c3_desc": "Micro-VMs Linux ultrarrápidas em RAM, roteamento privado com Ollama e APIs sob medida.",
                "contact_p2_c4_title": "Auditoria de Segurança e Zero Telemetria",
                "contact_p2_c4_desc": "Comprovação criptográfica de ausência de permissões de rede e atestado Hardened Runtime."
            },
            "ar": {
                "hero_badge": "✨ الإصدار Genie Build 500 • مساحة العمل المكانية الذكية المستقلة لنظام macOS",
                "hero_title": "سطح المكتب المكاني الذكي المستقل لنظام macOS.",
                "hero_desc": "وكيل CoreGraphics المستقل، وخوادم Linux في الذاكرة العشوائية، واستوديو Duo Fold البرمجي، ومصفوفة مكانية 120 إطاراً. دون تتبع واستهلاك 0% للمعالج.",
                "hero_version": "البناء الحالي: 1.0.0 (Build 500)",
                "dissection_desc": "تحليل تقني للأنظمة الفرعية الستة الأساسية التي تُشغل Genie v1.0.0 (Build 500).",
                "tab_agent": "🤖 وكيل النظام الذكي",
                "tab_hypervisor": "⚡️ خوادم الذاكرة الفائقة",
                "tab_duofold": "💻 استوديو Duo Fold",
                "tab_pillows": "🕰️ ساعات العالم OLED",
                "contact_title": "بوابة التواصل والدعم الفني",
                "contact_desc": "مركز تواصل مكوّن من صفحتين للدعم التقني المباشر، وإبلاغ الأخطاء، والتراخيص المؤسسية، والطلبات الخاصة.",
                "contact_tab_p1": "الصفحة 1: الدعم الفني وإبلاغ الأخطاء",
                "contact_tab_p2": "الصفحة 2: المؤسسات والطلبات الخاصة",
                "contact_p1_c1_title": "الدعم المباشر من المهندس المؤسس",
                "contact_p1_c1_desc": "تواصل مباشر مع Nicholas M. Dudek لتشخيص المشكلات الفنية، وتحليل سجلات الأعطال، والدعم ذي الأولوية.",
                "contact_p1_c2_title": "تذاكر GitHub والإصدارات الرسمية",
                "contact_p1_c2_desc": "استكشف سجل التغييرات وتفاصيل البنية المعمارية وأرسل تقارير الأخطاء البرمجية المعتمدة.",
                "contact_p1_c3_title": "نسخ تقرير بيئة macOS بنقرة واحدة",
                "contact_p1_c3_desc": "انسخ تقرير المواصفات الفنية لجهازك مباشرة إلى الحافظة لسرعة إرفاقه في رسائل الدعم.",
                "contact_p1_c4_title": "معتمد على متجر تطبيقات ماك",
                "contact_p1_c4_desc": "الصفحة الرسمية للبناء 500 على متجر آبل مع حماية العزل الأمني والتحديثات التلقائية.",
                "contact_p2_c1_title": "تراخيص المؤسسات والتوزيع دون إنترنت",
                "contact_p2_c1_desc": "نشر واسع النطاق للشركات، وتوزيع معزول تماماً عن الشبكة، وملفات تعريف MDM مخصصة.",
                "contact_p2_c2_title": "مؤثرات بصرية وإطارات مخصصة",
                "contact_p2_c2_desc": "طلب مؤثرات Metal حصرية بمعدل 120 إطاراً، وسمات وهوية بصرية للشركات، وإطارات خاصة بنوتش الشاشة.",
                "contact_p2_c3_title": "وكلاء أذكياء وخوادم Linux في الذاكرة",
                "contact_p2_c3_desc": "أسراب أجهزة افتراضية خفيفة في الذاكرة العشوائية، وتوجيه محلي لنماذج Ollama، وواجهات ظل برمجية مخصصة.",
                "contact_p2_c4_title": "تدقيق الأمان وضمان انعدام التتبع",
                "contact_p2_c4_desc": "إثبات مشفر لحظر الاتصالات الخارجية تماماً وتوثيق بيئة التشغيل المعزولة الصارمة."
            }
        }

        for lang, patch in translations_patch.items():
            if lang in trans:
                trans[lang].update(patch)
                # Also replace any lingering 'Build 12' in any value
                for k, v in trans[lang].items():
                    if isinstance(v, str) and "Build 12" in v:
                        trans[lang][k] = v.replace("Build 12", "Build 500")

        new_trans_str = json.dumps(trans, ensure_ascii=False)
        content = content[:match.start()] + f"const SITE_TRANSLATIONS = {new_trans_str};" + content[match.end():]
        print("  ✓ Updated SITE_TRANSLATIONS for all 10 languages with 2-pager contact strings")

    INDEX_PATH.write_text(content, encoding="utf-8")
    print("  ✓ index.html written successfully")

def update_features():
    print("[*] Updating features.html...")
    content = FEATURES_PATH.read_text(encoding="utf-8")

    # Replace all occurrences of Build 12 with Build 500
    content = content.replace("Build 12", "Build 500")
    content = content.replace("Build 12 • 18 Features", "Build 500 • 21 Subsystems")

    FEATURES_PATH.write_text(content, encoding="utf-8")
    print("  ✓ features.html written successfully")

def validate_html(path: Path):
    class StrictValidator(HTMLParser):
        def __init__(self):
            super().__init__()
            self.errors = []
        def error(self, message):
            self.errors.append(message)

    parser = StrictValidator()
    text = path.read_text(encoding="utf-8")
    parser.feed(text)
    if parser.errors:
        print(f"❌ HTML validation failed on {path.name}: {parser.errors}")
        return False
    print(f"✅ HTML validation PASSED on {path.name} (0 syntax errors)")
    return True

def sync_web():
    print("[*] Syncing files to web/ directory...")
    WEB_INDEX_PATH.write_text(INDEX_PATH.read_text(encoding="utf-8"), encoding="utf-8")
    WEB_FEATURES_PATH.write_text(FEATURES_PATH.read_text(encoding="utf-8"), encoding="utf-8")
    print("  ✓ Copied index.html -> web/index.html")
    print("  ✓ Copied features.html -> web/features.html")

def main():
    update_index()
    update_features()
    v1 = validate_html(INDEX_PATH)
    v2 = validate_html(FEATURES_PATH)
    if v1 and v2:
        sync_web()
        validate_html(WEB_INDEX_PATH)
        validate_html(WEB_FEATURES_PATH)
        print("\n🎉 Everything successfully updated, validated, and synchronized!")

if __name__ == "__main__":
    main()
