---
name: update-dependencies
description: Sweep active projects (writable repositories with recent default-branch activity, App Platform apps discovered with doctl, and an include list, minus an exclude list), apply minor and patch dependency updates and major updates of development and test dependencies such as RuboCop or ESLint in every ecosystem each project uses, starting from an up-to-date default branch, run its tests, commit, open a PR, apply feasible major upgrades in stacked PRs, and report the rest as suggestions in one pass, working on projects in parallel background tasks. Use when asked to update dependencies across projects, to sweep projects for outdated dependencies, to update dependencies in one named project, or to verify App Platform deployments after merging dependency PRs.
---

# Update Dependencies

Sweep every active project in one pass: apply minor and patch updates in each local checkout, apply major updates of development and test dependencies where the project can absorb them, validate, commit, and open one PR per project; then evaluate the remaining major upgrades, apply the ones that are not too hard in stacked PRs on top, and suggest the rest. Explicit user limits override these defaults.

Ecosystem specifics live in guides next to this file: [ruby.md](ruby.md) for Bundler and Ruby, [javascript.md](javascript.md) for npm, Yarn, pnpm, and Node.js, and [other.md](other.md) for Cargo, Python, Java, Elixir, Go, and the rest. Read the guide for every ecosystem a project uses; one project often uses several, such as Bundler and npm.

Do not merge PRs, deploy, or change anything on DigitalOcean. Follow the shared development instructions for branch naming, version verification, validation, commits, and PRs. Do not add changelog entries for dependency upgrades unless the project requires them, as described under Commit and Open a PR; this overrides the shared changelog instructions.

## Discover Projects

By default, sweep every active project. If the user names one project, as `owner/repo`, a repository name, a local path, or the current directory ("this project"), sweep only that project: skip the project lists and activity tiers, check App Platform only to find its deployed branch and apps, and otherwise use its GitHub default branch (`gh repo view --json defaultBranchRef`). If a repository name matches more than one repository or local checkout, ask which one.

Discover projects every time rather than keeping a list of them, since they include private repositories. Never write private repository names into files, issues, or other external services; the final terminal report is the only place to list them. Public examples include `dblock/slack-strava`, `dblock/discord-strava`, and `dblock/posebook`.

1. Read the project lists: `~/.config/update-dependencies/projects.yml`, linked from [projects.yml](projects.yml) by the dotfiles setup script, and `~/.config/update-dependencies/projects.local.yml` if it exists. Both have `include` and `exclude` lists of `owner/repo` or `owner/*` entries. `projects.yml` is public, so add only public repositories and owners to it; private ones go in `projects.local.yml`, which is never committed.
2. List writable repositories with `gh api --paginate 'user/repos?affiliation=owner,organization_member,collaborator&per_page=100'` and keep those with `permissions.push`. This covers your own repositories, organization repositories, and other users' repositories where you are a collaborator. Drop archived repositories, forks, and anything matching `exclude`.
3. Add every `include` entry, even a fork, expanding `owner/*` with `gh repo list <owner> --no-archived`. `exclude` wins over `include`. Skip included repositories that are archived or not writable, and report them.
4. Add App Platform projects. Run `doctl auth list` and confirm a current context; if `doctl` is missing or unauthenticated, ask the user to authenticate (`! doctl auth init`), and if they decline, continue without App Platform data and say so. Never request tokens in chat. Run `doctl apps list -o json`. For each app, read `spec.services`, `spec.workers`, `spec.jobs`, `spec.static_sites`, and `spec.functions`, and collect each component's `github` source with its `repo` and `branch`, along with the app `id` and component names for checking deployments. Deduplicate by repository; one app often has several components from the same repository, and one repository may back several apps.
5. Classify the remaining repositories by activity, using the newest default-branch commit not made by a bot: `gh api 'repos/<owner>/<repo>/commits?per_page=30'`, skipping commits whose `author.type` is `Bot` or whose author login ends in `[bot]`, and paging further only until the 12-month cutoff. Do not use the repository's push time, since bot branches update it.
   - Active: a non-bot commit in the last 3 months. App Platform and `include` projects are always active. Sweep these.
   - Dormant: the newest non-bot commit is 3 to 12 months old. List these with that date and ask once, for all of them together, which to sweep.
   - Inactive: older than 12 months. Skip these and give their count in the report.

