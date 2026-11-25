---
name: modernize-project
description: Modernize stale Ruby gem and JavaScript repositories in stacked PRs — move Travis or broken CI to GitHub Actions on current runtimes, add documentation linting and clean up Markdown, speed up CI, update Danger, and update dependencies — working on several repositories in parallel background tasks. Use when asked to modernize, refresh, or revive one or more repositories, to bring a project's CI, docs, or tooling up to date, or to find which maintained projects need modernization.
---

# Modernize Project

Bring a repository that has not been touched in a while up to current conventions and current dependencies as a native GitHub stack of small PRs, one concern per PR, each with green CI. Explicit user limits override these defaults. Follow the shared development instructions in [instructions.md](../../instructions.md) for locating or cloning checkouts, branch naming, stacked PRs, changelogs, version verification, validation, commits, and PR text.

Do not merge, release, tag, bump a released version, configure trusted publishers, or raise a package's minimum runtime (`required_ruby_version`, `engines`); report those as decisions for the user. Open regular PRs, not drafts, unless the repository's instructions say otherwise.

This file is the workflow shared by every ecosystem. Each layer below states its goal; the concrete tools, files, and known pitfalls are in the ecosystem guide, which you must read before building the stack:

- [ruby.md](ruby.md) for Ruby gems.
- [javascript.md](javascript.md) for JavaScript packages and browser extensions built with npm.

For another ecosystem, apply the same layers with that ecosystem's tools and say what was adapted in the report.

## Find Candidates

When asked which projects need modernization, list the non-archived, non-fork repositories the user can push to with `gh api graphql` (`viewer.repositories` with `ownerAffiliations: [OWNER, ORGANIZATION_MEMBER, COLLABORATOR]`). For stale ones, last pushed more than six months ago, collect stars, open issue and PR counts, whether `.github/workflows` or `.travis.yml` exists (`object(expression: "HEAD:<path>")`), and the latest release. Check real usage on RubyGems (`/api/v1/versions/<gem>.json` for the latest release date, `ruby_version`, and downloads) or npm (`api.npmjs.org/downloads/point/last-month/<package>`). Rank by usage rather than stars, and separately suggest archiving projects whose upstream service or framework is gone. Do not start modernizing until the user picks repositories.

## Run in Parallel

Repositories are independent, so start one background subagent per repository, all in the same turn. Give each one the repository name, its ecosystem, known facts (current CI, services the tests need, open PR counts), and the path to this skill, and tell it to follow everything from Prepare through Report for that repository only. With one repository, do the work directly.

Subagents must not ask the user questions; when blocked, a subagent leaves its checkout in a safe state and returns the question in its report. Do not poll; wait for completion notifications. When all have finished, give one combined report with every PR URL, its stack, its CI result, and one consolidated list of decisions for the user.

## Prepare

1. Identify the ecosystem from the repository's language and manifests (`*.gemspec`, `Gemfile`, `package.json`), and read its guide.
2. Locate the checkout by its remotes, or clone it, per the shared instructions. Renamed repositories leave checkouts whose remotes still use the old name, which GitHub redirects; before cloning, check directories named after the repository and remotes using its former names (`gh api repos/<owner>/<old-name> --jq .full_name` resolves to the current name). Never clone into an existing directory, which nests one checkout inside another. Read `AGENTS.md`, `CONTRIBUTING.md`, and `RELEASING.md` if present.
3. Inspect the checkout before branching: uncommitted work, unpushed commits on the default branch, and stashes belong to the user, so leave them in place, branch from `origin/<default-branch>`, and mention them in the report, including whether the stack supersedes them.
4. Fetch, and check open PRs (including Dependabot and Renovate), recent default-branch commits, and recent failed workflow runs (`gh run list`), since failing Dependabot runs often point at a broken manifest or lockfile. Do not duplicate open PRs; name overlaps and likely rebase conflicts in the PR bodies. Another session may be working on the same repository at the same time: recheck open PRs before predicting PR numbers, and never touch another session's branches or checkouts.
5. Verify current versions before writing any: runtime releases and their support status, `actions/checkout`, the setup action, linters and their plugins, and the latest `danger/danger-pr-comment` tag where Danger is used.
6. Run the existing suite on the oldest and newest runtimes you intend to test, installing strictly from the lockfile where there is one, to learn what is broken before changing anything. Confirm the tools actually came from the checkout: a stray `node_modules` or Gemfile in a parent directory can make a broken checkout look green.

## Stack

Build these layers in order, each on the branch below it, skipping layers that are already done. Never combine layers. Each PR is one commit with its own CHANGELOG entry, validated locally on the newest and oldest tested runtimes and with `actionlint` before pushing. When the checkout contains untracked directories that the project's globs pick up, such as another session's nested checkout, validate from a fresh `git clone --branch <layer>` of the checkout in a scratch directory instead of adding ignores for them.

### 1. CI

Only when CI is Travis, missing, broken, or on stale runtimes or actions. Title it "Replace Travis CI with GitHub Actions" or "Test on current <runtime> with current GitHub Actions".

