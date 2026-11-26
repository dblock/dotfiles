// The video page: out/page/index.html (captions, chapters and transcript inside it) with
// video.mp4 beside it, ready to publish.
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { SKILL_DIR } from "./lib.mjs";

const escapeHtml = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

export function page(project) {
  const read = (name) => JSON.parse(readFileSync(join(project.out, name), "utf8"));
  const chapters = read("chapters.json");
  const transcript = read("transcript.json");
  const dir = join(project.out, "page");
  mkdirSync(dir, { recursive: true });

  const title = project.title ?? "Video explainer";
  const captions = readFileSync(join(project.out, "captions.vtt"), "utf8");
  const data = JSON.stringify({ chapters, transcript, captions }).replace(/</g, "\\u003c");
  const html = readFileSync(join(SKILL_DIR, "assets", "page.html"), "utf8")
    .replaceAll("__TITLE__", escapeHtml(title))
    .replace("__DESCRIPTION__", escapeHtml(project.description ?? ""))
    .replace("__META__", escapeHtml(project.meta ?? ""))
    .replace("/*__DATA__*/null", data);
  writeFileSync(join(dir, "index.html"), html);
  copyFileSync(join(project.out, "video.mp4"), join(dir, "video.mp4"));
  console.log(`Page: ${dir} (index.html, video.mp4)`);
}
