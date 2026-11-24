---
name: update-dependencies
description: Sweep projects deployed on DigitalOcean App Platform (discovered with doctl), apply minor and patch dependency updates (and major updates of development and test gems such as RuboCop) in each local checkout starting from an up-to-date default branch, run its tests, commit, open a PR, apply feasible major upgrades in stacked PRs, and report the rest as suggestions in one pass, working on projects in parallel background tasks. Use when asked to update dependencies across DigitalOcean projects, to sweep projects for outdated dependencies, to update dependencies in one named project, or to verify App Platform deployments after merging dependency PRs.
---

# Update Dependencies

Sweep every project deployed on DigitalOcean in one pass: apply minor and patch updates in each local checkout, apply major updates of development and test gems where the project can absorb them, validate, commit, and open one PR per project; then evaluate the remaining major upgrades, apply the ones that are not too hard in stacked PRs on top, and suggest the rest. Explicit user limits override these defaults.

Do not merge PRs, deploy, or change anything on DigitalOcean. Follow the shared development instructions for branch naming, version verification, validation, commits, and PRs. Do not add changelog entries for dependency upgrades; this overrides the shared changelog instructions.

## Discover Projects

By default, sweep every project discovered from DigitalOcean. If the user names one project, as `owner/repo`, a repository name, a local path, or the current directory ("this project"), sweep only that project: still run the discovery below to find its deployed branch, then skip the rest. If it is not deployed on App Platform, say so and use its GitHub default branch (`gh repo view --json defaultBranchRef`). If a repository name matches more than one discovered repository or local checkout, ask which one.

Never hard-code the project list: it includes private repositories. Discover it with `doctl` every time, and do not write repository names into files, issues, or other external services; the final terminal report is the only place to list them. Public examples include `dblock/slack-strava`, `dblock/discord-strava`, and `dblock/posebook`.

1. Run `doctl auth list` and confirm a current context. If `doctl` is missing or unauthenticated, stop and ask the user to authenticate (`! doctl auth init`); never request tokens in chat.
2. Run `doctl apps list -o json`. For each app, read `spec.services`, `spec.workers`, `spec.jobs`, `spec.static_sites`, and `spec.functions`, and collect each component's `github` source with its `repo` and `branch`, along with the app `id` and component names for checking deployments. Deduplicate by repository; one app often has several components from the same repository, and one repository may back several apps.

## Locate Checkouts

Find each repository's local checkout by its remotes, as described under Repository Layout and Worktrees in [instructions.md](../../instructions.md). When the only match is a fork checkout, push the branch to the fork and open the PR against the upstream repository.

If a repository has no local checkout, list it and ask once, for all missing repositories together, whether to clone them to `~/source/<repo>/<branch>`, using the deployed branch name; skip them otherwise.

## Run in Parallel

Projects are independent, so do the per-project work in parallel on background tasks rather than one project at a time. With a single named project, do the work directly.

1. In the main session, finish everything that needs the user before fanning out: discovery, locating checkouts, and questions about missing checkouts or ambiguous names.
2. Install shared toolchains once, before fanning out, so parallel tasks do not race: look up the newest patch of each Ruby minor in use and `rvm install` any that are missing, along with the matching Bundler versions.
3. Start one background subagent per project, all in the same turn, with your agent tool's background mode. Give each one the repository, checkout path, deployed branch, and the path to this skill, and tell it to follow everything from Prepare Each Checkout through Stack Major Upgrades for that project only.
4. Subagents must not ask the user questions. When blocked, a subagent leaves its checkout in a safe state and returns the question in its report. Each one returns its part of the report: updates applied and held back, PR URLs with CI results, superseded bot PRs, abandoned attempts, suggestions, and skips.
5. Do not poll. Wait for completion notifications, and meanwhile only do work that does not touch the projects' checkouts. Each subagent waits for its own PRs' CI and fixes failures before it finishes.
6. Projects share a local MongoDB; most use their own database names. If two projects' test configurations use the same database name (`config/mongoid.yml`), run those two projects' tests one after the other instead of at the same time.
7. When every subagent has finished, ask any blocked questions together, then write the report.

## Prepare Each Checkout

1. Record the current branch so the user can return to it.
2. Run `git status --porcelain`. If the checkout has uncommitted or untracked changes, skip it and report why; never stash, reset, or discard work.
3. Run `git fetch --prune origin`.
4. Run `gh pr list --state open --json number,title,author,headRefName,files` and note open dependency-bot PRs (authors `app/dependabot` and `app/renovate`) and the updates each proposes. Many projects have `renovate.json`.
5. Resolve branches left by earlier sweeps, as described under Existing Branches.
6. Always start from an up-to-date default branch: switch to the deployed branch from the app spec and run `git pull --ff-only`. Projects use either `master` or `main`, so never assume one; `git switch <branch>` creates a tracking branch when only `origin/<branch>` exists. If the spec branch differs from the repository's GitHub default branch (`gh repo view --json defaultBranchRef`), use the spec branch and report the mismatch. If the local branch has diverged from `origin`, skip the checkout and report it; never reset or rebase it.
7. Create the topic branch from it: `git switch -c dblock/update-dependencies`, or the dated name chosen under Existing Branches.

