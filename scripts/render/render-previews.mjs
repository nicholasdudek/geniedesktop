#!/usr/bin/env node
// Render the 3 opening App Previews as real animation (not a slideshow).
//
//   node render-previews.mjs                    # 1080p, App Store Connect deliverable
//   node render-previews.mjs --res 4k           # 3840x2160 master
//   node render-previews.mjs --res 8k --fps 24  # 7680x4320 master
//   node render-previews.mjs --only 1 --duration 4   # quick look
//
// Crossfades are baked into the frames by the shared CSS timeline, so the
// encoder does a straight frame-sequence pass — no xfade filter needed.
// Audio is genuine silence unless --audio <file> is given.

import { readFile, mkdir, rm, copyFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import { Renderer, parseArgs, ROOT, REPO, GOLDGATE } from './lib/renderer.mjs';
import { previewHtml, DESIGN, DURATION } from './templates/preview.mjs';

const args = parseArgs();
const res = args.res ?? 'hd';
const fps = Number(args.fps ?? 30);
const duration = Number(args.duration ?? DURATION);

const items = JSON.parse(await readFile(resolve(ROOT, 'data/previews.json'), 'utf8'));
const selected = args.only ? items.filter((i) => i.id === String(args.only)) : items;
if (!selected.length) { console.error(`No preview matches --only ${args.only}`); process.exit(1); }

const renderer = Renderer.forDesign(DESIGN.width, DESIGN.height, res);

const OUT_APPSTORE = resolve(REPO, 'Marketing/AppStore_Connect_Assets/App_Store_Connect_Uploads_Build14/2_App_Preview_Videos_1080p');
const OUT_MKT = resolve(REPO, 'Marketing/Opening_App_Previews');
const OUT_WEB = resolve(GOLDGATE, 'web/assets/previews');

// App Store Connect takes 1080p; anything larger is a marketing/web master.
const isAppStoreSize = renderer.outputWidth === 1920 && renderer.outputHeight === 1080;
// H.264 is safe to 4K; above that use HEVC via VideoToolbox for a playable master.
const useHevc = renderer.outputWidth > 3840;

function run(cmd, argv) {
  return new Promise((ok, fail) => {
    const p = spawn(cmd, argv, { stdio: ['ignore', 'ignore', 'pipe'] });
    let err = '';
    p.stderr.on('data', (d) => { err += d; });        // drain, or ffmpeg blocks
    p.on('close', (code) => (code === 0 ? ok() : fail(new Error(`${cmd} exited ${code}\n${err.slice(-1200)}`))));
  });
}

/** Homebrew's webp tools are optional; without them we still ship the GIF. */
const hasGif2Webp = await new Promise((ok) => {
  const p = spawn('gif2webp', ['-version'], { stdio: 'ignore' });
  p.on('error', () => ok(false));
  p.on('close', (code) => ok(code === 0));
});

await Promise.all([OUT_APPSTORE, OUT_MKT, OUT_WEB].map((d) => mkdir(d, { recursive: true })));

console.log(`Rendering ${selected.length} preview(s) at ${renderer.label} @ ${fps}fps, ${duration}s`);
console.log(`  codec: ${useHevc ? 'hevc_videotoolbox' : 'libx264'}${isAppStoreSize ? ' (App Store deliverable)' : ' (master)'}`);

const started = Date.now();
try {
  for (const item of selected) {
    const t0 = Date.now();
    const frameDir = resolve(tmpdir(), `genie_preview_${item.id}_${renderer.label}`);
    await rm(frameDir, { recursive: true, force: true });

    process.stdout.write(`  ${item.name} — frames `);
    const total = await renderer.frames(previewHtml(item), {
      fps, duration, dir: frameDir,
      onFrame: (i, n) => {
        if (i % Math.ceil(n / 20) === 0 || i === n) process.stdout.write('.');
      },
    });

    const master = resolve(OUT_MKT, `${item.name}_${renderer.label}.mp4`);
    const video = useHevc
      ? ['-c:v', 'hevc_videotoolbox', '-b:v', '60M', '-tag:v', 'hvc1']
      : ['-c:v', 'libx264', '-profile:v', 'high', '-preset', 'slow', '-crf', '17'];

    const audio = args.audio
      ? ['-i', String(args.audio)]
      : ['-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=48000'];

    await run('ffmpeg', [
      '-y',
      '-framerate', String(fps), '-i', `${frameDir}/frame_%05d.png`,
      ...audio,
      ...video,
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac', '-b:a', '192k',
      '-shortest', '-movflags', '+faststart',
      master,
    ]);

    const rootVideo = resolve(GOLDGATE, 'assets/video');
    const rootPreviews = resolve(GOLDGATE, 'assets/previews');
    await Promise.all([rootVideo, rootPreviews].map((d) => mkdir(d, { recursive: true })));

    if (isAppStoreSize) {
      await copyFile(master, resolve(OUT_APPSTORE, `${item.name}.mp4`));
      await copyFile(master, resolve(OUT_WEB, `${item.name}.mp4`));
      await copyFile(master, resolve(rootVideo, `${item.name}.mp4`));
      await copyFile(master, resolve(rootPreviews, `${item.name}.mp4`));
    }

    // Looping preview for the web page and GitHub readme. ffmpeg here has no
    // libwebp encoder, so go via a two-pass palette GIF (which is the right way
    // to make a GIF regardless) and convert with gif2webp when it is installed.
    const gif = resolve(OUT_WEB, `${item.name}.gif`);
    const filters = 'fps=15,scale=960:-2:flags=lanczos';
    const palette = resolve(tmpdir(), `genie_palette_${item.id}.png`);

    await run('ffmpeg', ['-y', '-t', '10', '-i', master,
      '-vf', `${filters},palettegen=stats_mode=diff`, '-update', '1', palette]);
    await run('ffmpeg', ['-y', '-t', '10', '-i', master, '-i', palette,
      '-lavfi', `${filters}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5`,
      '-loop', '0', gif]);
    await rm(palette, { force: true });
    await copyFile(gif, resolve(rootPreviews, `${item.name}.gif`));

    if (hasGif2Webp) {
      const webp = resolve(OUT_WEB, `${item.name}.webp`);
      await run('gif2webp', ['-q', '78', '-m', '4', '-mt', gif, '-o', webp]);
      await copyFile(webp, resolve(rootPreviews, `${item.name}.webp`));
    }

    // Poster from the showcase scene (~40% in). -update 1 is required for a
    // single still, otherwise the image2 muxer wants a %0Nd sequence pattern.
    const poster = resolve(OUT_WEB, `${item.name}_poster.png`);
    await run('ffmpeg', [
      '-y', '-ss', String(duration * 0.4), '-i', master,
      '-frames:v', '1', '-update', '1',
      poster,
    ]);
    await copyFile(poster, resolve(rootPreviews, `${item.name}_poster.png`));

    await rm(frameDir, { recursive: true, force: true });
    console.log(` ${total} frames, ${((Date.now() - t0) / 1000).toFixed(1)}s`);
  }
} finally {
  await renderer.close();
}

console.log(`Done in ${((Date.now() - started) / 1000).toFixed(1)}s -> ${OUT_MKT}`);
