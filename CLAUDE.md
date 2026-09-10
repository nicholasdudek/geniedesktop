# Genie (GoldGate)

Native macOS spatial launcher + local-AI app. SwiftPM package named `Genie`, target
source under `Sources/GoldGate`. Bundle id `com.nicholasdudek.genie`.

## Build

```sh
swift build
```

`.build/out` caches hard. **"Build complete! (0.2s)" means nothing recompiled** — it is
not evidence your change compiled. To force a real build, `rm -rf .build/out` (~60s, 168
units). If that fails with "Directory not empty", another build is writing there right
now; do not fight it — build into an isolated tree instead:

```sh
swift build --scratch-path /tmp/genie-verify    # ~95s, fully isolated
```

`.build/` is tracked by git, so `git status` is thousands of build artifacts and is
near-useless for reviewing your own diff. Scope it: `git status --porcelain -- Sources/`.

Before blaming your edits for a failure, check whether something else touched the tree:

```sh
find Sources -name '*.swift' -newermt '-10 minutes'
```

A second agent session editing this repo concurrently has previously deleted files
mid-build and broken SwiftPM's cached file glob. Prefer targeted substitutions over
whole-file rewrites so concurrent edits survive.

## AI providers

`GenieBrainProvider` has four cases: `.local`, `.cloudGemini`, `.cloudClaude`,
`.cloudOpenAI`. **Local-first is the intended default and the one to keep working.**

- **Local** — Ollama on `http://localhost:11434`. Machine holds fine-tuned models
  (`genie-master`, `genie-macos-agent`, `genie-3`) plus `qwen3-coder:30b-64k`,
  `deepseek-r1:32b`, `codestral`. No key, no billing, works offline. Prefer this.
- **Cloud Gemini** — hits `generativelanguage.googleapis.com` (the **Gemini Developer
  API**), NOT Vertex. See `LocalModelManager.generateGemini`.

### Credential handling — read before touching keys

`LocalModelManager` routes the credential by prefix:

```swift
let isBearerToken = cleanKey.hasPrefix("ya29.")   // -> Authorization: Bearer
                                                  // else -> ?key= + x-goog-api-key
```

So only two forms work: a `ya29.` OAuth bearer token, or an `AIza…` (39-char) API key.
Anything else falls between the branches and every request fails.

Earlier builds shipped a hardcoded `AQ.` token as the registered default and re-injected
it on every launch from three places, so clearing the field never stuck. That is removed.
**The key now lives in the Keychain** (`GenieKeychain`, service
`com.nicholasdudek.genie.geminiApiKey`), never in the preference plist. Do not add
credentials to `PrefKey`/`UserDefaults`, and never hardcode one in source.

Note for the App Store build: it is sandboxed, so a Keychain item added by the `security`
CLI in your login keychain is not necessarily readable by the app. Entering the key once
in Settings writes it to the app's own item.

## Google Cloud

Project **`oval-proxy-508120-h8`** (number 869473828583). A $30/month budget is scoped to
it — budgets **alert only, they do not cap spend**.

Enabled and sufficient; do not enable more without a reason:

| Purpose | API |
|---|---|
| Genie's cloud fallback | `generativelanguage.googleapis.com` |
| Antigravity CLI (`agy`) / Agent Platform | `aiplatform.googleapis.com` |
| gcloud MCP (remote form) | `cloudcli.googleapis.com` |
| Minting keys | `apikeys.googleapis.com` |

Avoid Compute Engine, Notebooks, and Security Command Center — all bill against the
budget for capabilities this project does not use.

The project id must agree in four places or `gcloud` quotas against the wrong project:
`gcloud config` `project`, `gcloud config` `billing/quota_project`, ADC's
`quota_project_id`, and `GOOGLE_CLOUD_PROJECT` in `~/.zshrc`.

## Packaging

- `package_for_app_store.sh` — release build, signs with "3rd Party Mac Developer",
  sandboxed `Genie.AppStore.entitlements`, builds `Genie.pkg`, installs to /Applications
- `upload_to_app_store.sh` — altool validate + upload; password from
  `APP_SPECIFIC_PASSWORD` or keychain item `GENIE_ASC_PASSWORD`

Python tests are source-scanning checks: `.venv/bin/python -m pytest tests/`

## Automation IPC

`DistributedNotificationCenter` names `com.user.nexus.tab` (object = sidebar tab, e.g.
`"system"`, `"aiModels"`), `.grid`, `.open`, `.summon`. URL scheme `genie://canvas`.
The sandboxed build's `~/.gemini/genie_action.trigger` lives in the app container, not
the real home.
