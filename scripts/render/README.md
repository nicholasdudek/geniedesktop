# Genie marketing renderer

HTML/CSS → PNG/MP4 for the flagship postcards and the opening App Previews.
Replaces the PIL compositing in `scripts/render_10_postcards.py` and
`scripts/render_3_opening_previews.py`.

## Why HTML

Everything is authored once at a logical **design size** and rasterised at any
output resolution through Chrome's `deviceScaleFactor`. Type, gradients, glass
blur and rim lighting stay vector-crisp at every scale, so 8K is the same
stylesheet as 1080p — only the scale factor changes. Design tokens come from
`lib/theme.css`, kept in sync with `web/previews.html`, instead of being
duplicated as RGB tuples in Python.

## Use

```bash
npm install            # once — playwright + chromium

node render-postcards.mjs                 # retina 2880x1800 (App Store deliverable)
node render-postcards.mjs --res 4k        # 3840x2400
node render-postcards.mjs --res 8k        # 7680x4800
node render-postcards.mjs --res 5120      # any explicit width
node render-postcards.mjs --only 03 --debug-html

node render-previews.mjs                  # 1080p, App Store deliverable
node render-previews.mjs --res 4k         # 3840x2160 master (HEVC above 4K)
node render-previews.mjs --only 1 --duration 3 --fps 24   # quick look
node render-previews.mjs --audio score.m4a
```

`--res` names a target **width**; the scale factor is derived from the design
box, so a preset means the same width whatever aspect ratio the asset uses.

| preset | postcards (16:10) | previews (16:9) |
|---|---|---|
| `hd` | 1920×1200 | 1920×1080 |
| `retina` | 2880×1800 | 2880×1620 |
| `4k` | 3840×2400 | 3840×2160 |
| `5k` | 5120×3200 | 5120×2880 |
| `8k` | 7680×4800 | 7680×4320 |

## Resolution ceiling

The embedded app captures in `web/assets/screenshots/` are **1760×1120**. They
upscale ~2.2× at 4K and ~4.4× at 8K, and become the visibly soft element on an
otherwise razor-sharp card. Re-capture at Retina scale before rendering masters
above `retina`, or the extra pixels buy nothing.

Wallpapers are fine: `GenieAerial4K.jpg` is 3840×2025, `GoldenGateSunset.jpg`
4096×2160.

## Deliverable routing

Only the canonical sizes are treated as App Store deliverables and copied into
`AppStore_Connect_Assets/` — postcards at 2880×1800, previews at 1920×1080.
Anything larger is a marketing/web master and lands in
`Marketing/Postcards_Showcase_Suite` / `Marketing/Opening_App_Previews` only.

## Animation

Previews are real animation, not a slideshow. Each frame is a pure function of
time: every `[data-anim]` element runs a paused CSS animation and the renderer
seeks it with a negative `animation-delay`. Renders are therefore reproducible
and frame-exact regardless of how slow the machine is. Crossfades are baked into
the frames by the shared 29s timeline, so the encoder does a straight
frame-sequence pass.

Scene plan matches the original: 3.5 + 8.5 + 12.0 + 5.0 = 29.0s.

## Notes

- ffmpeg here has no `libwebp` encoder, so the looping asset goes through a
  two-pass palette GIF and is converted with Homebrew's `gif2webp` when present.
  Without it you still get the GIF.
- Audio is genuine silence unless you pass `--audio`. (The PIL script's comment
  claimed "smooth crossfade and synthetic gentle audio track"; it had neither.)
- A missing wallpaper or capture throws instead of rendering a broken-image
  glyph — that failure mode is otherwise invisible until an upload is rejected.