## Locate Checkouts

Find each repository's local checkout by its remotes, as described under Repository Layout and Worktrees in [instructions.md](../../instructions.md). When the only match is a fork checkout, push the branch to the fork and open the PR against the upstream repository.

If repositories have no local checkout, list them and ask once, for all of them together, whether to clone them; skip them otherwise. Clone writable repositories directly, without a fork, to `~/source/<repo>/<branch>` using the deployed or default branch name, or to `~/source/<owner>/<repo>/<branch>` when `~/source/<owner>` already exists.

## Run in Parallel

Projects are independent, so do the per-project work in parallel on background tasks rather than one project at a time. With a single named project, do the work directly.

1. In the main session, finish everything that needs the user before fanning out: discovery, the dormant-project question, locating checkouts, and questions about missing checkouts or ambiguous names.
2. Install shared toolchains once, before fanning out, so parallel tasks do not race, as each ecosystem guide describes; for example, missing Ruby patches and their Bundler versions with `rvm`, Node.js majors with `nvm`, and Rust with `rustup`.
3. Start one background subagent per project, all in the same turn, as one batch, with your agent tool's background mode. Give each one the repository, checkout path, deployed or default branch, the ecosystems it uses, and the paths to this skill and the matching guides, and tell it to follow everything from Prepare Each Checkout through Stack Major Upgrades for that project only.
4. Subagents must not ask the user questions. When blocked, a subagent leaves its checkout in a safe state and returns the question in its report. Each one returns its part of the report: updates applied and held back, PR URLs with CI results, superseded bot PRs, abandoned attempts, suggestions, and skips.
5. Do not poll. Wait for completion notifications, and meanwhile only do work that does not touch the projects' checkouts. Each subagent waits for its own PRs' CI and fixes failures before it finishes.
6. Projects may share local services, such as a local MongoDB, where most use their own database names. If two projects' test configurations use the same database name (for example in `config/mongoid.yml`), run those two projects' tests one after the other instead of at the same time.
7. When every subagent has finished, ask any blocked questions together, then write the report.

## Prepare Each Checkout

1. Record the current branch so the user can return to it.
2. Run `git status --porcelain`. If the checkout has uncommitted or untracked changes, skip it and report why; never stash, reset, or discard work.
3. Run `git fetch --prune origin`.
4. Run `gh pr list --state open --json number,title,author,headRefName,files` and note open dependency-bot PRs (authors `app/dependabot` and `app/renovate`) and the updates each proposes.
5. Resolve branches left by earlier sweeps, as described under Existing Branches.
6. Always start from an up-to-date base branch: the deployed branch from the app spec for App Platform projects, or the GitHub default branch (`gh repo view --json defaultBranchRef`) otherwise. Switch to it and run `git pull --ff-only`. Projects use either `master` or `main`, so never assume one; `git switch <branch>` creates a tracking branch when only `origin/<branch>` exists. If the spec branch differs from the GitHub default branch, use the spec branch and report the mismatch. If the local branch has diverged from `origin`, skip the checkout and report it; never reset or rebase it.
7. Create the topic branch from it: `git switch -c dblock/update-dependencies`, or the dated name chosen under Existing Branches.

### Existing Branches

Earlier sweeps leave `dblock/update-dependencies` and `dblock/upgrade-<name>-<major>` branches behind. Before creating any of these branches, check whether it exists locally (`git branch --list`) or on the remote (`git ls-remote --heads origin <branch>`), and find its PR with `gh pr list --head <branch> --state all --json number,state,headRefOid,mergedAt,mergeCommit`.

