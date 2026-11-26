// Narration: one WAV per step (48 kHz mono, loudness-normalised) and out/audio/durations.json.
// Providers: elevenlabs (default when a key is configured), say (macOS, the fallback), openai;
// their keys come from apiKey().
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { duration, pool, run, runAsync, SAMPLE_RATE } from "./lib.mjs";

// Best first. Premium and Enhanced voices are free downloads in System Settings ›
// Accessibility › Spoken Content › System voice › Manage Voices.
const SAY_VOICES = [
  "Ava (Premium)", "Zoe (Premium)", "Evan (Premium)", "Jamie (Premium)",
  "Ava (Enhanced)", "Zoe (Enhanced)", "Evan (Enhanced)", "Samantha", "Daniel",
];

// A stock voice every ElevenLabs account has, made for explaining things.
const ELEVENLABS_VOICE = "Matilda";

export async function tts(project) {
  const dir = join(project.out, "audio");
  const cache = join(dir, "cache");
  mkdirSync(cache, { recursive: true });
  const provider = project.voice.provider ?? (findKey("elevenlabs") ? "elevenlabs" : "say");
  const voice = await resolveVoice({ ...project.voice, provider });
  console.log(`Voice: ${voice.provider}${voice.label ? ` · ${voice.label}` : ""}`);

  const durations = {};
  const jobs = [];
  for (const scene of project.scenes) {
    durations[scene.id] = [];
    scene.steps.forEach((text, k) => {
      const spoken = speakable(text, project.lexicon);
      const key = createHash("sha1").update(JSON.stringify({ ...voice, spoken })).digest("hex");
      const cached = join(cache, `${key}.wav`);
      const target = join(dir, `${scene.id}-${k}.wav`);
      jobs.push(async () => {
        if (!existsSync(cached)) await synthesize(voice, spoken, cached);
        copyFileSync(cached, target);
        durations[scene.id][k] = duration(target);
      });
    });
  }
  // say runs locally; the APIs get a few requests at once.
  await pool(jobs, voice.provider === "say" ? 4 : 3);
  writeFileSync(join(dir, "durations.json"), JSON.stringify(durations, null, 2));
  const total = Object.values(durations).flat().reduce((a, b) => a + b, 0);
  console.log(`Narration: ${jobs.length} steps, ${total.toFixed(1)} s spoken`);
  return durations;
}

// Keys stay here, out of the voice object, so they never reach a cache key or a log line.
const keys = {};

/**
 * A provider's API key: $<PROVIDER>_API_KEY, else the macOS Keychain item repo-video-<provider>,
 * else ~/.config/repo-video/<provider>.key. Undefined when none is configured.
 */
function findKey(provider) {
  if (keys[provider]) return keys[provider];
  let key = process.env[`${provider.toUpperCase()}_API_KEY`]?.trim();
  if (!key && process.platform === "darwin") {
    const found = spawnSync("security", ["find-generic-password", "-s", `repo-video-${provider}`, "-w"], {
      encoding: "utf8",
    });
    if (found.status === 0) key = found.stdout.trim();
  }
  const file = keyFile(provider);
  if (!key && existsSync(file)) key = readFileSync(file, "utf8").trim();
  if (key) keys[provider] = key;
  return key || undefined;
}

function keyFile(provider) {
  return join(homedir(), ".config", "repo-video", `${provider}.key`);
}

function apiKey(provider) {
  const key = findKey(provider);
  if (!key) {
    const variable = `${provider.toUpperCase()}_API_KEY`;
    throw new Error(
      `No ${provider} API key: set ${variable}, add the Keychain item repo-video-${provider}, or write ${keyFile(provider)}`,
    );
  }
  return key;
}

