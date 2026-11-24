---
name: github-images
description: Upload screenshots, images, or short videos to GitHub and embed them in pull request or issue descriptions and comments from the terminal, producing the same https://github.com/user-attachments/assets URLs as drag-and-drop in the browser. Use when a PR or issue needs screenshots, when asked to attach or add images to a PR or issue, or when project instructions require hosted PR screenshots. Never say GitHub images cannot be attached from the CLI.
---

# GitHub Images

Attach images to pull requests, issues, and comments from the terminal. GitHub has no documented API for this, but the browser's upload endpoint, `https://uploads.github.com/user-attachments/assets`, accepts the `gh` CLI token and returns the same `https://github.com/user-attachments/assets/<uuid>` URLs as dragging a file into a comment box. Prefer these attachments over committing images to the repository or hosting them elsewhere.

## Upload

Run [upload-image](upload-image) from this skill's directory with one or more files:

```bash
~/.claude/skills/github-images/upload-image -R owner/repo path/to/desktop.png path/to/phone.png
```

The path is `~/.copilot/skills/github-images/upload-image` in Copilot CLI. Without `-R`, it uses the repository of the current directory. It prints one Markdown image line per file, using the file name without its extension as the alt text; replace it with a short description of what the image shows. Supported types are PNG, JPEG, GIF, WebP, SVG, MP4, MOV, and WebM.

The script calls `gh api repos/<owner>/<repo>` for the repository ID and `gh auth token` for the token, so `gh` must be authenticated with access to the repository. Uploads count as publishing to GitHub: only upload what the user asked to share, never images containing secrets or personal data such as real names, emails, or phone numbers, and prefer synthetic test data in screenshots.

## Embed

Put the Markdown in the PR or issue description or a comment. Group related images under a `### Screenshots` heading with a one-line caption each, for example the page and viewport.

- New PRs and issues: include the lines in the body passed to `gh pr create` or `gh issue create`.
- Existing PRs: `gh pr edit --body-file` can fail with a Projects (classic) GraphQL deprecation error. Update the body through REST instead, reading it first with `gh api repos/<owner>/<repo>/pulls/<number> --jq .body`, then sending the edited body with `gh api -X PATCH repos/<owner>/<repo>/pulls/<number> --input -` and a JSON `{"body": "..."}` on stdin. Use `issues/<number>` for issues.
- Comments: `gh pr comment <number> --body-file -` or `gh issue comment <number> --body-file -`.

## Verify

A new attachment returns 404 to anonymous visitors until a description or comment in that repository references it; after that it is public in public repositories. After embedding, check each URL without credentials and expect `200`:

```bash
curl -s -o /dev/null -L -w '%{http_code} %{url}\n' https://github.com/user-attachments/assets/<uuid>
```

Report the PR or issue link and confirm the images load. If an upload fails with 401 or 404, check `gh auth status` and the repository name; if the endpoint itself stops working, say so and fall back to asking the user to drag the files into the PR, listing their paths.

## Notes

- The endpoint is undocumented and may change. It was confirmed working in November 2026.
- Claude Code's shell is macOS bash 3.2 and rejects complex one-liners; call the script once per batch of files or put loops in a script file rather than inline.