### Existing Branches

Earlier sweeps leave `dblock/update-dependencies` and `dblock/upgrade-<name>-<major>` branches behind. Before creating any of these branches, check whether it exists locally (`git branch --list`) or on the remote (`git ls-remote --heads origin <branch>`), and find its PR with `gh pr list --head <branch> --state all --json number,state,headRefOid,mergedAt,mergeCommit`.

- If its PR merged on GitHub, the local branch tip (if any) equals the PR's `headRefOid` or is contained in the deployed branch, and no open PR uses the branch as its base, delete it: `git branch -D <branch>` locally and `git push origin --delete <branch>` if it is still on the remote. Rebase merges rewrite commits, so verify the merge through GitHub rather than `git branch --merged`. Then check the deployment of that merge as described under Verify Deployments, and reuse the branch name.
- If the merged branch has local commits that are not in the PR, or an open PR is based on it, leave it and report it.
- If the merged branch is checked out in a linked worktree (`git worktree list`), remove that worktree with `git worktree remove <path>` before deleting the branch, but only when it has no uncommitted or untracked changes; otherwise leave both and report them. Never remove the main checkout.
- If the branch has an open PR, no PR, or a closed unmerged PR, leave it untouched and use a dated name instead, such as `dblock/update-dependencies-2026-11-22` or `dblock/upgrade-faraday-3-2026-11-22`. If the dated name is taken too, add a numeric suffix (`-2`).

## Apply Minor and Patch Updates

Verify current releases from the registries (`gem info -r <gem>`, `gem search -r -e <gem>`, rubygems.org, GitHub releases) rather than remembered numbers, and exclude prereleases. Treat a change in the first version component as major; for `0.x` versions, also treat a change in the second component as major.

### Ruby Gems

1. Run `bundle outdated --parseable` before updating to record current and latest versions.
2. Run `bundle update --minor` to move gems to their newest minor and patch releases within each current major and the Gemfile constraints.
3. For Gemfile constraints that block a non-major update, such as `'~> 2.3.0'` or an exact pin, raise the constraint to the newest release within the same major, keeping the file's existing constraint style (for example `'~> 2.4.0'` or `'~> 2.4', '>= 2.4.1'`), and run `bundle update --minor <gem>`. Leave constraints that carry an explanatory comment, or are clearly deliberate, and report them as held back.
4. Run `bundle update --bundler` to update `BUNDLED WITH` within the current Bundler major, using a locally installed Bundler of that version.
5. Run `bundle outdated --parseable` again and confirm that only major updates (and held-back gems) remain.
6. Keep `Gemfile.lock` platforms unchanged, as described under Lockfile Platforms.

### Lockfile Platforms

App Platform builds on Linux, while sweeps run on an arm64 Mac, and Bundler may add the local platform or platform-specific gem variants while updating. Most lockfiles list only the `ruby` platform; some list explicit Linux, musl, and Darwin platforms.

1. Record the `PLATFORMS` section of `Gemfile.lock` before updating.
2. After every `bundle update` or `bundle lock`, compare `PLATFORMS` with the recorded list. Remove platforms that the update added with `bundle lock --remove-platform <platform>`, and never remove a platform that was already there.
3. Check that each native gem still resolves for every Linux platform the project deploys on: with only `ruby` listed, the lockfile must gain no platform-specific gem entries (`-arm64-darwin`, `-x86_64-linux`, and so on); with explicit Linux platforms listed, each native gem must keep entries for those platforms or have a `ruby` fallback. Fix anything else with `bundle lock --add-platform` or `--remove-platform`.
4. Mention platform changes, and why, in the PR description. For Dockerfile apps, rely on the CI Docker build where the project has one, and report when it does not.

### Development and Test Gems

Keep RuboCop and other development and test gems current, including major versions, since they do not ship to production. They are gems only in the `development` and `test` groups (`bundle outdated --group development`, `bundle outdated --group test`), such as `rubocop` and its plugins, `rspec`, `rack-test`, `webmock`, `vcr`, `fabrication`, `database_cleaner`, `capybara`, `selenium-webdriver`, and `guard`. Treat a gem that is also in a runtime group as a runtime gem. Never major-bump test helpers tied to a payment gem, such as `stripe-ruby-mock`; keep them on the newest minor compatible with the project's `stripe`, and suggest their majors together with it.

