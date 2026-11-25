# Updating JavaScript Dependencies

npm, Yarn, pnpm, and Node.js specifics for the [update-dependencies](SKILL.md) sweep. Use the package manager the lockfile belongs to (`package-lock.json`, `yarn.lock`, or `pnpm-lock.yaml`) and the version in `packageManager` where set; the commands below are for npm. Verify versions with `npm view <package> version engines.node peerDependencies`. Validate with `npm ci`, then the project's `lint`, `test`, and `build` scripts.

The lessons in the Dependencies section of modernize-project's [javascript.md](../modernize-project/javascript.md) apply here too: `ERESOLVE` failures, peer conflicts from implicit transitive dependencies, prerelease ranges, and `npm audit` comparisons.

## Toolchain

Before fanning out, `nvm install` each Node.js major the projects use. Put the selected version's `bin` directory first on `PATH` explicitly, since a Homebrew Node.js can otherwise shadow `nvm use`.

## Minor and Patch Updates

1. Check that the lockfile is in sync with `npm ci`; fix a corrupt or out-of-sync lockfile minimally rather than regenerating it, and report it.
2. Record `npm outdated --json`.
3. Run `npm update` to move packages to their newest versions within the `package.json` ranges, then raise each range to the resolved version with `npm install <package>@^<version>`, saving development packages with `-D`, so the manifest records what was tested. For libraries, raise only development ranges, as the skill describes under Applications and Libraries.
4. Update `packageManager` within its major where it is set.
5. Rerun `npm outdated` and confirm that only majors and held-back packages remain. Never silence install output, since one unresolvable package aborts the whole install.
6. If the project commits build output, such as a GitHub Action's `dist/`, rebuild it as its CONTRIBUTING describes; otherwise leave build output uncommitted.
7. Report `npm audit --json` counts before and after.

## Development Dependencies

Development dependencies are those in `devDependencies`: linters such as ESLint and its plugins, formatters such as Prettier, test frameworks such as Jest, and type checkers such as TypeScript. In a bundled project, such as a browser extension or a GitHub Action built with `ncc` or webpack, bundlers and their loaders and plugins ship nothing at runtime either, so treat them as development dependencies. Respect version limits a project documents, such as keeping TypeScript within the range its test runner supports.

## Node.js Runtime

Node.js is declared in `.nvmrc`, `.node-version`, `engines.node`, `action.yml` (`runs.using`), Dockerfiles, and CI matrices. `engines.node` in a published package is a compatibility promise, not a pin. Check current releases and their support status at `https://nodejs.org/dist/index.json`.

## Major Upgrades

Find majors with `npm outdated`, and install each with `npm install <package>@^<major>`, checking peer ranges first.