- If its PR merged on GitHub, the local branch tip (if any) equals the PR's `headRefOid` or is contained in the base branch, and no open PR uses the branch as its base, delete it: `git branch -D <branch>` locally and `git push origin --delete <branch>` if it is still on the remote. Rebase merges rewrite commits, so verify the merge through GitHub rather than `git branch --merged`. For App Platform projects, then check the deployment of that merge as described under Verify Deployments. Reuse the branch name.
- If the merged branch has local commits that are not in the PR, or an open PR is based on it, leave it and report it.
- If the merged branch is checked out in a linked worktree (`git worktree list`), remove that worktree with `git worktree remove <path>` before deleting the branch, but only when it has no uncommitted or untracked changes; otherwise leave both and report them. Never remove the main checkout.
- If the branch has an open PR, no PR, or a closed unmerged PR, leave it untouched and use a dated name instead, such as `dblock/update-dependencies-2026-11-22` or `dblock/upgrade-faraday-3-2026-11-22`. If the dated name is taken too, add a numeric suffix (`-2`).

## Apply Minor and Patch Updates

Verify current releases from the registries rather than remembered numbers, and exclude prereleases. Treat a change in the first version component as major; for `0.x` versions, also treat a change in the second component as major.

Find every ecosystem the project uses from its manifests and lockfiles, including those in subdirectories, and for each one, using the commands in its guide:

1. Record outdated dependencies with their current and latest versions.
2. Update dependencies to their newest minor and patch releases within each current major and the declared constraints.
3. Raise constraints that block a non-major update, such as `'~> 2.3.0'` or an exact pin, to the newest release within the same major, keeping the file's existing constraint style. Leave constraints that carry an explanatory comment, are documented in the project's AGENTS or CONTRIBUTING, or are clearly deliberate, and report them as held back.
4. Update the package manager's recorded version within its major, such as `BUNDLED WITH` or `packageManager`.
5. Record outdated dependencies again and confirm that only major updates (and held-back dependencies) remain.

If an ecosystem has no guide entry and no reliable standard tool for these steps, leave it and report it as not covered.

### Applications and Libraries

Applications, such as App Platform projects, run exactly what their lockfiles pin, so update lockfiles and constraints freely. Libraries, such as gems, npm packages, and crates, promise compatibility ranges to their consumers: update committed lockfiles and development dependencies, but do not raise a runtime dependency's lower bound or a runtime minimum (`required_ruby_version`, `engines.node`, `rust-version`, `requires-python`) only to track the newest release. Widening a runtime range to allow a new major is a major upgrade; narrowing one or raising its floor is a breaking change to suggest rather than make.

### Development and Test Dependencies

Keep development and test dependencies current, including major versions, since they do not ship to production: linters, formatters, test frameworks and helpers, and development-only build tools. The guides name each ecosystem's development groups. Treat a dependency that is also a runtime dependency as a runtime dependency.

1. For each with a new major, raise its constraint to the new major in the file's existing style and update it together with its plugins, so they stay compatible.
2. After a linter update, run the linter, fix new offenses with safe autocorrection and small manual fixes, and resolve renamed or removed rules in its configuration.
3. If a major update needs more than small, clear fixes to pass tests and lint, revert it (and its plugins) to the newest compatible minor and suggest the major with the failure, rather than retrying it in a stacked PR.

### Runtimes

Runtimes are declared in several places that must stay consistent, such as version files, the manifest, Dockerfiles, CI workflow matrices, and platform files like `app.json`; the guides list them. For pinned runtimes, apply the newest patch release within the current minor to every declaration. Treat a new runtime minor or major, and adding or dropping a runtime line in a CI matrix, as a major upgrade.

