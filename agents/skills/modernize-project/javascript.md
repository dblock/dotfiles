# Modernizing JavaScript Projects

JavaScript specifics for each layer of the [modernize-project](SKILL.md) stack, for npm packages and for browser extensions built with npm and webpack. Validate each layer with `npm ci`, `npm run lint`, `npm test`, and the build (`npm run build`, plus the packaging script such as `npm run repack` or `npm pack` when packaging changes) on the oldest and newest tested Node.js versions. Install other Node.js versions with `nvm install <major>`, and put the selected version's `bin` directory first on `PATH` explicitly, since a Homebrew Node.js can otherwise shadow `nvm use`.

## Prepare

- Verify current Node.js releases and their support status from `https://nodejs.org/dist/index.json` (the `lts` field) and the release schedule, `actions/setup-node`, and each tool's `engines.node` with `npm view <package> version engines.node`.
- Check that `package-lock.json` parses and `npm ci` succeeds. Corrupt or out-of-sync lockfiles hide behind CI that runs `npm install`, and they make every Dependabot run fail.

## 1. CI

- Test the maintained LTS lines and the current release, for example `{ node: '22' }`, `{ node: '24' }`, `{ node: '26' }`. Drop end-of-life lines, and keep a line only as long as the dev tools support it.
- Use `actions/setup-node` with `cache: npm`, run `npm ci`, and remove `npm install` and `npm update` steps that make CI test something other than the lockfile. Run tests and the build in `Test`; for a published package, also check `npm pack` output in a `package.yml` (`Package`) workflow, as the shared instructions describe.
- Fix a corrupt lockfile minimally (for example, a stray character before the JSON) and run `npm install` to resync its name and version, rather than regenerating it, so the diff stays reviewable.
- Move test-only packages such as `jest-environment-jsdom` and `jsdom` from `dependencies` to `devDependencies`. A browser extension bundles only what its source imports, so runtime dependencies are those imported by `src`.
- Release workflows that build and upload artifacts should also use `npm ci`.

## 2. Docs Lint

- Move ESLint to its current major with a flat `eslint.config.js` built from `@eslint/js`, `globals`, and `eslint-plugin-prettier/recommended` (which includes `eslint-config-prettier`). Carry over environments and custom globals from `.eslintrc.*`, mark CommonJS configuration files with `sourceType: "commonjs"`, move `.eslintignore` entries to `ignores`, and remove plugins the old configuration never enabled. ESLint 9 and newer drop `--ext`.
- Add `markdownlint-cli2` with `.markdownlint-cli2.jsonc` (disable `MD013` for one-line paragraphs, allow only the inline HTML elements actually needed, such as `img` for an icon in the title, and ignore `node_modules`, build output, and `LICENSE.md`) and `cspell` with `cspell.json` loading `.spellcheck.txt` as a custom dictionary and ignoring the lockfile, fixtures, and binary assets.
- Compose `npm run lint` from `lint:js`, `lint:md`, and `lint:spelling` scripts, keeping `lint:fix`.
- Both linters need Node.js 22 or newer; run `Lint` on the newest Node.js and state the floor in CONTRIBUTING.
- Markdownlint's command-line negations do not override the `globs` in its configuration file, which is another reason to validate from a fresh clone when the checkout has untracked nested directories.

## 5. Dependencies

- Record `npm outdated`, run `npm update`, and raise `package.json` ranges to the resolved versions with `npm install <package>@^<version>`, saving dev packages with `-D`.
- Development tools ship nothing at runtime in a bundled project, so apply their majors in the base PR, as update-dependencies does for development gems. Runtime dependencies are the packages the bundle imports.
- One unresolvable package aborts a whole `npm install` with `ERESOLVE`, so never silence its output with `-s`, and rerun `npm outdated` to confirm what changed. Install conflicting majors separately to find the one that conflicts.
- Peer conflicts often come from an implicit transitive dependency, for example Babel 8's `@babel/preset-env` needing `@babel/core` 8 while Jest pulls in 7. Check the consumer's real peer range (`npm view babel-jest peerDependencies`), add the peer as a direct dev dependency, and confirm which copy is loaded with `require.resolve` and `npm ls`.
- Move prerelease ranges such as `^4.0.0-beta` to the first stable release.
- Compare `npm audit --json` counts before and after. Leave advisories whose only fix is a downgrade (`npm audit fix --force`), and name the tools they come from.

## Decisions

Typical decisions for the user: the `engines.node` floor for published packages, unused bootstrap leftovers such as `file-loader` or CSS loaders in a project without CSS or image imports, packaging scripts that derive artifact names from the checkout directory, and checking a browser extension manually in the browser against the live site before releasing.
