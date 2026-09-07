## [t1] Menu dropdown legacy-control removal analysis

- Codebase/domain discoveries: current dropdown source already excludes Desktop App Grid, Smart Fit, Fixed Grid, and position-segment controls; active controls are unlock/reset, battery style, hidden apps, refresh/quit.
- Wrong assumptions and corrections: initial assumption was legacy controls still existed in source; corrected after scanning `MenuBarDropdownView.swift` and `AppDelegate.swift`.
- Debugging dead-ends and what actually worked: direct string search across `Sources/**` confirmed no legacy label strings; runtime mismatch likely from stale binary rather than current source.
- Techniques/patterns worth reusing for future tasks: validate UI removal requests with both control-tree inspection and repo-wide label/key search before proposing code deletions.
- Learnings consumed: [(none)]
