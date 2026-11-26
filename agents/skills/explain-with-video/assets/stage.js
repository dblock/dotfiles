// Reveal and emphasis for explain-with-video scenes; render.mjs drives it through window.stage.
// data-step="N": hidden before step N, shown from N, emphasised at N.
// data-focus="N M": also emphasised at those steps. data-emph="none": shown, never emphasised.
(() => {
  const marked = () => [...document.querySelectorAll("[data-step],[data-focus]")];
  const list = (el, attr) =>
    (el.getAttribute(attr) ?? "").split(/[\s,]+/).filter(Boolean).map(Number);
  const firstStep = (el) => (el.hasAttribute("data-step") ? Number(el.dataset.step) : -Infinity);
  let running = [];

  function apply(k) {
    const els = marked();
    let anyCurrent = false;
    for (const el of els) {
      const step = firstStep(el);
      const shown = k >= 0 && k >= step;
      const current =
        shown && el.dataset.emph !== "none" && (step === k || list(el, "data-focus").includes(k));
      el.classList.toggle("is-hidden", !shown);
      el.classList.toggle("is-current", current);
      el.classList.toggle("is-past", shown && !current);
      anyCurrent ||= current;
    }
    // While something is emphasised, dim what was shown before, once: never a container of the
    // emphasised element, a data-emph="none" container, a marker, or inside a dimmed element.
    for (const el of els) {
      el.classList.toggle(
        "is-dim",
        anyCurrent &&
          el.classList.contains("is-past") &&
          el.dataset.emph !== "none" &&
          !el.classList.contains("hl") &&
          !el.querySelector(".is-current") &&
          !el.parentElement.closest(".is-dim"),
      );
    }
    document.body.classList.toggle("is-pre", k < 0);
  }

  window.stage = {
    /** Problems with the scene's marks, for a scene of n steps. */
    check(n) {
      const problems = [];
      const used = new Set();
      for (const el of marked()) {
        const steps = [...list(el, "data-focus")];
        if (el.hasAttribute("data-step")) steps.push(Number(el.dataset.step));
        for (const s of steps) {
          if (!Number.isInteger(s) || s < 0 || s >= n) {
            problems.push(`step ${s} on <${el.tagName.toLowerCase()}> is outside 0..${n - 1}`);
          }
          used.add(s);
        }
      }
      for (let k = 1; k < n; k++) {
        if (!used.has(k)) problems.push(`step ${k} reveals and emphasises nothing`);
      }
      return problems;
    },

    go(k, { instant = false } = {}) {
      if (instant) document.documentElement.classList.add("no-anim");
      apply(k);
      if (instant) {
        document.body.getBoundingClientRect();
        document.documentElement.classList.remove("no-anim");
      }
    },

    /** Moves to step k with its animations paused at 0; returns the frames to capture. */
    animate(k, fps, maxMs) {
      apply(k);
      running = document.getAnimations();
      let end = 0;
      for (const animation of running) {
        animation.pause();
        animation.currentTime = 0;
        end = Math.max(end, Math.min(maxMs, animation.effect.getComputedTiming().endTime || 0));
      }
      // Frame f shows time f / fps; the last frame is the settled picture.
      return Math.ceil((end / 1000) * fps) + 1;
    },

    seek(f, fps) {
      for (const animation of running) {
        const end = animation.effect.getComputedTiming().endTime || 0;
        animation.currentTime = Math.min(end, (f * 1000) / fps);
      }
    },

    settle() {
      for (const animation of running) animation.finish();
      running = [];
    },

    /** Elements that spill past the 1920×1080 frame or out of their box. */
    overflow() {
      const problems = [];
      document.documentElement.classList.add("no-anim", "measuring");
      document.body.getBoundingClientRect();
      for (const el of document.querySelectorAll(".stage *")) {
        const r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) continue;
        if (r.right > 1921 || r.bottom > 1081 || r.left < -1 || r.top < -1) {
          problems.push(`<${el.tagName.toLowerCase()} class="${el.className}"> runs off the frame`);
        } else if (
          getComputedStyle(el).overflow === "visible" &&
          (el.scrollWidth > el.clientWidth + 2 || el.scrollHeight > el.clientHeight + 2) &&
          el.clientWidth > 0 &&
          ["DIV", "PRE", "TD"].includes(el.tagName)
        ) {
          problems.push(`<${el.tagName.toLowerCase()} class="${el.className}"> content overflows it`);
        }
      }
      document.documentElement.classList.remove("no-anim", "measuring");
      return problems.slice(0, 10);
    },
  };
})();
