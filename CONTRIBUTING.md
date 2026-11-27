# Contributing

## Lint

Markdown is linted with [ESLint](https://eslint.org) and [@eslint/markdown](https://github.com/eslint/markdown), checking style, spelling, broken links and fragments with [eslint-plugin-markdown-links](https://github.com/ota-meshi/eslint-plugin-markdown-links), and pages unreachable from `README.md` with [eslint-plugin-markdown-links-unlinked](https://github.com/dblock/eslint-plugin-markdown-links-unlinked). It needs the Node.js version in `.nvmrc`.

```sh
npm ci
npm run lint
```

Run `npm run lint:fix` to apply automatic fixes. Add reviewed project vocabulary to `.spellcheck.txt`. The vendored [explain-with-video](agents/skills/explain-with-video/README.md) skill is kept verbatim, so only its structure and links are checked.

## Agent Setup

Run the setup tests against a temporary home, the shared session title tests against a fake project root and model CLI, and the Copilot hook tests against a fake title script:

```sh
bash scripts/setup.test.sh
agents/claude/hooks/session-title/session-title.test.sh
agents/copilot/hooks/session-title/session-title.test.sh
```

Setup must preserve unrelated Copilot settings and remain safe to repeat. Copilot and Claude Code share the title script, pinned emojis, and cache.
