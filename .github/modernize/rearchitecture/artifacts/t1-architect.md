# t1 - Menu Bar UI Behavior Analysis and In-Place UX Change Map

## Summary

The current menu dropdown implementation does not include the requested non-working items (Desktop App Grid, Smart Fit, Fixed Grid, Position Left/Center/Right). The visible controls in the current build are focused on popover unlock/reset, battery/icon styling, hidden-app restore, refresh, and quit.

Because the requested items are already absent in source, the required in-place UX change for implementation should be treated as a no-op in current code plus a verification pass that no legacy controls remain reachable in runtime UI.

## Current Behavior Map (Controls Tab)

1. Unlock Frame toggle:

- State key: `nexus.popoverFreePositionEnabled`
- Enables free panel movement when on.
- Posts `NexusPopoverUnlockChanged`.

2. Reset Position button:

- Visible only when Unlock Frame is on.
- Posts `NexusResetPopoverPosition`.
- Clears saved custom popover origin and returns to anchored placement behavior.

3. Show Battery % toggle:

- State key: `nexus.showBatteryPercentage`
- Posts `NexusIconStyleChanged` on change.

4. Style picker + Animation slider:

- State keys: `nexus.iconStyle`, `nexus.animSpeed`
- Posts icon/animation update notifications.

5. Hidden Apps menu:

- Conditionally visible when hidden apps exist.
- Supports unhide individual or unhide all.

6. Footer actions:

- Refresh and Quit.

## Legacy Feature Presence Check

Requested removals were checked against current source and no occurrences were found:

- `Desktop App Grid`
- `Smart Fit`
- `Fixed Grid`
- `Position Left`
- `Position Center`
- `Position Right`

## In-Place UX Contract for Downstream Implementation (t3)

1. Do not introduce any grid-mode or position-segment controls while implementing t3.
2. Preserve current visual structure and spacing of existing control cards.
3. Preserve existing notification wiring and user defaults keys for retained controls.
4. Preserve conditional visibility rule for Reset Position under Unlock Frame only.
5. If any residual legacy controls are discovered at runtime only (not in source), remove them without altering retained control typography, paddings, and card styles.

## Risks and Mitigations

- HIGH: User-reported non-working items may come from a stale binary rather than current source.
  - Mitigation: tester validates runtime menu against current build artifacts after fresh build/run.
- MEDIUM: Feature-council docs still reference legacy grid concepts and can cause implementation confusion.
  - Mitigation: prioritize source-of-truth in current `Sources/Nexus/Views/MenuBarDropdownView.swift` and current runtime behavior.

## Upstream Artifacts Consumed

- `/Users/nicholasdudek/Nexus/.github/modernize/rearchitecture/clarification.md` - confirmed exact removal intent and preserve-style constraint.

## Evidence Mapping

- `clarification.md#Success definition` -> no-op source removal conclusion + explicit downstream no-reintroduction contract.
- `clarification.md#Screenshots` -> runtime-only residue check requirement in downstream implementation and validation.

## Test Results

- Command: `n/a (analysis-only architect task)`
- Passed: 0
- Failed: 0
- Skipped: 0
