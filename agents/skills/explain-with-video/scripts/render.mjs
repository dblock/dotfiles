// Frames: each step's reveal and emphasis animation, captured frame by frame in Chromium.
// Writes out/frames/<scene>/<step>/NNNN.png, out/frames/counts.json and out/preview/<scene>-<step>.png
// (each step's settled picture, for checking by eye).
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { FPS, launchChromium, sceneFile, SKILL_DIR } from "./lib.mjs";

const DEFAULT_HEAD =
  '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap">';
const MAX_ANIMATION_MS = 2000;

export async function render(project, { scene: only } = {}) {
  const framesDir = join(project.out, "frames");
  const countsFile = join(framesDir, "counts.json");
  const counts = existsSync(countsFile) ? JSON.parse(readFileSync(countsFile, "utf8")) : {};
  const scenes = project.scenes.filter((scene) => !only || scene.id === only);
  if (only && scenes.length === 0) throw new Error(`No scene ${only}`);
  mkdirSync(join(project.out, "html"), { recursive: true });
  mkdirSync(join(project.out, "preview"), { recursive: true });

  const browser = await launchChromium();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  const problems = [];
  page.on("pageerror", (error) => problems.push(`page error: ${error.message}`));
  page.on("requestfailed", (request) => {
    if (!request.url().startsWith("https://fonts.")) problems.push(`failed to load ${request.url()}`);
  });

  try {
    for (const scene of scenes) {
      const htmlFile = join(project.out, "html", `${scene.id}.html`);
      writeFileSync(htmlFile, wrap(project, readFileSync(sceneFile(project, scene), "utf8")));
      await page.goto(pathToFileURL(htmlFile).href, { waitUntil: "load" });
      await page.evaluate(() => document.fonts.ready);

      const check = await page.evaluate((n) => window.stage.check(n), scene.steps.length);
      for (const message of check) problems.push(`${scene.id}: ${message}`);

      await page.evaluate(() => window.stage.go(-1, { instant: true }));
      counts[scene.id] = [];
      for (let k = 0; k < scene.steps.length; k++) {
        const dir = join(framesDir, scene.id, String(k));
        rmSync(dir, { recursive: true, force: true });
        mkdirSync(dir, { recursive: true });
        const frames = await page.evaluate(
          ({ k, fps, max }) => window.stage.animate(k, fps, max),
          { k, fps: FPS, max: MAX_ANIMATION_MS },
        );
        for (let f = 0; f < frames; f++) {
          await page.evaluate(({ f, fps }) => window.stage.seek(f, fps), { f, fps: FPS });
          await page.screenshot({ path: join(dir, `${String(f).padStart(4, "0")}.png`) });
        }
        await page.evaluate(() => window.stage.settle());
        counts[scene.id][k] = frames;
        copyFileSync(
          join(dir, `${String(frames - 1).padStart(4, "0")}.png`),
          join(project.out, "preview", `${scene.id}-${k}.png`),
        );
      }
      const overflow = await page.evaluate(() => window.stage.overflow());
      for (const message of overflow) problems.push(`${scene.id}: ${message}`);
      console.log(`Rendered ${scene.id}: ${counts[scene.id].reduce((a, b) => a + b, 0)} frames`);
    }
  } finally {
    await browser.close();
  }
  writeFileSync(countsFile, JSON.stringify(counts, null, 2));
  for (const problem of problems) console.warn(`WARN ${problem}`);
  return counts;
}

// Paths in a scene resolve against the project folder, so <img src="shots/home.png"> works.
function wrap(project, body) {
  const asset = (name) => pathToFileURL(join(SKILL_DIR, "assets", name)).href;
  const theme = join(project.root, "theme.css");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<base href="${pathToFileURL(project.root).href}/">
${project.head ?? DEFAULT_HEAD}
<link rel="stylesheet" href="${asset("stage.css")}">
${existsSync(theme) ? `<link rel="stylesheet" href="${pathToFileURL(theme).href}">` : ""}
</head><body><main class="stage">
${body}
</main><script src="${asset("stage.js")}"></script></body></html>`;
}