1. For each outdated development or test gem with a new major, raise its Gemfile constraint to the new major in the file's existing style and run `bundle update <gem>`. Update RuboCop together with its plugins (`rubocop-rspec`, `rubocop-rake`, `rubocop-performance`, and so on) so they stay compatible.
2. After a RuboCop update, run `bundle exec rubocop`. Fix new offenses with safe autocorrection (`bundle exec rubocop -a`) and small manual fixes, and resolve renamed or removed cops and plugins in `.rubocop.yml`. If the project keeps a `.rubocop_todo.yml`, regenerate it with `bundle exec rubocop --auto-gen-config` for offenses that need more than a small fix, as the project's AGENTS or CONTRIBUTING describes.
3. If a major update needs more than small, clear fixes to pass tests and lint, revert that gem (and its plugins) to the newest compatible minor and suggest the major with the failure, rather than retrying it in a stacked PR.

### Ruby Runtime

Ruby is declared in several places that must stay consistent: `.ruby-version`, the Gemfile `ruby` line, `ARG RUBY_VERSION` or `FROM ruby:` in a Dockerfile, CI workflow matrices, and `app.json`. Apply the newest patch release within the current Ruby minor to every declaration. Treat a new Ruby minor or major as a major upgrade, since it changes the runtime more than a gem update does.

