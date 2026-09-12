import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { ROOT, asset } from '../lib/renderer.mjs';

const theme = await readFile(resolve(ROOT, 'lib/theme.css'), 'utf8');

/** 16:9. x2 = 4K UHD, x4 = 8K UHD. */
export const DESIGN = { width: 1920, height: 1080 };

/** Scene plan, ported from render_3_opening_previews.py (3.5 + 8.5 + 12.0 + 5.0). */
export const SCENES = [
  { id: 'hero', duration: 3.5 },
  { id: 'showcase', duration: 8.5 },
  { id: 'features', duration: 12.0 },
  { id: 'close', duration: 5.0 },
];
export const DURATION = SCENES.reduce((a, s) => a + s.duration, 0); // 29.0s

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/** Keyframes that fade+scale a scene in, hold, then fade out. Each scene owns a
 *  slice of one shared 29s timeline, so seeking `--t` drives the whole clip. */
function sceneKeyframes() {
  let at = 0;
  return SCENES.map((s, i) => {
    const start = at;
    at += s.duration;
    const end = at;
    const fade = 0.6;
    const pct = (t) => ((t / DURATION) * 100).toFixed(4);
    // Hard 0 outside the window, cross-faded at the seams.
    return `@keyframes scene-${s.id} {
  0%, ${pct(Math.max(0, start - 0.001))}% { opacity: 0; transform: scale(1.04); }
  ${pct(start + fade)}% { opacity: 1; transform: scale(1); }
  ${pct(Math.max(start + fade, end - fade))}% { opacity: 1; transform: scale(1); }
  ${pct(end)}%, 100% { opacity: 0; transform: scale(0.99); }
}
.scene-${s.id} { animation: scene-${s.id} ${DURATION}s linear infinite; }`;
  }).join('\n');
}

export function previewHtml(item) {
  const wallpaper = asset('Wallpapers', item.bg_wallpaper);
  const capture = asset('web', 'assets', 'screenshots', item.main_capture);

  return `<!doctype html>
<html><head><meta charset="utf-8"><style>
${theme}
.stage { position: relative; width: 100%; height: 100%; overflow: hidden; background: #05070a; }

.scene {
  position: absolute; inset: 0;
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  opacity: 0; will-change: opacity, transform;
}

${sceneKeyframes()}

/* Slow continuous drift on the wallpaper across the whole clip. */
@keyframes drift { from { transform: scale(1.06) translate3d(-1.2%, -0.6%, 0); }
                   to   { transform: scale(1.14) translate3d(1.2%, 0.6%, 0); } }
.wallpaper { animation: drift ${DURATION}s linear infinite alternate; }

.hero-title {
  font-size: 92px; font-weight: 800; letter-spacing: -0.03em;
  margin: 26px 0 0; text-align: center;
  text-shadow: 0 8px 60px rgba(0,0,0,0.75);
}
.hero-sub {
  font-size: 34px; font-weight: 500; color: rgba(203,213,225,0.95);
  margin: 22px 0 0; text-align: center; max-width: 68%;
  text-shadow: 0 4px 26px rgba(0,0,0,0.7);
}

.chrome-bar {
  position: absolute; top: 34px; left: 200px; right: 200px;
  display: flex; align-items: center; justify-content: space-between;
  padding: 18px 36px; border-radius: 20px;
  background: rgba(12,18,30,0.88);
  border: 2px solid color-mix(in srgb, var(--accent) 48%, transparent);
  backdrop-filter: blur(20px);
  font-size: 26px; font-weight: 600;
}
.chrome-callout { color: var(--accent); font-size: 24px; font-weight: 500; }

.showcase-shot { width: 68%; aspect-ratio: 1760 / 1120; margin-top: 40px; }

.feature-title {
  font-size: 66px; font-weight: 800; letter-spacing: -0.02em;
  text-align: center; margin: 0; color: var(--accent);
  text-shadow: 0 6px 44px color-mix(in srgb, var(--accent) 32%, transparent);
}
.feature-desc {
  font-size: 30px; line-height: 1.5; color: rgba(226,232,240,0.94);
  text-align: center; max-width: 62%; margin: 28px 0 0;
}
.feature-pills { display: flex; gap: 22px; margin-top: 46px; }
.feature-pills .pill { font-size: 24px; padding: 14px 30px; }

.close-mark {
  font-size: 120px; font-weight: 800; letter-spacing: 0.08em;
  color: var(--accent);
  text-shadow: 0 0 90px color-mix(in srgb, var(--accent) 55%, transparent);
}
.close-sub { font-size: 32px; color: rgba(203,213,225,0.9); margin-top: 24px; letter-spacing: 0.3em; }
</style></head>
<body style="--accent: ${esc(item.accent)}">
  <div class="stage">
    <img class="wallpaper" src="${wallpaper}" alt="" data-anim>
    <div class="vignette"></div>

    <div class="scene scene-hero" data-anim>
      <div class="badge">Genie Build 500 for Mac</div>
      <h1 class="hero-title">${esc(item.title)}</h1>
      <p class="hero-sub">${esc(item.subtitle)}</p>
    </div>

    <div class="scene scene-showcase" data-anim>
      <div class="chrome-bar">
        <span>Genie Build 500 &nbsp;&bull;&nbsp; ${esc(item.title)}</span>
        <span class="chrome-callout">${esc(item.callout)}</span>
      </div>
      <div class="showcase-shot capture-frame"><img src="${capture}" alt=""></div>
    </div>

    <div class="scene scene-features" data-anim>
      <h2 class="feature-title">${esc(item.feature_title)}</h2>
      <p class="feature-desc">${esc(item.feature_desc)}</p>
      <div class="feature-pills">
        ${(item.pills ?? []).map((p) => `<span class="pill">${esc(p)}</span>`).join('\n        ')}
      </div>
    </div>

    <div class="scene scene-close" data-anim>
      <div class="close-mark">GENIE</div>
      <div class="close-sub">SOVEREIGN. LOCAL. YOURS.</div>
    </div>
  </div>
</body></html>`;
}
