// Core HTML -> PNG renderer.
//
// Everything is authored once at a logical "design size" (CSS px) and rasterised
// at any output resolution via Chrome's deviceScaleFactor. Text, gradients,
// shadows and blur stay vector-crisp at every scale, so 4K and 8K are the same
// stylesheet as 1080p — only `scale` changes.

import { chromium } from 'playwright';
import { mkdir, writeFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
export const GOLDGATE = resolve(ROOT, '..', '..');
export const REPO = resolve(GOLDGATE, '..');

/** Named target widths. Scale is derived from the design width, so a preset
 *  means the same output width whatever aspect ratio the asset uses. */
export const PRESETS = {
  hd: 1920,
  retina: 2880,
  '4k': 3840,
  '5k': 5120,
  '8k': 7680,
};

/** Absolute file:// URL, verified to exist. A missing asset otherwise renders
 *  as a silent broken-image glyph that survives all the way to an App Store
 *  upload, so this throws instead. */
export function asset(...parts) {
  const path = resolve(GOLDGATE, ...parts);
  if (!existsSync(path)) {
    throw new Error(`Missing asset: ${path}`);
  }
  return pathToFileURL(path).href;
}

export class Renderer {
  #browser = null;

  constructor({ designWidth, designHeight, scale }) {
    this.designWidth = designWidth;
    this.designHeight = designHeight;
    this.scale = scale;
  }

  /** Resolve a `--res` preset or explicit width into a Renderer for this design. */
  static forDesign(designWidth, designHeight, res) {
    const width = PRESETS[res] ?? Number(res);
    if (!Number.isFinite(width) || width <= 0) {
      throw new Error(
        `Unknown --res "${res}". Use a width in px or one of: ${Object.keys(PRESETS).join(', ')}`
      );
    }
    return new Renderer({ designWidth, designHeight, scale: width / designWidth });
  }

  get outputWidth() { return Math.round(this.designWidth * this.scale); }
  get outputHeight() { return Math.round(this.designHeight * this.scale); }
  get label() { return `${this.outputWidth}x${this.outputHeight}`; }

  async open() {
    this.#browser ??= await chromium.launch();
    return this.#browser;
  }

  async close() {
    await this.#browser?.close();
    this.#browser = null;
  }

  async #page() {
    const browser = await this.open();
    return browser.newPage({
      viewport: { width: this.designWidth, height: this.designHeight },
      deviceScaleFactor: this.scale,
    });
  }

  /** setContent() leaves the document on about:blank, from which Chrome blocks
   *  every file:// subresource — wallpapers and screenshots silently 404. So
   *  stage the markup as a real file and navigate to it. */
  async #load(page, html) {
    const staged = resolve(ROOT, '.tmp', `stage_${process.pid}_${Date.now()}.html`);
    await mkdir(dirname(staged), { recursive: true });
    await writeFile(staged, html, 'utf8');

    const missing = [];
    page.on('requestfailed', (r) => missing.push(r.url()));

    await page.goto(pathToFileURL(staged).href, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await rm(staged, { force: true });

    if (missing.length) {
      throw new Error(`Assets failed to load:\n  ${missing.join('\n  ')}`);
    }
  }

  /** Render one still. */
  async still(html, outPath) {
    const page = await this.#page();
    try {
      await this.#load(page, html);
      await mkdir(dirname(outPath), { recursive: true });
      await page.screenshot({ path: outPath });
    } finally {
      await page.close();
    }
    return outPath;
  }

  /** Render a frame sequence by seeking a paused CSS animation clock.
   *
   *  Every `[data-anim]` element runs a paused animation; setting a negative
   *  animation-delay jumps it to an exact offset. That makes each frame a pure
   *  function of `t` — no wall-clock timing, so output is reproducible and the
   *  render can be as slow as it needs to be without dropping frames. */
  async frames(html, { fps, duration, dir, onFrame }) {
    const page = await this.#page();
    const total = Math.round(fps * duration);
    try {
      await this.#load(page, html);
      await mkdir(dir, { recursive: true });

      for (let i = 0; i < total; i++) {
        const t = i / fps;
        await page.evaluate((time) => {
          document.documentElement.style.setProperty('--t', String(time));
          for (const el of document.querySelectorAll('[data-anim]')) {
            el.style.animationDelay = `${-time}s`;
            el.style.animationPlayState = 'paused';
          }
        }, t);
        const path = `${dir}/frame_${String(i).padStart(5, '0')}.png`;
        await page.screenshot({ path });
        onFrame?.(i + 1, total);
      }
    } finally {
      await page.close();
    }
    return total;
  }
}

/** Minimal arg parsing: --key value and --flag. */
export function parseArgs(argv = process.argv.slice(2)) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) continue;
    const key = argv[i].slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out[key] = true;
    else { out[key] = next; i++; }
  }
  return out;
}

export async function writeDebugHtml(html, path) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, html, 'utf8');
}
