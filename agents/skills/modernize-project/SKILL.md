---
name: modernize-project
description: Modernize stale Ruby gem repositories in stacked PRs — move Travis or broken CI to GitHub Actions on current Rubies, add documentation linting and clean up Markdown, speed up CI, update Danger, and update dependencies with the update-dependencies skill — working on several repositories in parallel background tasks. Use when asked to modernize, refresh, or revive one or more repositories, to bring a project's CI, docs, or tooling up to date, or to find which maintained projects need modernization.
---

# Modernize Project

Bring a repository that has not been touched in a while up to current conventions and current dependencies as a native GitHub stack of small PRs, one concern per PR, each with green CI. Explicit user limits override these defaults. Follow the shared development instructions in [instructions.md](../../instructions.md) for locating or cloning checkouts, branch naming, stacked PRs, changelogs, version verification, validation, commits, and PR text.

Do not merge, release, tag, bump a released version, configure trusted publishers, or raise `required_ruby_version`; report those as decisions for the user. Open regular PRs, not drafts, unless the repository's instructions say otherwise.

This skill is written for Ruby gems, where it has been exercised. For other ecosystems, apply the same layers with that ecosystem's tools and say what was adapted.

## Find Candidates

When asked which projects need modernization, list the non-archived, non-fork repositories the user can push to with `gh api graphql` (`viewer.repositories` with `ownerAffiliations: [OWNER, ORGANIZATION_MEMBER, COLLABORATOR]`). For stale ones, last pushed more than six months ago, collect stars, open issue and PR counts, whether `.github/workflows` or `.travis.yml` exists (`object(expression: "HEAD:<path>")`), and the latest release. Check real usage on RubyGems (`/api/v1/versions/<gem>.json` for the latest release date, `ruby_version`, and downloads) or npm (`api.npmjs.org/downloads/point/last-month/<package>`). Rank by usage rather than stars, and separately suggest archiving projects whose upstream service or framework is gone. Do not start modernizing until the user picks repositories.

## Run in Parallel

Repositories are independent, so start one background subagent per repository, all in the same turn. Give each one the repository name, known facts (current CI, services the tests need, open PR counts), and the path to this skill, and tell it to follow everything from Prepare through Report for that repository only. With one repository, do the work directly.

Subagents must not ask the user questions; when blocked, a subagent leaves its checkout in a safe state and returns the question in its report. Do not poll; wait for completion notifications. When all have finished, give one combined report with every PR URL, its stack, its CI result, and one consolidated list of decisions for the user.

## Prepare

1. Locate the checkout by its remotes, or clone it, per the shared instructions. Read `AGENTS.md`, `CONTRIBUTING.md`, and `RELEASING.md` if present.
2. Fetch, start from an up-to-date default branch, and check open PRs (including Dependabot and Renovate) and recent default-branch commits. Do not duplicate them; name overlaps and likely rebase conflicts in the PR bodies.
3. Verify current versions before writing any: stable Ruby releases, `actions/checkout`, `ruby/setup-ruby`, RuboCop and its plugins, and the latest `danger/danger-pr-comment` tag.
4. Run the existing suite on the oldest and newest Rubies you intend to test, to learn what is broken before changing anything.

## Stack

Build these layers in order, each on the branch below it, skipping layers that are already done. Never combine layers. Each PR is one commit with its own CHANGELOG entry, validated locally with `bundle exec rake` on the newest and oldest tested Rubies and with `actionlint` before pushing.

### 1. CI

Only when CI is Travis, missing, broken, or on stale Rubies or actions. Title it "Replace Travis CI with GitHub Actions" or "Test on current Rubies with current GitHub Actions".

