# Contributing

## Lint

Markdown is linted with [ESLint](https://eslint.org) and [@eslint/markdown](https://github.com/eslint/markdown), checking style, spelling, broken links and fragments with [eslint-plugin-markdown-links](https://github.com/ota-meshi/eslint-plugin-markdown-links), and pages unreachable from `README.md` with [eslint-plugin-markdown-links-unlinked](https://github.com/dblock/eslint-plugin-markdown-links-unlinked). It needs the Node.js version in `.nvmrc`.

```sh
npm ci
npm run lint
```

Run `npm run lint:fix` to apply automatic fixes. Add reviewed project vocabulary to `.spellcheck.txt`. The vendored [explain-with-video](agents/skills/explain-with-video/README.md) skill is kept verbatim, so only its structure and links are checked.
