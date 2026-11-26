// Shared helpers for the explain-with-video scripts: the project file, processes, timing.
import { spawn, spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const SKILL_DIR = resolve(dirname(fileURLToPath(import.meta.url)), "..");
export const FPS = 30;
export const SAMPLE_RATE = 48000;

const DEFAULTS = {
  voice: {}, // no provider: tts.mjs picks ElevenLabs when a key is configured, else macOS speech
  lexicon: {},
  lead: 0.25, // seconds of picture before a step's narration starts
  sceneLead: 0.6, // the same for a scene's first step, so its reveal plays first
  pad: 0.45, // silence after a step's narration
  scenePad: 0.9, // the same after a scene's last step
};

/** Reads and checks <dir>/script.json. VIDEO_TTS_PROVIDER and VIDEO_TTS_VOICE override its voice. */
export function loadProject(dir) {
  const root = resolve(dir);
  const file = join(root, "script.json");
  if (!existsSync(file)) throw new Error(`No script.json in ${root}`);
  const script = JSON.parse(readFileSync(file, "utf8"));
  const project = {
    ...DEFAULTS,
    ...script,
    voice: { ...DEFAULTS.voice, ...script.voice },
    root,
    out: join(root, "out"),
  };
  if (process.env.VIDEO_TTS_PROVIDER) project.voice.provider = process.env.VIDEO_TTS_PROVIDER;
  if (process.env.VIDEO_TTS_VOICE) project.voice.name = process.env.VIDEO_TTS_VOICE;

  if (!Array.isArray(project.scenes) || project.scenes.length === 0) {
    throw new Error("script.json: scenes is empty");
  }
  const seen = new Set();
  for (const scene of project.scenes) {
    if (!/^[A-Za-z0-9_-]{1,64}$/.test(scene.id ?? "")) throw new Error(`Bad scene id: ${scene.id}`);
    if (seen.has(scene.id)) throw new Error(`Duplicate scene id: ${scene.id}`);
    seen.add(scene.id);
    if (!Array.isArray(scene.steps) || scene.steps.length === 0) {
      throw new Error(`Scene ${scene.id}: steps is empty`);
    }
    if (scene.steps.some((step) => typeof step !== "string" || !step.trim())) {
      throw new Error(`Scene ${scene.id}: every step is a non-empty narration string`);
    }
    if (!existsSync(sceneFile(project, scene))) throw new Error(`Missing ${sceneFile(project, scene)}`);
  }
  return project;
}

export const sceneFile = (project, scene) => join(project.root, "scenes", `${scene.id}.html`);

export function run(cmd, args, opts = {}) {
  const result = spawnSync(cmd, args, { encoding: "utf8", maxBuffer: 1 << 26, ...opts });
  if (result.status !== 0) {
    throw new Error(`${cmd} ${args.join(" ")}\n${result.stderr || result.error || ""}`);
  }
  return result.stdout;
}

export function runAsync(cmd, args) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(cmd, args, { stdio: ["ignore", "ignore", "pipe"] });
    let stderr = "";
    child.stderr.on("data", (chunk) => (stderr += chunk));
    child.on("error", reject);
    child.on("close", (code) =>
      code === 0 ? resolvePromise() : reject(new Error(`${cmd} ${args.join(" ")}\n${stderr}`)),
    );
  });
}

/** Runs async jobs with at most `limit` at a time. */
export async function pool(jobs, limit = 4) {
  const queue = [...jobs];
  const workers = Array.from({ length: limit }, async () => {
    while (queue.length) await queue.shift()();
  });
  await Promise.all(workers);
}

export function duration(file) {
  const out = run("ffprobe", [
    "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", file,
  ]);
  return Number(out.trim());
}

/** Whole frames needed to cover `seconds`. */
export const toFrames = (seconds) => Math.ceil(seconds * FPS - 1e-6);

/**
 * Where every step sits in the video. A step's segment is its animation, then its picture
 * held while the narration plays (after `lead`) and for `pad` after it.
 * @param durations {[sceneId]: number[]} narration seconds per step
 * @param frameCounts {[sceneId]: number[]} animation frames per step
 */
export function timeline(project, durations, frameCounts) {
  const steps = [];
  let t = 0;
  for (const scene of project.scenes) {
    scene.steps.forEach((text, k) => {
      const audio = durations[scene.id]?.[k];
      const animFrames = frameCounts[scene.id]?.[k];
      if (audio === undefined) throw new Error(`No narration for ${scene.id} step ${k}: run tts`);
      if (animFrames === undefined) throw new Error(`No frames for ${scene.id} step ${k}: run render`);
      const lead = k === 0 ? project.sceneLead : project.lead;
      const pad = k === scene.steps.length - 1 ? project.scenePad : project.pad;
      const frames = Math.max(toFrames(lead + audio + pad), animFrames + Math.round(FPS * 0.2));
      const length = frames / FPS;
      steps.push({ scene, k, text, start: t, length, frames, animFrames, lead, audio });
      t += length;
    });
  }
  return { steps, total: t };
}

/** Launches Chromium through playwright-core installed in the current directory. */
export async function launchChromium() {
  const require = createRequire(join(process.cwd(), "noop.js"));
  let playwright;
  try {
    playwright = require("playwright-core");
  } catch {
    throw new Error(`playwright-core not found: run \`npm i playwright-core\` in ${process.cwd()}`);
  }
  const executablePath = process.env.CHROME || cachedChromium();
  return playwright.chromium.launch(executablePath ? { executablePath } : {});
}

function cachedChromium() {
  const caches = [join(homedir(), "Library/Caches/ms-playwright"), join(homedir(), ".cache/ms-playwright")];
  const inside = [
    "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
    "chrome-mac/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
    "chrome-mac/Chromium.app/Contents/MacOS/Chromium",
    "chrome-linux64/chrome",
    "chrome-linux/chrome",
  ];
  for (const cache of caches.filter(existsSync)) {
    const builds = readdirSync(cache)
      .filter((name) => /^chromium-\d+$/.test(name))
      .sort((a, b) => Number(b.split("-")[1]) - Number(a.split("-")[1]));
    for (const build of builds) {
      for (const path of inside) {
        if (existsSync(join(cache, build, path))) return join(cache, build, path);
      }
    }
  }
  return undefined;
}