async function resolveVoice(voice) {
  switch (voice.provider) {
    case "say": {
      const installed = run("say", ["-v", "?"])
        .split("\n")
        .map((line) => line.match(/^(.+?)\s{2,}[a-z]{2}_[A-Z]{2}/)?.[1]?.trim())
        .filter(Boolean);
      const name = voice.name ?? SAY_VOICES.find((v) => installed.includes(v));
      if (!name || !installed.includes(name)) {
        throw new Error(`macOS voice not installed: ${name}. Installed: ${installed.join(", ")}`);
      }
      return { provider: "say", name, label: name, rate: voice.rate ?? 175 };
    }
    case "openai": {
      apiKey("openai");
      const name = voice.name ?? "alloy";
      return {
        provider: "openai",
        name,
        label: name,
        model: voice.model ?? "gpt-4o-mini-tts",
        instructions: voice.instructions,
      };
    }
    case "elevenlabs": {
      const key = apiKey("elevenlabs");
      const name = voice.name ?? ELEVENLABS_VOICE;
      // A voice id, or a name as the voices list shows it ("Matilda", or the full "Matilda - …").
      const response = await fetch("https://api.elevenlabs.io/v1/voices", { headers: { "xi-api-key": key } });
      if (!response.ok) throw new Error(`ElevenLabs voices list failed: ${response.status}`);
      const { voices } = await response.json();
      const wanted = name.toLowerCase();
      const match =
        voices.find((v) => v.voice_id === name) ??
        voices.find((v) => v.name.toLowerCase() === wanted) ??
        voices.find((v) => v.name.toLowerCase().split(" - ")[0] === wanted);
      if (!match) {
        throw new Error(`No ElevenLabs voice ${name}. Voices: ${voices.map((v) => v.name).join("; ")}`);
      }
      return {
        provider: "elevenlabs",
        name: match.voice_id,
        label: match.name,
        model: voice.model ?? "eleven_multilingual_v2",
      };
    }
    default:
      throw new Error(`Unknown voice.provider: ${voice.provider} (say, openai or elevenlabs)`);
  }
}

/** Applies the lexicon (written form → spoken form), longest entry first, whole words only. */
export function speakable(text, lexicon = {}) {
  let out = text;
  for (const [written, spoken] of Object.entries(lexicon).sort((a, b) => b[0].length - a[0].length)) {
    const escaped = written.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const start = /^\w/.test(written) ? "(?<![\\w-])" : "";
    const end = /\w$/.test(written) ? "(?![\\w-])" : "";
    out = out.replace(new RegExp(`${start}${escaped}${end}`, "g"), spoken);
  }
  return out;
}

async function synthesize(voice, text, target) {
  const raw = `${target}.raw`;
  try {
    switch (voice.provider) {
      case "say": {
        const textFile = `${target}.txt`;
        writeFileSync(textFile, text);
        await runAsync("say", ["-v", voice.name, "-r", String(voice.rate), "-o", `${raw}.aiff`, "-f", textFile]);
        rmSync(textFile);
        await normalise(`${raw}.aiff`, target);
        rmSync(`${raw}.aiff`);
        return;
      }
      case "openai": {
        const body = { model: voice.model, voice: voice.name, input: text, response_format: "wav" };
        if (voice.instructions) body.instructions = voice.instructions;
        await download("https://api.openai.com/v1/audio/speech", {
          headers: { Authorization: `Bearer ${apiKey("openai")}`, "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }, raw);
        break;
      }
      case "elevenlabs":
        await download(
          `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voice.name)}?output_format=mp3_44100_128`,
          {
            headers: { "xi-api-key": apiKey("elevenlabs"), "Content-Type": "application/json" },
            body: JSON.stringify({ text, model_id: voice.model }),
          },
          raw,
        );
        break;
    }
    await normalise(raw, target);
  } finally {
    rmSync(raw, { force: true });
  }
}

async function download(url, init, target) {
  for (let attempt = 1; ; attempt++) {
    const response = await fetch(url, { method: "POST", ...init });
    if (response.ok) {
      writeFileSync(target, Buffer.from(await response.arrayBuffer()));
      return;
    }
    if (attempt >= 3 || ![429, 500, 502, 503].includes(response.status)) {
      throw new Error(`TTS request failed: ${response.status} ${await response.text()}`);
    }
    await new Promise((r) => setTimeout(r, 2000 * attempt));
  }
}

// Leading silence trimmed, loudness evened out across steps and providers.
function normalise(input, target) {
  return runAsync("ffmpeg", [
    "-y", "-v", "error", "-i", input,
    "-af", "silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-18:TP=-1.5:LRA=11",
    "-ar", String(SAMPLE_RATE), "-ac", "1", "-c:a", "pcm_s16le", target,
  ]);
}
