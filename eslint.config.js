import markdown from "@eslint/markdown";
import links from "eslint-plugin-markdown-links";
import unlinked from "eslint-plugin-markdown-links-unlinked";
import preferences, { resources } from "eslint-plugin-markdown-preferences";
import paragraph from "eslint-plugin-markdown-preferences-paragraph";
import proseSpellcheck from "eslint-plugin-prose-spellcheck";

// Skills vendored from other repositories stay verbatim; only structure and links are checked.
const vendored = ["agents/skills/explain-with-video/**"];

export default [
  {
    ignores: ["node_modules/**"],
  },
  {
    files: ["**/*.md"],
    plugins: {
      markdown,
      "markdown-links": links,
      "markdown-links-unlinked": unlinked,
    },
    language: "markdown/gfm",
    languageOptions: { frontmatter: "yaml" },
    rules: {
      ...markdown.configs.recommended[0].rules,
      ...links.configs.recommended.rules,
      // Every page, including each skill's SKILL.md, must be reachable from the README.
      "markdown-links-unlinked/no-unlinked-pages": ["error", {
        roots: ["README.md"],
        // The vendored explain-with-video skill names its reference page by path rather than linking it.
        ignore: ["agents/skills/explain-with-video/reference/**"],
      }],
    },
  },
  {
    files: ["**/*.md"],
    ignores: vendored,
    plugins: {
      "markdown-preferences": preferences,
      paragraph,
      "prose-spellcheck": proseSpellcheck,
    },
    rules: {
      ...preferences.configs.standard.rules,
      "markdown/no-duplicate-headings": "error",
      "markdown/no-bare-urls": "error",
      "markdown-preferences/no-heading-trailing-punctuation": "error",
      // Allow unaligned tables, matching sibling projects.
      "markdown-preferences/table-pipe-alignment": "off",
      "markdown-preferences/heading-casing": ["error", {
        style: "Title Case",
        preserveWords: [...resources.defaultPreserveWords, "CI", "iMessage", "macOS", "PR", "PRs", "README"],
      }],
      // Its fix turns relative links such as [ruby.md](ruby.md) into <ruby.md>, which GitHub does not link.
      "markdown-preferences/prefer-autolinks": "off",
      "paragraph/wrap": ["error", { width: "nowrap" }],
      "prose-spellcheck/spellcheck": ["error", {
        dictionaries: ["@cspell/dict-en_us", "@cspell/dict-software-terms", "./.spellcheck.txt"],
        baseDir: import.meta.dirname,
      }],
    },
  },
];
