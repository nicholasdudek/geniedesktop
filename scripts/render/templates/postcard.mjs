import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { ROOT, asset } from '../lib/renderer.mjs';

const theme = await readFile(resolve(ROOT, 'lib/theme.css'), 'utf8');

/** Logical design box. `retina` (x2) lands on 2880x1800 — the exact App Store
 *  Connect deliverable the PIL script produced, so this is a drop-in. */
export const DESIGN = { width: 1440, height: 900 };

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export function postcardHtml(item) {
  const wallpaper = asset('Wallpapers', item.wallpaper);
  const capture = item.capture ? asset('web', 'assets', 'screenshots', item.capture) : null;
  const showCapture = capture && !item.is_fullscreen;

  return `<!doctype html>
<html><head><meta charset="utf-8"><style>
${theme}
.card { position: relative; width: 100%; height: 100%; overflow: hidden; }

.frame-line {
  position: absolute; inset: 26px;
  border: 1px solid rgba(255,255,255,0.14);
  border-radius: 18px;
  pointer-events: none;
}

.content {
  position: absolute; inset: 0;
  padding: 54px 70px 58px;
  display: flex; flex-direction: column;
}

.top { display: flex; align-items: center; justify-content: space-between; }

.headline { margin-top: 34px; max-width: ${showCapture ? '58%' : '82%'}; }

.title {
  font-size: 54px; font-weight: 700; line-height: 1.04;
  letter-spacing: -0.022em; margin: 22px 0 0;
  text-shadow: 0 4px 30px rgba(0,0,0,0.6);
}

.subtitle {
  font-size: 26px; font-weight: 500; line-height: 1.42;
  color: rgba(215,225,240,0.92); margin: 20px 0 0;
  text-shadow: 0 2px 18px rgba(0,0,0,0.55);
}

.pills { margin-top: auto; display: flex; flex-wrap: wrap; gap: 16px; }

.shot {
  position: absolute; right: 70px; top: 50%;
  transform: translateY(-50%);
  width: 46%; aspect-ratio: 1760 / 1120;
}

.watermark {
  font-size: 22px; font-weight: 700; letter-spacing: 0.24em;
  color: var(--accent); text-transform: uppercase;
  text-shadow: 0 0 26px color-mix(in srgb, var(--accent) 45%, transparent);
}
</style></head>
<body style="--accent: ${esc(item.accent)}">
  <div class="card">
    <img class="wallpaper" src="${wallpaper}" alt="">
    <div class="vignette"></div>
    <div class="frame-line"></div>
    ${showCapture ? `<div class="shot capture-frame"><img src="${capture}" alt=""></div>` : ''}
    <div class="content">
      <div class="top">
        <div class="stamp">Genie Build 500 &nbsp;&bull;&nbsp; Sovereign macOS Desktop</div>
        <div class="watermark">Genie</div>
      </div>
      <div class="headline">
        <div class="badge">${esc(item.badge)}</div>
        <h1 class="title">${esc(item.title)}</h1>
        <p class="subtitle">${esc(item.subtitle)}</p>
      </div>
      <div class="pills">
        ${(item.pills ?? []).map((p) => `<span class="pill">${esc(p)}</span>`).join('\n        ')}
      </div>
    </div>
  </div>
</body></html>`;
}
