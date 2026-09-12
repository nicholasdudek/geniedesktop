#!/usr/bin/env node
// Render the 10 flagship marketing postcards from HTML/CSS at any resolution.
//
//   node render-postcards.mjs                 # retina (2880x1800), the App Store deliverable
//   node render-postcards.mjs --res 4k        # 3840x2400
//   node render-postcards.mjs --res 8k        # 7680x4800
//   node render-postcards.mjs --res 5120      # any explicit width
//   node render-postcards.mjs --only 01 --debug-html

import { readFile, mkdir, copyFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Renderer, parseArgs, writeDebugHtml, ROOT, REPO, GOLDGATE } from './lib/renderer.mjs';
import { postcardHtml, DESIGN } from './templates/postcard.mjs';

const args = parseArgs();
const res = args.res ?? 'retina';
const items = JSON.parse(await readFile(resolve(ROOT, 'data/postcards.json'), 'utf8'));
const selected = args.only ? items.filter((i) => i.id === String(args.only)) : items;

if (!selected.length) {
  console.error(`No postcard matches --only ${args.only}`);
  process.exit(1);
}

const renderer = Renderer.forDesign(DESIGN.width, DESIGN.height, res);

const SUITE = resolve(REPO, 'Marketing/Genie_AppStore_Suite');
const BUILD14 = resolve(REPO, 'Marketing/AppStore_Connect_Assets/App_Store_Connect_Uploads_Build14/1_Retina_Screenshots_2880x1800');
const SHOWCASE = resolve(REPO, 'Marketing/Postcards_Showcase_Suite');
const WEB = resolve(GOLDGATE, 'web/assets/postcards');

// Only the canonical 2880x1800 render is an App Store deliverable; higher
// resolutions are marketing/web masters and go to the showcase suite alone.
const isAppStoreSize = renderer.outputWidth === 2880 && renderer.outputHeight === 1800;

console.log(`Rendering ${selected.length} postcard(s) at ${renderer.label} (scale ${renderer.scale.toFixed(3)})`);
if (!isAppStoreSize) console.log('  (non-App-Store size — writing masters to Postcards_Showcase_Suite only)');

const ROOT_POSTCARDS = resolve(GOLDGATE, 'assets/postcards');
await Promise.all([SUITE, BUILD14, SHOWCASE, WEB, ROOT_POSTCARDS].map((d) => mkdir(d, { recursive: true })));

const started = Date.now();
try {
  for (const [n, item] of selected.entries()) {
    const t0 = Date.now();
    const html = postcardHtml(item);

    if (args['debug-html']) {
      await writeDebugHtml(html, resolve(ROOT, `.debug/${item.slug}.html`));
    }

    const master = resolve(SHOWCASE, `${item.slug}_${renderer.label}.png`);
    await renderer.still(html, master);

    if (isAppStoreSize) {
      await copyFile(master, resolve(SUITE, item.appstore_name));
      await copyFile(master, resolve(BUILD14, item.appstore_name));
      await copyFile(master, resolve(WEB, `${item.slug}.png`));
      await copyFile(master, resolve(GOLDGATE, `assets/postcards/${item.slug}.png`));

      // Synchronize with legacy App Store screenshot slots for web carousel & grid
      const legacyNames = [
        "01_Spatial_Canvas_Launch.png",
        "02_App_Matrix_Navigation.png",
        "03_Studio_Hub_Living_Themes.png",
        "04_Wallpaper_Camouflage_Mode.png",
        "05_Geometric_Formations_Lotus.png",
        "06_Fibonacci_Galaxy_Spiral.png",
        "07_Motion_Physics_And_Gestures.png",
        "08_Spatial_Sound_Engine.png",
        "09_Dynamic_Battery_Status_Bar.png",
        "10_VIP_Expansion_Store.png"
      ];
      if (n < legacyNames.length) {
        await copyFile(master, resolve(GOLDGATE, `assets/images/appstore_screenshots/${legacyNames[n]}`));
        await copyFile(master, resolve(GOLDGATE, `web/assets/images/appstore_screenshots/${legacyNames[n]}`));
      }
    }

    console.log(`  [${n + 1}/${selected.length}] ${item.title} — ${((Date.now() - t0) / 1000).toFixed(1)}s`);
  }
} finally {
  await renderer.close();
}

console.log(`Done in ${((Date.now() - started) / 1000).toFixed(1)}s -> ${SHOWCASE}`);
