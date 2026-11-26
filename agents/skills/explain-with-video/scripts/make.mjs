// Usage: node make.mjs <project-dir> [all|tts|render|assemble|page] [--scene <id>]
// Run it from a folder where playwright-core is installed (render needs it).
// all = tts, render, assemble, page. Narration is cached, so re-running after an edit is cheap;
// --scene re-renders one scene's frames.
import { assemble } from "./assemble.mjs";
import { loadProject } from "./lib.mjs";
import { page } from "./page.mjs";
import { render } from "./render.mjs";
import { tts } from "./tts.mjs";

const args = process.argv.slice(2);
const sceneFlag = args.indexOf("--scene");
const scene = sceneFlag >= 0 ? args.splice(sceneFlag, 2)[1] : undefined;
const [dir, stage = "all"] = args;
if (!dir) {
  console.error("Usage: node make.mjs <project-dir> [all|tts|render|assemble|page] [--scene <id>]");
  process.exit(1);
}

const project = loadProject(dir);
const stages = { tts, render, assemble, page };
try {
  if (stage === "all") {
    await tts(project);
    await render(project, { scene });
    await assemble(project);
    page(project);
  } else if (stages[stage]) {
    await stages[stage](project, { scene });
  } else {
    throw new Error(`Unknown stage: ${stage}`);
  }
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
