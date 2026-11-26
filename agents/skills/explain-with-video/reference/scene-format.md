# Scene format

A video is `<project>/script.json` plus one `<project>/scenes/<id>.html` per scene. `scripts/render.mjs` wraps each scene in a page with `assets/stage.css` and `assets/stage.js` and records it in Chromium at 1920×1080, 30 fps.

## script.json

```json
{
  "title": "How explain-with-video works",
  "description": "One sentence for the video page.",
  "meta": "repo · branch @ commit · outputs run on that commit",
  "lexicon": { "JSON": "jason", "PR": "P R" },
  "scenes": [
    { "id": "format", "title": "The rules file", "steps": ["Step 0 narration.", "Step 1 narration."] }
  ]
}
```

- `scenes[].title` is the chapter title on the video page; `steps[k]` is what the voice says while step k is on screen.
- `lexicon` maps a written form to how it is spoken, whole words only, longest first. Captions keep the written form.
- Timing, in seconds, all optional: `lead` (0.25, picture before a step's narration), `sceneLead` (0.6, the same for a scene's first step), `pad` (0.45, silence after a step), `scenePad` (0.9, after a scene's last step).
- `head`: HTML for the scene page's `<head>`, in place of the default Google Fonts link (IBM Plex Sans, JetBrains Mono). `<project>/theme.css`, if present, loads after `stage.css`: override the tokens on `:root` there.

## Steps: what appears and what lights up

A scene has as many steps as its narration. Before step 0 the scene is blank; at step 0 it fades in.

| attribute | effect |
| --- | --- |
| `data-step="N"` | hidden before step N; slides in at N and is emphasised at N |
| `data-focus="N M"` | emphasised at those steps (visible from step 0, or from its `data-step`) |
| `data-emph="none"` | revealed by its `data-step` but never emphasised or dimmed: use it on containers |
| none | always visible: titles, labels, the frame of a diagram |

While anything is emphasised, items shown earlier dim, so the eye goes to what the voice is talking about. A container of the emphasised item never dims, so highlight a line inside a code panel by giving the panel `data-step="1" data-emph="none"` and each line its `data-focus`. Every step from 1 on must reveal or emphasise something; the build warns otherwise.

Emphasis by element: a `.card`, `.node`, `.code`, `.term` or `.shot` gets an accent ring and grows slightly; a code line (`.ln`) gets a highlight bar; a `.points li` or table row turns accent; `<span class="hl">` gets a marker sweep that stays once drawn.

## Layout

`<section class="scene">` is the 1920×1080 canvas with 112px top and bottom and 128px side margins: a flex column, gap 40px. Variants: `alt` (second background), `dark`, `accent` (statement), `center` (centred vertically). Keep everything inside the margins; the build warns when an element runs off the frame or out of its box.

| class | for |
| --- | --- |
| `.eyebrow`, `h1` 112px, `h2` 64px, `h3` 40px, `.lead` 40px, body 32px, `.small` 24px | type; nothing under 24px |
| `.row`, `.col`, `.grow`, `.grid-2/3/4` | flex rows and columns, equal grids |
| `.card` (`.label`, `p`), `.card.warn`, `.card.blue`, `.pill` | boxes |
| `.points` + `li` | bullet list, one `li` per step |
| `.code` / `.term` + `.title` + one `<span class="ln">` per line | code and terminal output; `.c` `.k` `.s` colour comments, keywords, strings; `.ok` `.err` `.prompt` in terminals |
| `table.data` | tables; `tr data-step` reveals a row |
| `.stat` | a 200px number |
| `.diagram` + `.node` (absolute `left/top/width/height`) + `<svg class="wires">` | diagrams |
| `img.shot` | a screenshot, path relative to `<project>` (`shots/home.png`) |
| `.footer` | one line pinned to the bottom margin |

**Code panels:** at 24px a panel holds about 18 lines and, in a two-column row, about 52 characters a line: shorten lines rather than shrink the font. Write leading spaces as spaces: `.ln` keeps them. Escape `<` and `&` in code as `&lt;` and `&amp;`.

**Diagram arrows:** a `<path pathLength="1" class="draw" data-step="N" data-emph="none" marker-end="url(#arrow)" d="…">` inside `svg.wires` draws itself at step N. Give the svg `viewBox="0 0 W H"` matching the diagram's box (1664 wide inside the margins), and define the `#arrow` marker in its `<defs>`. `assets/example/scenes/pipeline.html` has three.

## A scene

```html
<section class="scene">
  <p class="eyebrow">Configuration</p>
  <h2>config.json</h2>
  <div class="row">
    <div class="code grow" data-step="0" data-emph="none">
      <span class="title">config.json (shortened)</span>
      <span class="ln" data-focus="1">"server": {</span>
      <span class="ln" data-focus="1">  "port": 8080 },</span>
      <span class="ln" data-focus="2">"cache": { "ttl": 60 },</span>
    </div>
    <div class="col" style="width:520px">
      <div class="card" data-step="1"><span class="label">SERVER</span><p>Where the app listens.</p></div>
      <div class="card" data-step="2"><span class="label">CACHE</span><p>How long answers are kept.</p></div>
    </div>
  </div>
</section>
```

With three narration steps: at 0 the code fades in; at 1 the server card slides in and the server lines light up; at 2 the cache card slides in, the cache line lights up and the server card and lines dim.