Before changing Ruby, confirm the version is supported where the project deploys: the [App Platform Ruby buildpack](https://docs.digitalocean.com/products/app-platform/reference/buildpacks/ruby/) for buildpack apps, and the official `ruby` Docker image tag for Dockerfile apps. Install the version locally with `rvm install <version>` if needed, then reinstall gems with it.

### GitHub Actions and Other Manifests

- Update GitHub Actions pinned to exact versions (`@v1.2.3`) to the newest release within the same major. For SHA-pinned actions, update both the SHA and its version comment, resolving the SHA from the release tag. Leave floating major tags (`@v2`) and `@latest` as they are; suggest replacing `@latest` with a pinned version.
- Treat new action majors as major upgrades.
- If a project has other manifests, such as `package.json`, Docker base images, or service versions in CI (for example MongoDB), apply the same rule: update minor and patch versions, and treat majors as major upgrades.

## Validate

1. Read the project's AGENTS, CONTRIBUTING, and Rakefile for its test and lint commands; the default is usually `bundle exec rake` (RuboCop and RSpec).
2. Make sure required services are running, such as a local MongoDB for projects using Mongoid. If a service cannot be started, report the tests as not run rather than skipping them silently.
3. Run the tests and lint once after all updates, fixing RuboCop offenses as described under development and test gems, and rerun.
4. If an update breaks tests and the fix is not small and clear, revert that one dependency to its previous version, rerun the affected checks, and report it as held back with the failure.

## Commit and Open a PR

Commit and open a PR only for projects whose tests and lint pass locally, or whose checks could not run for a reported reason the user has accepted. Leave failing projects uncommitted on the topic branch and report them. If a project has no minor, patch, or development and test updates, delete its empty topic branch and start the major-upgrade stack from the deployed branch instead; if it has no feasible major upgrades either, switch back to the previous branch.

1. Commit everything as one commit, such as `Update dependencies`, with the AI co-author trailer.
2. Push with `git push -u origin <branch>` and open a PR against the deployed branch with `gh pr create --base <branch>`. In the description, disclose that the author is an AI acting on behalf of `@dblock`, and list the updates applied (current → new), held-back updates with reasons, and the actual local validation. Add `Supersedes #<number>` for each open bot PR it supersedes, as described below.
3. Wait for CI in the background (`gh pr checks <number> --watch`) while starting the major-upgrade stack, and fix failures on the PR's head. Do not merge.

### Superseded Bot PRs

In each PR, base or stacked, add one `Supersedes #<number>` line per open Dependabot or Renovate PR whose updates it fully covers, meaning it brings every dependency that bot PR changes to the same or a newer version. For a bot PR it covers only partly, write `Related to #<number>` instead. Dependabot and Renovate close their own PRs once the default branch has the update, so do not close bot PRs yourself.

## Stack Major Upgrades

After the base PR is open, evaluate every remaining major upgrade: runtime gems (`bundle outdated --filter-major`), Bundler, a Ruby minor or major, GitHub Actions, and majors in other manifests. Apply the ones that are not too hard in stacked PRs on top of the base PR, and suggest the rest.

### Evaluate

For each candidate, read the upstream changelog or upgrade guide, search the project for affected APIs and configuration, note deprecation warnings in the test output, and check compatibility: the gem's `required_ruby_version`, constraints from other gems that block resolution, and for Ruby, support on the App Platform buildpack or Docker image. An upgrade is not too hard when it:

- Resolves without forcing unrelated major upgrades.
- Needs changes in only a few call sites or configuration entries.
- Needs no data migration, change to stored data formats, new environment variables, or App Platform settings beyond the version declaration.
- Passes tests and lint after those changes.

Never attempt majors of payment gems such as `stripe`, whose majors pin a new API version and have proven difficult; always suggest them instead, with the evaluation. Majors of the web or data framework, such as Mongoid or Rails, are worth trying: evaluate them like any other major, and stack them after the smaller upgrades.

### Build the Stack

Follow the shared stacked-PR instructions. Order upgrades from easiest to hardest, one PR per upgrade, or per tightly coupled group such as a gem and its plugins or two gems whose majors require each other.

1. Branch each layer from the one below, resolving existing branches first as described under Existing Branches: `git switch -c dblock/upgrade-<name>-<major>` from the base PR branch or the previous layer, for example `dblock/upgrade-faraday-3` or `dblock/upgrade-ruby-4.1`.
2. Raise the constraint or version declaration, run `bundle update <gem>` (or the equivalent), fix the code, and run the full tests and lint.
3. If the fixes grow beyond the evaluation or tests fail without a clear fix, abandon the layer: switch back to the layer below, delete the unpushed branch, and move the upgrade to the suggestions with what was found. Continue with the next candidate.
4. Commit the layer as one commit, push it, and open a PR with `gh pr create --base <branch below>`. Describe only this layer: the upgrade (current → new), the upstream changelog link, the code changes and why, the actual local validation, `Supersedes #<number>` for each open bot PR it supersedes, and which PR it builds on.
5. Register the stack natively with `gh stack link --base <deployed branch> <base PR> <layer PRs...>`, and verify each PR with `gh api repos/<owner>/<repo>/pulls/<number> --jq .stack`. Report unsupported native stack operations rather than substituting a plain dependent-PR chain silently.
6. Wait for CI on each layer in the background and fix failures on that layer. If a fix changes a lower layer, rebase the layers above onto it and push each with `--force-with-lease=refs/heads/<branch>:<recorded-sha>`.

Finally, update the base PR description with links to the stacked PRs and the remaining suggestions. For each suggestion, give current and latest versions, the upstream changelog or upgrade guide link, and why it was judged too hard. Group upgrades shared by several projects (for example a common gem or Ruby version) so they can be planned once.

## Verify Deployments

Every app deploys on push to its deployed branch, so merging a sweep PR ships it to production. Verify deployments of merged sweep PRs, both when the user says they merged them or asks to verify deployments (run only this section then) and when Existing Branches finds an earlier sweep's merged PR.

1. Get the merge with `gh pr view <number> --json mergeCommit,mergedAt,baseRefName`, and the app IDs for the repository from discovery.
2. List deployments with `doctl apps list-deployments <app id> -o json`. Find the earliest deployment created after `mergedAt` whose `cause_details.git_push.commit_sha` is the merge commit or contains it (`git merge-base --is-ancestor <merge commit> <deployment commit>`), since one deployment can include several pushed commits.
3. Read its `phase`. `ACTIVE`, or `SUPERSEDED` by a later successful deployment that also contains the merge, means it deployed. If the phase is still in progress (pending, building, or deploying), wait in the background with a bounded check rather than polling in the foreground. If no deployment contains the merge, report that.
4. If the phase is `ERROR` or `CANCELED`, read the logs with `doctl apps logs <app id> <component> --type build --deployment <deployment id>`, and with `--type deploy` for deploy failures; summarize the cause. After an `ACTIVE` deployment, scan recent run logs (`doctl apps logs <app id> <component> --type run`) for boot errors or crash loops.
5. Never roll back, redeploy, or change the app. For a failure caused by the update, prepare a fix on a new branch and open a PR as in Commit and Open a PR, and tell the user right away, since production may be on the previous deployment or down.

## Report

When all background tasks have finished, end with a single report in the terminal, printing full URLs rather than Markdown links:

- A summary table with one row per project: checkout path, previous branch, branch used, number of minor and patch updates applied, local test and lint result, base PR URL and CI result, stacked major-upgrade PRs with CI results, held-back count, and major upgrades suggested.
- For each project: notable updates applied (current → new), held-back updates with reasons, overlapping open bot PRs, stacked PRs in order, abandoned major attempts with reasons, and suggested major upgrades.
- Grouped major-upgrade suggestions that apply to several projects.
- Existing branches deleted after merge, branches left in place with reasons, and dated branch names used.
- Deployment status for merged sweep PRs: deployed, in progress, or failed with the cause and any fix PR.
- Skipped projects and why: dirty checkout, diverged default branch, no updates, or missing checkout.
- Projects left uncommitted because checks failed, with `git -C <path> diff` to examine them.