- Replace the old workflow with `test.yml` (`Test`) using a `matrix.entry` that covers the oldest runtime that still works and current releases, with `permissions: contents: read` and dependency caching.
- Install exactly what the lockfile says; remove steps that update dependencies during CI.
- Update release and post-release workflows in the same layer: their runtime versions, action majors, install commands, and `actionlint` findings such as unquoted `$GITHUB_OUTPUT`. These cannot run before a release, so validate them with `actionlint` and say so.
- Remove dead badges and stale CI mentions in CONTRIBUTING and RELEASING, and add the new workflow's badge.
- Fix real incompatibilities in focused ways, and check that tests actually exercise the code: confirm that a test fails when the code under test is removed or broken. Upstream frameworks change defaults, leaving tests that pass vacuously.

### 2. Docs Lint

Title it "Lint documentation and clean up Markdown", or "Lint code, Markdown, and spelling, and clean up documentation" when the code linter also moves to a new major.

- Move the code linter to its current major and add Markdown and spelling linters, with reviewed vocabulary in `.spellcheck.txt`, all run by the project's single lint command.
- Run lint in a separate `lint.yml` (`Lint`) on the newest runtime only, and remove lint from `Test`.
- Clean up README, CONTRIBUTING, and RELEASING per the shared documentation rules: title-case headings, one-line paragraphs, fenced code with languages, image alt text, separate Installation, Usage, and Configuration sections, and links to the project's documentation.
- Give the CHANGELOG a `# Changelog` title. When a post-release workflow prepends the next version, change it to insert below the title, and run its snippet locally against the new file. Fix wrong release dates and leftover placeholders in released sections unless Danger rejects edits to released entries, in which case add words to `.spellcheck.txt` instead.
- Keep `LICENSE` text verbatim, and exclude it, deliberately invalid fixtures, and generated files from linting.
- Avoid backticks in headings when the repository runs `danger-toc`.

### 3. CI Performance

Title it "Speed up CI". The model is [mongoid-geospatial#83](https://github.com/mongoid/mongoid-geospatial/pull/83).

- Run `push` builds only on the default branch, so same-repository PR branches do not build twice.
- Add a per-workflow, per-ref `concurrency` group with `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`, so superseded PR runs are cancelled and default-branch runs never are.
- Set `timeout-minutes` on every job (10 is usually enough), including release workflows; jobs that call reusable workflows cannot take one.
- Test jobs run tests only, since lint runs once in `Lint`, and dependency caching is on.
- Confirm on the pushed PR that each workflow ran once, on `pull_request`.

### 4. Danger

Only when the repository uses Danger. Move `numbata/danger-pr-comment` or a hand-rolled comment workflow to the latest `danger/danger-pr-comment` release, update the gem, add the comment permissions it documents, set `base-branch: '*'` so stacked PRs get comments, and set `comment-empty: false` so pull requests without findings get no comment (an existing comment is still updated when its findings clear). The comment workflow runs from the default branch's copy, so it takes effect only after merge; say so in the PR. If the repository has no Danger, skip this layer and mention any open issue asking for it.

### 5. Dependencies

Always finish the stack by updating dependencies, after the layers above are pushed, so updates are validated by the modernized CI. Follow the [update-dependencies](../update-dependencies/SKILL.md) skill from Prepare Each Checkout through Stack Major Upgrades, with these adaptations:

- Branch `dblock/update-dependencies` from the top modernization layer rather than the default branch, open its PR against that layer, and stack its major-upgrade PRs above it, all in the same native stack. If no modernization layer was needed, start from the default branch as that skill describes.
- Skip DigitalOcean discovery and Verify Deployments unless the repository is deployed on App Platform; use the GitHub default branch where that skill says deployed branch.
- Development and test dependencies that the CI and docs lint layers already moved to current majors need no second update; update everything else, including GitHub Actions and service versions in CI.
- Use that skill's ecosystem guide alongside this skill's guide for the repository.
- Keep that skill's rules on superseded bot PRs (`Supersedes #<number>`), held-back updates, abandoned majors, and suggestions, and add no changelog entries for dependency upgrades.
- Report security advisory counts before and after (`npm audit`, `bundle audit` where installed), and why any remaining advisory was left.

Include its results in the report: updates applied, held back, stacked majors, and suggestions.

## Push and Verify

1. Predict each PR's number from the latest issue or PR number, rechecked just before creating the PR. Registering a stack with `gh stack link` also consumes a number in the shared sequence, so create every PR before linking, and correct any mispredicted CHANGELOG link with a lease-guarded force push. When a PR is added above an existing stack, rerun `gh stack link` with the full list.
2. Push each layer and open its PR against the layer below. Run `gh pr checks <number> --watch` in the background and fix failures until the final head is green. CI often surfaces resolver differences that local runs miss; pin narrowly, with a comment, for the affected combination only.
3. Register the stack with `gh stack link --base <default-branch> <bottom> ... <top>` and verify each PR with `gh api repos/<owner>/<repo>/pulls/<number> --jq .stack`.
4. Leave the checkout clean and on the branch it started on, and remove scratch clones and build artifacts the task created, keeping artifacts that were already there.

## Report

For each repository, report a table of PR URL, title, base, and CI result on the final head; the stack URL; what each layer changed in a few bullets, including real bugs found; dependency updates applied and held back, and suggested major upgrades, grouped across repositories when shared; layers skipped and why; overlaps with open PRs and other sessions' work; and the user's local state left in place, such as unpushed commits. End with decisions for the user, typically the runtime floor against the oldest tested runtime, dependency floors CI proved too low, package metadata, packaging bugs noticed out of scope, untested behavior that needs a manual check, and whether to release unreleased fixes.
