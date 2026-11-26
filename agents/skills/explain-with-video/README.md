# explain-with-video

This skill is a vendored copy, not original work. It comes from [marekkirejczyk/skills](https://github.com/marekkirejczyk/skills) by Marek Kirejczyk, path [`skills/explain-with-video`](https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/skills/explain-with-video), at commit [`467825e`](https://github.com/marekkirejczyk/skills/commit/467825ee3c9cf69ba2152603c477a1431e463c67). It is distributed under the MIT license in [LICENSE](LICENSE), copied from the upstream repository.

Only this one skill is copied, instead of installing the author's whole plugin with `claude plugin install` or `npx skills add`. Every file except this README and `LICENSE` is unchanged from upstream. See the upstream [README](https://github.com/marekkirejczyk/skills#explain-with-video-a-narrated-explainer) and [how it works](https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/docs/explain-with-video.md) for usage, and report issues there.

## What It Does

`/explain-with-video` makes a narrated MP4 explainer, with captions and a video page, for a repository or a pull request. It runs only when invoked. It needs `ffmpeg`, `ffprobe`, Node 18 or newer, and `playwright-core` with Chromium, which it installs into each video's working folder. It uses macOS `say` for narration by default, and ElevenLabs or OpenAI when an API key is configured in `ELEVENLABS_API_KEY`/`OPENAI_API_KEY`, the Keychain items `repo-video-elevenlabs`/`repo-video-openai`, or `~/.config/repo-video/`. Paid providers receive the narration text and spend account credits. Scenes and the video page load fonts from Google Fonts.

## Update

Replace the directory's contents with the upstream skill at a newer commit, keep this README and `LICENSE`, update the commit links above, and review the diff before committing.

```bash
sha=$(gh api repos/marekkirejczyk/skills/commits/HEAD --jq .sha)
src=$(mktemp -d)
gh api "repos/marekkirejczyk/skills/tarball/$sha" | tar -xz -C "$src" --strip-components 1
rsync -a --delete --exclude README.md --exclude LICENSE "$src/skills/explain-with-video/" agents/skills/explain-with-video/
cp "$src/LICENSE" agents/skills/explain-with-video/LICENSE
rm -rf "$src"
```