Before changing a deployed runtime, confirm the version is supported where the project deploys: the [App Platform buildpacks](https://docs.digitalocean.com/products/app-platform/reference/buildpacks/) for buildpack apps, and the official Docker image tag for Dockerfile apps.

### GitHub Actions and Other Manifests

- Update GitHub Actions pinned to exact versions (`@v1.2.3`) to the newest release within the same major. For SHA-pinned actions, update both the SHA and its version comment, resolving the SHA from the release tag. Leave floating major tags (`@v2`) and `@latest` as they are; suggest replacing `@latest` with a pinned version.
- Treat new action majors as major upgrades.
- Apply the same rule to Docker base images and service versions in CI (for example MongoDB): update minor and patch versions, and treat majors as major upgrades.

## Validate

1. Read the project's AGENTS, CONTRIBUTING, and build files (Rakefile, `package.json` scripts, Makefile, and so on) for its test, lint, and build commands; the guides give each ecosystem's defaults.
2. Make sure required services are running, such as a local MongoDB for projects using Mongoid. If a service cannot be started, report the tests as not run rather than skipping them silently.
3. Run the tests, lint, and build once after all updates, fixing lint offenses as described under Development and Test Dependencies, and rerun.
4. If an update breaks tests and the fix is not small and clear, revert that one dependency to its previous version, rerun the affected checks, and report it as held back with the failure.

## Commit and Open a PR

Commit and open a PR only for projects whose tests and lint pass locally, or whose checks could not run for a reported reason the user has accepted. Leave failing projects uncommitted on the topic branch and report them. If a project has no minor, patch, or development and test updates, delete its empty topic branch and start the major-upgrade stack from the base branch instead; if it has no feasible major upgrades either, switch back to the previous branch.

Add no changelog entry unless the project requires one for every PR, through its AGENTS or CONTRIBUTING, or a Danger or changelog check that fails without one. When the check honors a skip label for dependency updates, such as `skip-changelog`, apply the label instead; otherwise add an entry following the shared changelog instructions and the project's format.

1. Commit everything as one commit, such as `Update dependencies`, with the AI co-author trailer.
2. Push with `git push -u origin <branch>` and open a PR against the base branch with `gh pr create --base <branch>`, passing `--repo <owner>/<repo>` for forks, since `gh` otherwise targets the parent repository. In the description, disclose that the author is an AI acting on behalf of `@dblock`, and list the updates applied (current → new), held-back updates with reasons, and the actual local validation. Add `Supersedes #<number>` for each open bot PR it supersedes, as described below.
3. Wait for CI in the background (`gh pr checks <number> --watch`) while starting the major-upgrade stack, and fix failures on the PR's head. Do not merge.

### Superseded Bot PRs

In each PR, base or stacked, add one `Supersedes #<number>` line per open Dependabot or Renovate PR whose updates it fully covers, meaning it brings every dependency that bot PR changes to the same or a newer version. For a bot PR it covers only partly, write `Related to #<number>` instead. Dependabot and Renovate close their own PRs once the base branch has the update, so do not close bot PRs yourself.

## Stack Major Upgrades

After the base PR is open, evaluate every remaining major upgrade: runtime dependencies in every ecosystem, package managers, a runtime minor or major, GitHub Actions, and majors in other manifests. Apply the ones that are not too hard in stacked PRs on top of the base PR, and suggest the rest.

### Evaluate

For each candidate, read the upstream changelog or upgrade guide, search the project for affected APIs and configuration, note deprecation warnings in the test output, and check compatibility: the dependency's runtime requirements (such as `required_ruby_version` or `engines.node`), constraints from other dependencies that block resolution, and for a runtime, support where the project deploys. An upgrade is not too hard when it:

- Resolves without forcing unrelated major upgrades.
- Needs changes in only a few call sites or configuration entries.
- Needs no data migration, change to stored data formats, new environment variables, or App Platform settings beyond the version declaration.
- Passes tests and lint after those changes.

Never attempt majors of payment libraries such as `stripe`, whose majors pin a new API version and have proven difficult; always suggest them instead, with the evaluation. Majors of the web or data framework, such as Mongoid or Rails, are worth trying: evaluate them like any other major, and stack them after the smaller upgrades.

### Build the Stack

Follow the shared stacked-PR instructions. Order upgrades from easiest to hardest, one PR per upgrade, or per tightly coupled group such as a dependency and its plugins or two dependencies whose majors require each other.

1. Branch each layer from the one below, resolving existing branches first as described under Existing Branches: `git switch -c dblock/upgrade-<name>-<major>` from the base PR branch or the previous layer, for example `dblock/upgrade-faraday-3` or `dblock/upgrade-ruby-4.1`.
2. Raise the constraint or version declaration, update it with the ecosystem's tools, fix the code, and run the full tests and lint.
3. If the fixes grow beyond the evaluation or tests fail without a clear fix, abandon the layer: switch back to the layer below, delete the unpushed branch, and move the upgrade to the suggestions with what was found. Continue with the next candidate.
4. Commit the layer as one commit, push it, and open a PR with `gh pr create --base <branch below>`. Describe only this layer: the upgrade (current → new), the upstream changelog link, the code changes and why, the actual local validation, `Supersedes #<number>` for each open bot PR it supersedes, and which PR it builds on.
5. Register the stack natively with `gh stack link --base <base branch> <base PR> <layer PRs...>`, and verify each PR with `gh api repos/<owner>/<repo>/pulls/<number> --jq .stack`. Report unsupported native stack operations rather than substituting a plain dependent-PR chain silently.
6. Wait for CI on each layer in the background and fix failures on that layer. If a fix changes a lower layer, rebase the layers above onto it and push each with `--force-with-lease=refs/heads/<branch>:<recorded-sha>`.

Finally, update the base PR description with links to the stacked PRs and the remaining suggestions. For each suggestion, give current and latest versions, the upstream changelog or upgrade guide link, and why it was judged too hard. Group upgrades shared by several projects (for example a common dependency or runtime version) so they can be planned once.

## Verify Deployments

Only App Platform projects deploy: every app deploys on push to its deployed branch, so merging a sweep PR ships it to production. Verify deployments of merged sweep PRs, both when the user says they merged them or asks to verify deployments (run only this section then) and when Existing Branches finds an earlier sweep's merged PR in an App Platform project.

1. Get the merge with `gh pr view <number> --json mergeCommit,mergedAt,baseRefName`, and the app IDs for the repository from discovery.
2. List deployments with `doctl apps list-deployments <app id> -o json`. Find the earliest deployment created after `mergedAt` whose `cause_details.git_push.commit_sha` is the merge commit or contains it (`git merge-base --is-ancestor <merge commit> <deployment commit>`), since one deployment can include several pushed commits.
3. Read its `phase`. `ACTIVE`, or `SUPERSEDED` by a later successful deployment that also contains the merge, means it deployed. If the phase is still in progress (pending, building, or deploying), wait in the background with a bounded check rather than polling in the foreground. If no deployment contains the merge, report that.
4. If the phase is `ERROR` or `CANCELED`, read the logs with `doctl apps logs <app id> <component> --type build --deployment <deployment id>`, and with `--type deploy` for deploy failures; summarize the cause. After an `ACTIVE` deployment, scan recent run logs (`doctl apps logs <app id> <component> --type run`) for boot errors or crash loops.
5. Never roll back, redeploy, or change the app. For a failure caused by the update, prepare a fix on a new branch and open a PR as in Commit and Open a PR, and tell the user right away, since production may be on the previous deployment or down.

## Report

When all background tasks have finished, end with a single report in the terminal, printing full URLs rather than Markdown links:

- Discovery: counts of active, dormant (and which were chosen), and inactive projects; excluded projects; and include-list entries that were skipped and why.
- A summary table with one row per project: checkout path, ecosystems, previous branch, branch used, number of minor and patch updates applied, local test and lint result, base PR URL and CI result, stacked major-upgrade PRs with CI results, held-back count, and major upgrades suggested.
- For each project: notable updates applied (current → new), held-back updates with reasons, overlapping open bot PRs, stacked PRs in order, abandoned major attempts with reasons, suggested major upgrades, and ecosystems not covered.
- Grouped major-upgrade suggestions that apply to several projects.
- Existing branches deleted after merge, branches left in place with reasons, and dated branch names used.
- Deployment status for merged sweep PRs in App Platform projects: deployed, in progress, or failed with the cause and any fix PR.
- Skipped projects and why: dirty checkout, diverged base branch, no updates, or missing checkout.
- Projects left uncommitted because checks failed, with `git -C <path> diff` to examine them.
