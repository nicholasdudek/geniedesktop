# Privacy Policy for Genie — Desktop Workspace

**Effective Date**: September 3, 2026  
**Product**: Genie — Desktop Workspace (`com.nicholasdudek.genie`)  
**Developer**: Nicholas M. Dudek  
**Contact**: `nicholas.dudek@icloud.com`  
**Web Policy**: [https://nicholasdudek.github.io/geniedesktop/privacy.html](https://nicholasdudek.github.io/geniedesktop/privacy.html)

---

## 1. Zero-Telemetry Guarantee
Genie is engineered from the ground up with a strict **Privacy-First, Zero-Telemetry Architecture**. 

Genie functions **100% offline** on your Mac. It does not collect, record, log, profile, track, transmit, or monetize any personal data, usage analytics, or system information.

---

## 2. Zero Data Collection
Genie does **NOT** collect:
- Names, email addresses, phone numbers, or physical addresses.
- IP addresses, MAC addresses, hardware serial numbers, or UUID identifiers.
- Keystrokes, mouse coordinates, screen recordings, or clipboard contents.
- Application usage frequencies, browsing histories, or launch logs.
- Diagnostic crash telemetry, performance logs, or behavioral analytics.

---

## 3. Local On-Device Execution
All operations are executed strictly locally on your Mac's CPU and GPU:
- **Application Indexing**: When indexing installed apps, Genie queries local standard directories (`/Applications`) in ephemeral memory. Never transmitted externally.
- **Icon Rendering**: Cached in an in-memory `NSCache`. No visual assets ever leave your device.
- **Preference Storage**: User customization preferences (themes, grid scaling, battery styles, audio profiles) are stored locally in your sandboxed `UserDefaults` container.

---

## 4. macOS App Sandbox & Zero Network Access
Genie operates in strict compliance with the Apple macOS App Sandbox:
- The compiled application bundle **completely omits network client entitlements** (`com.apple.security.network.client`).
- By operating system design, macOS prohibits Genie from initiating outbound socket connections, making HTTP/HTTPS queries, or communicating with remote servers.

---

## 5. In-App Purchases (StoreKit 2)
Expansion packs are handled directly by Apple Inc. through **StoreKit 2**:
- The developer never receives, processes, or stores your payment details or financial credentials.
- In-app entitlement validation uses cryptographic on-device StoreKit verification.

---

## 6. App Store Review Guidelines Compliance
This policy satisfies **Apple App Store Review Guideline 5.1 (Legal - Privacy - Data Collection and Storage)**.

---

## 7. Contact
For any questions regarding this Privacy Policy:
- **Email**: `nicholas.dudek@icloud.com`
- **Support**: `https://github.com/nicholasdudek/geniedesktop/issues`

Copyright © 2026 Nicholas M. Dudek. All rights reserved.
