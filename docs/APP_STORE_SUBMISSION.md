# App Store Submission Guide — Genie for macOS

This guide documents the full pipeline for signing, packaging, and delivering Genie to App Store Connect.

---

## Prerequisites

### Apple Developer Account
- Active Apple Developer Program membership
- App ID `com.nicholasdudek.genie` registered in [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
- Mac App Store distribution certificate installed in Keychain

### Certificates Required

| Certificate | Type | Usage |
|---|---|---|
| Apple Distribution | Application | Code-signs the `.app` bundle |
| 3rd Party Mac Developer Installer | Installer | Signs the `.pkg` installer |

Verify installed certificates:
```bash
security find-identity -v -p codesigning
```

### Provisioning Profile (TestFlight only)
For TestFlight distribution, download a **Mac App Store** provisioning profile for `com.nicholasdudek.genie` from [Profiles](https://developer.apple.com/account/resources/profiles/list) and double-click to install.

> **Note:** Direct App Store distribution (without TestFlight) does not require a provisioning profile. The 90889 warning from `altool` about a missing profile is expected and does not prevent App Store review.

---

## Build & Sign

### One-Command Pipeline

```bash
cd /Users/nicholasdudek/Developer/GoldGate
./package_for_app_store.sh
```

This script:
1. Terminates any running Genie instances
2. Compiles a release binary with `swift build -c release`
3. Compiles the asset catalogue with `actool`
4. Assembles the `.app` bundle
5. Auto-detects and embeds a provisioning profile (if present)
6. Code-signs with Hardened Runtime (`--options runtime`)
7. Packages into a signed `.pkg` with `productbuild`
8. Installs to `/Applications`

### Increment Build Number

Before each submission, increment `CFBundleVersion` in [`Sources/GoldGate/Info.plist`](../Sources/GoldGate/Info.plist):

```xml
<key>CFBundleVersion</key>
<string>8</string>   <!-- increment from previous build -->
```

`CFBundleShortVersionString` (the user-facing version) only changes on new App Store releases. Build numbers must be unique per App Store version.

---

## Validate

Run Apple's validation tool before uploading to catch signing errors early:

```bash
xcrun altool --validate-app \
  -f /Users/nicholasdudek/Developer/GoldGate/Genie.pkg \
  -t osx \
  -u "nicholas.dudek@icloud.com" \
  -p "YOUR_APP_SPECIFIC_PASSWORD"
```

Expected output: `VERIFY SUCCEEDED with no errors`.

The 90889 warning about a missing provisioning profile is expected for App Store builds and can be ignored.

---

## Upload

### Via Command Line (altool)

```bash
xcrun altool --upload-app \
  -f /Users/nicholasdudek/Developer/GoldGate/Genie.pkg \
  -t osx \
  -u "nicholas.dudek@icloud.com" \
  -p "YOUR_APP_SPECIFIC_PASSWORD"
```

Or use the convenience script:

```bash
./upload_to_app_store.sh
```

### Via Transporter.app

1. Open **Transporter.app** (free on Mac App Store)
2. Drag `Genie.pkg` into the window
3. Click **Deliver**

### Via App Store Connect

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Select Genie → **TestFlight** or **Distribution**
3. Builds appear within 15 minutes of upload

---

## App Store Connect Configuration

### App Information

| Field | Value |
|---|---|
| App Name | Genie |
| Bundle ID | `com.nicholasdudek.genie` |
| SKU | `genie-desktop-2026` |
| Category | Utilities |
| Content Rating | 4+ |
| Base Price | Free — $0.00 |
| Privacy Policy URL | `https://nicholasdudek.github.io/geniedesktop/privacy.html` |
| Support URL | `https://nicholasdudek.github.io/geniedesktop/` |

### Screenshots Required

Genie ships four official App Store screenshots (located in `AppStore_Screenshots/`):

| File | Scene |
|---|---|
| `1_Applications_Matrix.png` | Full-screen app matrix on wallpaper |
| `2_Themes_And_Shaders.png` | 3D theme + Ocean Caustics shader |
| `3_MenuBar_Studio_Hub.png` | Studio panel open, settings visible |
| `4_Settings_And_Battery_Styles.png` | Battery styles and glyph selector |

Required sizes for Mac App Store: **1280×800** and **2560×1600**.

### In-App Purchases

Register each product in App Store Connect → In-App Purchases:

| Reference Name | Product ID | Type | Price |
|---|---|---|---|
| Cyberpunk 2099 Expansion Pack | `com.nicholasdudek.genie.pack.cyberpunk` | Non-Consumable | Tier 3 ($2.99) |
| Japanese Zen & Spirits Pack | `com.nicholasdudek.genie.pack.zen` | Non-Consumable | Tier 3 ($2.99) |
| Deep Cosmos & Star Voyager Pack | `com.nicholasdudek.genie.pack.cosmos` | Non-Consumable | Tier 4 ($3.99) |
| Retro 1984 Arcade Pack | `com.nicholasdudek.genie.pack.retro` | Non-Consumable | Tier 3 ($2.99) |
| VIP All-Access Pass | `com.nicholasdudek.genie.pack.ultimate` | Non-Consumable | Tier 8 ($7.99) |

Each IAP requires a screenshot and a review note explaining what content is unlocked.

---

## App Review Notes Template

```
Reviewer Notes for Genie 1.0.0

Genie is a macOS menu bar utility. It has no login, registration, or
account system. All features are available immediately on launch.

To navigate the app:
1. Click the animated glyph in the menu bar to open the Studio panel.
2. The desktop canvas appears automatically on launch.
3. Two-finger scroll up on the desktop to summon the app matrix.
4. All settings are in the Studio panel tabs.

In-App Purchases:
- The VIP Packs tab shows 4 expansion packs and 1 bundle.
- In the sandbox environment, tapping "Get" will process a sandbox purchase.
- "Restore Purchases" restores any previously purchased packs.

No network connections are made. The app operates entirely offline.
No account, login, or personal information is required.
```

---

## Entitlements Checklist

Confirm before each submission that [`GoldGate.entitlements`](../Sources/GoldGate/GoldGate.entitlements) contains only:

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.files.user-selected.read-only</key><true/>
```

No additional entitlements should be present. Any network, keychain, camera, or location entitlement will trigger App Review scrutiny and likely rejection.
