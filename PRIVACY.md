# Privacy Policy for Genie — Desktop Workspace

**Effective Date**: September 2, 2026  
**Last Updated**: September 6, 2026  
**Product**: Genie — Desktop Workspace (`com.nicholasdudek.genie` • legacy: `com.nicholasdudek.goldgate`)  
**Developer**: Nicholas M. Dudek  
**Contact**: `nicholas.dudek@icloud.com`

---

## 1. Overview & Core Privacy Guarantee

Genie — Desktop Workspace is engineered from the ground up with a strict **Privacy-First, Zero-Telemetry Architecture**. 

We believe that your desktop workspace, installed applications, file organization, and computing habits are strictly personal. Genie functions **100% offline** on your Mac. It does not collect, record, log, profile, track, transmit, or monetize any personal data, usage analytics, or system information.

---

## 2. Data Collection & Processing

### No Collection of Personal Information
Genie does **NOT** collect:
- Names, email addresses, phone numbers, or physical addresses.
- IP addresses, MAC addresses, hardware serial numbers, or UUID device identifiers.
- Keystrokes, mouse coordinates, screen recordings, or clipboard contents.
- Application usage frequencies, browsing histories, or launch logs.
- Diagnostic crash telemetry, performance logs, or behavioral analytics.

### Local On-Device Execution
All data processing performed by Genie occurs strictly locally on your Mac's CPU and GPU:
- **Application Directory Indexing**: When indexing installed apps, Genie queries local standard application directories (`/Applications`, `/System/Applications`, `~/Applications`) and local Spotlight indexes (`kMDItemContentType == 'com.apple.application-bundle'`). This indexing occurs in ephemeral system memory and is never transmitted off your device.
- **Icon Rendering & Caching**: Application icons are extracted from local bundle resources via `NSWorkspace` and cached in an in-memory `NSCache`. No icon images or visual assets are ever transmitted externally.
- **Preference Storage**: User customization preferences (selected themes, grid scaling, battery styles, audio profiles, and custom icon orders) are stored locally on your device within your sandboxed macOS `UserDefaults` container (`~/Library/Containers/com.nicholasdudek.genie/Data/Library/Preferences/com.nicholasdudek.genie.plist`).

---

## 3. macOS App Sandbox & Network Entitlement Transparency

Genie is distributed in strict compliance with the **Apple macOS App Sandbox**:

```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
```

### Zero Network Access
- The compiled Genie application bundle **completely omits** the network client entitlement (`com.apple.security.network.client`).
- By operating system design, macOS prohibits the application from initiating outbound socket connections, making HTTP/HTTPS requests, querying remote APIs, or communicating with remote servers.
- Even if third-party analytics code were introduced, macOS sandboxing would block any outbound network traffic at the kernel level.

### File System Isolation
- The application cannot access user files outside of standard sandboxed temporary workspaces and explicitly user-selected files (e.g. if you select a custom brand logo image via an open panel).
- Genie does not read, modify, or scan your personal documents, photos, desktop files, or downloads.

---

## 4. Third-Party Analytics & Tracking SDKs

Genie contains **zero third-party software development kits (SDKs)**. 
- We do not embed Google Analytics, Firebase, Mixpanel, Segment, Sentry, Facebook SDK, or any advertising or marketing tracking frameworks.
- The codebase is 100% native Swift, SwiftUI, AppKit, Metal, and StoreKit 2.

---

## 5. In-App Purchases & Financial Privacy

Optional expansion packs in Genie are processed exclusively through **Apple StoreKit 2**:
- All financial transactions, billing details, credit card numbers, and Apple ID authentications are handled directly by Apple Inc. via macOS system services.
- The developer never receives, processes, or stores your payment details or financial credentials.
- In-app entitlement validation uses cryptographic on-device StoreKit verification (`Transaction.currentEntitlements`).

---

## 6. Children's Privacy (COPPA)

Genie does not knowingly collect or solicit any information from anyone, including children under the age of 13 (or under 16 in the European Union). Because Genie collects zero data from all users, it is fully compliant with the Children's Online Privacy Protection Act (COPPA) and international standards.

---

## 7. Global Privacy Regulations (GDPR & CCPA/CPRA)

- **GDPR (European General Data Protection Regulation)**: Because no personal data is collected, stored, processed, or transferred to third parties, Genie operates in full compliance with the GDPR. Users have no personal data subject to deletion or portability requests since no data exists outside the user's local Mac.
- **CCPA / CPRA (California Consumer Privacy Act)**: Genie does not sell, share, rent, or monetize personal information. Zero consumer data is collected or disclosed.

---

## 8. App Store Review Guidelines Compliance

This privacy policy complies with **Apple App Store Review Guideline 5.1 (Legal - Privacy - Data Collection and Storage)**:
1. Genie only accesses data required for the app's primary desktop launcher and workspace functionality.
2. The app requests no unnecessary permissions or entitlements.
3. The app provides a transparent, legally binding statement of zero data collection.

---

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect future software enhancements or regulatory updates. Any changes will be published in this document and included with application release notes. Your continued use of Genie following any updates confirms your acceptance of the policy.

---

## 10. Contact & Inquiries

If you have any questions, suggestions, or concerns regarding this Privacy Policy or Genie's privacy architecture, please contact:

**Nicholas M. Dudek**  
Email: `nicholas.dudek@icloud.com`  
Support & Issue Tracker: `https://github.com/nicholasdudek/geniedesktop/issues`  
Repository: `https://github.com/nicholasdudek/geniedesktop`

Copyright © 2026 Nicholas M. Dudek. All rights reserved.
