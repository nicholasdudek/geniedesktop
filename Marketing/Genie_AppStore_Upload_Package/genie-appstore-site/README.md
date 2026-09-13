# Genie 1.0 — Isolated Mac App Store Static Site Package

This directory contains **ONLY** the public-facing static web assets required by Apple App Store Connect for **Genie 1.0 (Spatial AI Studio & Cockpit)**:

1. **`index.html`**: The public showcase marketing page.
2. **`privacy.html`**: The zero-telemetry Apple App Store privacy policy.
3. **`features.html`**: Public feature specifications (Metal shaders, living dock companions, OLED clocks).
4. **`assets/`**: Public icons, preview graphics, CSS, and interactive shaders.

---

## 🔒 100% Air-Gapped From Proprietary Code & Documents

This folder contains:
- ❌ **NO** Swift source code
- ❌ **NO** internal architecture documents or sales pitches
- ❌ **NO** neural weights, prompt files, or API credentials
- ❌ **NO** reverse-engineered SkyLight or private framework headers

You can safely publish this folder to the public internet without exposing any proprietary engineering.

---

## 🚀 Deployment Options (Zero Vercel Needed)

### Option A: Cloudflare Pages (Recommended — Fast, Free, No Code Exposure)
Cloudflare Pages provides global CDN, free SSL, DDoS protection, and unlimited bandwidth without tying into your GitHub account if you don't want it to.

1. **Direct Drag-and-Drop** (Zero Git required):
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → **Workers & Pages** → **Create application** → **Pages** → **Upload assets**.
   - Drag and drop this `genie-appstore-site` folder.
   - Name your project (e.g. `geniedesktop` or `genie-app`).
   - Done! Instant live URL: `https://geniedesktop.pages.dev` (or attach your custom domain).

2. **Via Terminal**:
   ```bash
   npx wrangler pages deploy . --project-name=genie-app
   ```

### Option B: Dedicated Public GitHub Pages Repo (Isolated from Code)
If you want to use GitHub Pages, create a **completely new and separate repository**:

1. Create a new empty repository on GitHub: `https://github.com/new` named `genie-site` (Public).
2. In this directory, initialize git and push:
   ```bash
   cd Marketing/Genie_AppStore_Upload_Package/genie-appstore-site
   git init
   git branch -M main
   git add .
   git commit -m "Deploy Genie 1.0 Mac App Store marketing & privacy site"
   git remote add origin https://github.com/nicholasdudek/genie-site.git
   git push -u origin main --force
   ```
3. In GitHub repo settings → **Pages** → Source: `Deploy from branch main / (root)`.
4. Your App Store URLs become:
   - **Marketing URL**: `https://nicholasdudek.github.io/genie-site/`
   - **Privacy URL**: `https://nicholasdudek.github.io/genie-site/privacy.html`
   - **Support URL**: `https://nicholasdudek.github.io/genie-site/#contact`

---

## 🛡️ Hiding Your Main Codebase & Documents Off GitHub

To protect your core intellectual property in the main `GoldGate` repository:

1. **Set `geniedesktop` to Private**:
   - Go to `https://github.com/nicholasdudek/geniedesktop/settings`.
   - Under **Danger Zone** → **Change repository visibility** → **Make Private**.
2. **Or Completely Remove GitHub Remote (Local Sovereign Mac Repo)**:
   - If you do not want your proprietary code on GitHub servers at all:
     ```bash
     git remote remove origin
     ```
   - All Git commit history and branches stay safe locally on your Mac's NVMe drive. Back it up to Time Machine or an encrypted APFS drive.
