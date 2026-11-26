// The video: a segment per step (its animation frames, then its picture held while the narration
// plays), joined with the narration into out/video.mp4, plus captions, chapters and transcript.
import { mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { FPS, pool, run, runAsync, SAMPLE_RATE, timeline } from "./lib.mjs";

const PUBLISH_LIMIT_MB = 20; // largest file the artifact server takes

export async function assemble(project) {
  const read = (path) => JSON.parse(readFileSync(join(project.out, path), "utf8"));
  const { steps, total } = timeline(project, read("audio/durations.json"), read("frames/counts.json"));
  const segDir = join(project.out, "segments");
  rmSync(segDir, { recursive: true, force: true });
  mkdirSync(segDir, { recursive: true });

  await pool(
    steps.map((step) => async () => {
      const name = `${step.scene.id}-${step.k}`;
      const frames = join(project.out, "frames", step.scene.id, String(step.k), "%04d.png");
      await runAsync("ffmpeg", [
        "-y", "-v", "error", "-framerate", String(FPS), "-i", frames,
        "-vf", `tpad=stop_mode=clone:stop_duration=${step.length + 1},format=yuv420p`,
        "-frames:v", String(step.frames), "-r", String(FPS),
        "-c:v", "libx264", "-preset", "medium", "-tune", "stillimage", "-crf", "24", "-an",
        join(segDir, `${name}.mp4`),
      ]);
      await runAsync("ffmpeg", [
        "-y", "-v", "error", "-i", join(project.out, "audio", `${name}.wav`),
        "-af", `adelay=${Math.round(step.lead * 1000)}:all=1,apad,atrim=end_sample=${Math.round(step.length * SAMPLE_RATE)}`,
        "-ar", String(SAMPLE_RATE), "-ac", "1", "-c:a", "pcm_s16le",
        join(segDir, `${name}.wav`),
      ]);
    }),
    4,
  );

  const list = (ext) => {
    const file = join(segDir, `list-${ext}.txt`);
    writeFileSync(file, steps.map((s) => `file '${s.scene.id}-${s.k}.${ext}'`).join("\n"));
    return file;
  };
  const silentVideo = join(segDir, "video.mp4");
  const narration = join(segDir, "narration.wav");
  run("ffmpeg", ["-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", list("mp4"), "-c", "copy", silentVideo]);
  run("ffmpeg", ["-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", list("wav"), "-c", "copy", narration]);

  const cues = captionCues(steps);
  writeFileSync(join(project.out, "captions.vtt"), vtt(cues));
  writeFileSync(join(project.out, "captions.srt"), srt(cues));

  const output = join(project.out, "video.mp4");
  run("ffmpeg", [
    "-y", "-v", "error", "-i", silentVideo, "-i", narration, "-i", join(project.out, "captions.srt"),
    "-map", "0:v", "-map", "1:a", "-map", "2:s",
    "-c:v", "copy", "-c:a", "aac", "-b:a", "128k", "-c:s", "mov_text",
    "-metadata", `title=${project.title ?? ""}`, "-metadata:s:s:0", "language=eng",
    "-movflags", "+faststart", output,
  ]);

  const chapters = [];
  for (const step of steps) {
    if (step.k === 0) chapters.push({ title: step.scene.title ?? step.scene.id, start: round(step.start) });
  }
  const transcript = steps.map((s) => ({
    scene: s.scene.id,
    start: round(s.start + s.lead),
    end: round(s.start + s.lead + s.audio),
    text: s.text,
  }));
  writeFileSync(join(project.out, "chapters.json"), JSON.stringify(chapters, null, 2));
  writeFileSync(join(project.out, "transcript.json"), JSON.stringify(transcript, null, 2));

  const mb = statSync(output).size / 2 ** 20;
  console.log(`Video: ${output}\n  ${clock(total)} · ${steps.length} steps · ${chapters.length} chapters · ${mb.toFixed(1)} MB`);
  if (mb > PUBLISH_LIMIT_MB) {
    console.warn(`WARN over ${PUBLISH_LIMIT_MB} MB, too big to publish: raise -crf or shorten the video`);
  }
  return { output, total, chapters, transcript };
}

/** A cue per sentence, its share of the step's narration time in proportion to its length. */
function captionCues(steps) {
  const cues = [];
  for (const step of steps) {
    const sentences = step.text.match(/[^.!?]+[.!?]+["”’)]*\s*|[^.!?]+$/g)?.map((s) => s.trim()).filter(Boolean) ?? [step.text];
    const chars = sentences.reduce((n, s) => n + s.length, 0);
    let t = step.start + step.lead;
    for (const sentence of sentences) {
      const length = (step.audio * sentence.length) / chars;
      cues.push({ start: t, end: t + length, text: sentence });
      t += length;
    }
  }
  return cues;
}

const round = (seconds) => Math.round(seconds * 100) / 100;

function clock(seconds, separator = ".") {
  const ms = Math.round(seconds * 1000);
  const h = String(Math.floor(ms / 3600000)).padStart(2, "0");
  const m = String(Math.floor((ms % 3600000) / 60000)).padStart(2, "0");
  const s = String(Math.floor((ms % 60000) / 1000)).padStart(2, "0");
  return `${h}:${m}:${s}${separator}${String(ms % 1000).padStart(3, "0")}`;
}

function vtt(cues) {
  return `WEBVTT\n\n${cues.map((c) => `${clock(c.start)} --> ${clock(c.end)}\n${c.text}`).join("\n\n")}\n`;
}

function srt(cues) {
  return `${cues.map((c, i) => `${i + 1}\n${clock(c.start, ",")} --> ${clock(c.end, ",")}\n${c.text}`).join("\n\n")}\n`;
}