- Add `test.yml` (`Test`) with a `matrix.entry` covering the oldest Ruby that still works (usually 2.7, or the gemspec's floor if higher) and current stable releases, plus JRuby where it was tested before and still passes. For gems with framework dependencies, pair each Ruby with a framework version through Gemfile environment variables, for example `{ ruby: '3.4', rails: '8.0' }`. For database-backed tests, prefer one workflow with one job per database service over one workflow per database.
- Use `permissions: contents: read` and `ruby/setup-ruby` with `bundler-cache: true`, and run `bundle exec rake spec` (or `test`) rather than `rake`, because an old pinned RuboCop usually cannot load on current Ruby.
- Remove `.travis.yml` and dead badges (Travis, Gemnasium, Code Climate), add an Actions badge, and update Travis mentions in CONTRIBUTING and RELEASING.
- Move development dependencies from the gemspec to the Gemfile and drop stale pins such as `rake < 11`, `rake ~> 12`, ancient RuboCop, and Rails 4.
- Fix real incompatibilities in focused ways. Common ones: gems no longer bundled with Ruby (`ostruct`, `logger`, `webrick`, `rackup`, `cgi`, `bigdecimal`, `base64`, `mutex_m`) need explicit Gemfile entries; `$CHILD_STATUS` needs `require 'English'`; frozen globals cannot be stubbed; Rack 3 breaks old HTTP stacks on old Rubies, so pin Rack below 3 for those Rubies only; RSpec 3.0 to 3.3 call `Rake.application.last_comment`, which Rake 11 removed.
- Check that tests actually exercise the gem: confirm that an integration test fails when the library's code is not loaded. Upstream frameworks change defaults (Grape stopped building `Hashie::Mash` params in 1.0), leaving tests that pass vacuously.

### 2. Docs Lint

Title it "Lint documentation and clean up Markdown". The model is [mongoid-geospatial#82](https://github.com/mongoid/mongoid-geospatial/pull/82); copy its concrete setup with `gh pr diff`.

- Add current RuboCop with `rubocop-md`, `rubocop-prose`, `rubocop-rake`, `rubocop-spellcheck`, and `rubocop-yaml`, installed only on MRI 3.3 and newer so older Rubies still run specs:

  ```ruby
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    # The other plugins, each with require: false.
  end
  ```

- In the Rakefile, define the `rubocop` and `lint` tasks only when the same condition holds and `Gem.loaded_specs.key?('rubocop')`, and make `default` run lint and specs where lint is available and specs otherwise.
- Replace `rubocop.yml` with `lint.yml` (`Lint`) running `bundle exec rake lint` on the newest Ruby, and set `TargetRubyVersion` to the oldest tested Ruby.
- Add reviewed vocabulary to `.spellcheck.txt`. Regenerate `.rubocop_todo.yml` so existing Ruby code is not restyled in this PR; fix only typos and examples that do not parse.
- Clean up README, CONTRIBUTING, and RELEASING per the shared documentation rules: title-case headings, one-line paragraphs, fenced code with languages, separate Installation, Usage, and Configuration sections, and links to the project's documentation.
- Exclude released CHANGELOG sections from layout checks. Danger rejects edits to released entries, so leave their spelling alone and add the word to `.spellcheck.txt` instead. Keep `LICENSE` text verbatim, and exclude deliberately invalid fixtures.
- Avoid backticks in headings when the repository runs `danger-toc`.

### 3. CI Performance

Title it "Speed up CI". The model is [mongoid-geospatial#83](https://github.com/mongoid/mongoid-geospatial/pull/83).

- Run `push` builds only on the default branch, so same-repository PR branches do not build twice.
- Add a per-workflow, per-ref `concurrency` group with `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`, so superseded PR runs are cancelled and default-branch runs never are.
- Set `timeout-minutes` on every job (10 is usually enough); jobs that call reusable workflows cannot take one.
- Test jobs run specs only, since lint runs once in `Lint`, and dependency caching is on.
- Confirm on the pushed PR that each workflow ran once, on `pull_request`.

### 4. Danger

Only when the repository uses Danger. Move `numbata/danger-pr-comment` or a hand-rolled comment workflow to the latest `danger/danger-pr-comment` release, update the gem, add the comment permissions it documents, set `base-branch: '*'` so stacked PRs get comments, and set `comment-empty: false` so pull requests without findings get no comment (an existing comment is still updated when its findings clear). The comment workflow runs from the default branch's copy, so it takes effect only after merge; say so in the PR. If the repository has no Danger, skip this layer and mention any open issue asking for it.

### 5. Dependencies

For Ruby projects, always finish the stack by running the [update-dependencies](../update-dependencies/SKILL.md) skill for this one repository, after the layers above are pushed, so updates are validated by the modernized CI. Follow it from Prepare Each Checkout through Stack Major Upgrades, with these adaptations:

- Branch `dblock/update-dependencies` from the top modernization layer rather than the default branch, open its PR against that layer, and stack its major-upgrade PRs above it, all in the same native stack. If no modernization layer was needed, start from the default branch as that skill describes.
- Skip DigitalOcean discovery and Verify Deployments unless the repository is deployed on App Platform; use the GitHub default branch where that skill says deployed branch.
- Development and test gems that the CI and docs lint layers already moved to current majors (RuboCop and its plugins) need no second update; update everything else, including GitHub Actions and service versions in CI.
- Gems that do not commit `Gemfile.lock` have nothing to lock: update stale Gemfile constraints, and for gemspec runtime dependencies, check whether the newest releases (including majors) pass the suite. Widening a runtime constraint to allow a new major is a layer of its own; narrowing one or raising its floor is a breaking change to report rather than make.
- Keep that skill's rules on superseded bot PRs (`Supersedes #<number>`), held-back updates, abandoned majors, and suggestions, and its rule of no changelog entries for dependency upgrades.

Include its results in the report: updates applied, held back, stacked majors, and suggestions.

## Push and Verify

1. Predict each PR's number from the latest issue or PR number. Registering a stack with `gh stack link` also consumes a number in the shared sequence, so create every PR before linking, and correct any mispredicted CHANGELOG link with a lease-guarded force push.
2. Push each layer and open its PR against the layer below. Run `gh pr checks <number> --watch` in the background and fix failures until the final head is green. CI often surfaces resolver differences that local runs miss, for example newer RuboCop allowing `json` 3, which breaks old ActiveSupport; pin narrowly, with a comment, for the affected combination only.
3. Register the stack with `gh stack link --base <default-branch> <bottom> ... <top>` and verify each PR with `gh api repos/<owner>/<repo>/pulls/<number> --jq .stack`.
4. Leave the checkout clean and remove scratch files.

## Report

For each repository, report a table of PR URL, title, base, and CI result on the final head; the stack URL; what each layer changed in a few bullets, including real bugs found; dependency updates applied and held back, and suggested major upgrades, grouped across repositories when shared; layers skipped and why; and overlaps with open PRs. End with decisions for the user, typically the Ruby floor (`required_ruby_version` against the oldest tested Ruby), dependency floors CI proved too low, gemspec MFA metadata, packaging bugs noticed out of scope, and whether to release unreleased fixes.
