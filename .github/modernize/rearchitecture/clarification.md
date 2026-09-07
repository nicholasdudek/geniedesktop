---
schema: clarification/v1
generated_at: "2026-09-01T05:44:00Z"
scope:
  - frontend
clarity_score: 1.00
rounds: 1
gaps:
  - id: i18n.locales
    resolution: default
    default_used: "preserve current locales; keep existing i18n library if present"
  - id: state_mgmt.preference
    resolution: default
    default_used: "preserve existing pattern if identifiable; otherwise recommend minimal (component state + server-state library)"
  - id: routing.preference
    resolution: default
    default_used: "use the de-facto router for the chosen target framework"
blocking_gaps: []
---

# Scenario Clarification

## Frontend

- **Target framework**: Hybrid SwiftUI+AppKit (existing stack)
- **Component library**: Existing custom components
- **Screenshots**: Screenshot provided in chat; remove non-working desktop app grid options shown while preserving key styling
- **Design system**: Match existing pixel-by-pixel where retained
- **Accessibility**: WCAG 2.1 AA equivalent
- **Browser targets**: latest and previous major macOS versions
- **Responsive strategy**: preserve current behavior exactly for retained controls
- **i18n locales**: preserve current locales; keep existing i18n library if present (default)
- **State management**: preserve existing pattern if identifiable; otherwise recommend minimal (component state + server-state library) (default)
- **Routing**: use the de-facto router for the chosen target framework (default)

## Generic

- **Success definition**: Remove non-working grid smart features from the menu, specifically Smart Fit, Fixed Grid, and any dependent controls that require those features, while preserving existing visual style
- **Out of scope**: full UI redesign out of scope
- **Existing test posture**: must pass

---

## Gaps & Defaults Applied

- id: i18n.locales
  resolution: default
  default_used: "preserve current locales; keep existing i18n library if present"
- id: state_mgmt.preference
  resolution: default
  default_used: "preserve existing pattern if identifiable; otherwise recommend minimal (component state + server-state library)"
- id: routing.preference
  resolution: default
  default_used: "use the de-facto router for the chosen target framework"

## Downstream Usage Notes

- Items listed under "Gaps & Defaults Applied" were not explicitly confirmed by the user. Treat them as working assumptions and flag them if they affect critical design decisions.
- Items listed under `blocking_gaps` must be highlighted in the plan summary at the next checkpoint so the user can confirm or provide values before implementation begins.
- Do not re-ask the user about items that are fully answered in this file.
