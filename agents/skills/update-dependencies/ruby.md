# Updating Ruby Dependencies

Ruby and Bundler specifics for the [update-dependencies](SKILL.md) sweep. Verify versions with `gem info -r <gem>`, `gem search -r -e <gem>`, rubygems.org, and GitHub releases. Validate with `bundle exec rake` (usually RuboCop and RSpec) unless the project documents otherwise, running under the project's Ruby, for example `rvm <version> do bundle exec rake`, since the shell's default Ruby may differ from `.ruby-version`.

## Toolchain

Before fanning out, look up the newest patch of each Ruby minor in use and `rvm install` any that are missing, along with the matching Bundler versions.

## Minor and Patch Updates

1. Run `bundle outdated --parseable` before updating to record current and latest versions.
2. Run `bundle update --minor` to move gems to their newest minor and patch releases within each current major and the Gemfile constraints.
3. For Gemfile constraints that block a non-major update, raise the constraint to the newest release within the same major, keeping the file's existing constraint style (for example `'~> 2.4.0'` or `'~> 2.4', '>= 2.4.1'`), and run `bundle update --minor <gem>`.
4. Run `bundle update --bundler` to update `BUNDLED WITH` within the current Bundler major, using a locally installed Bundler of that version.
5. Run `bundle outdated --parseable` again and confirm that only major updates (and held-back gems) remain.
6. Keep `Gemfile.lock` platforms unchanged, as described under Lockfile Platforms.

Gems that do not commit `Gemfile.lock` have nothing to lock: update stale Gemfile constraints, and treat gemspec runtime dependencies as library ranges, as the skill describes under Applications and Libraries.

## Lockfile Platforms

App Platform builds on Linux, while sweeps run on an arm64 Mac, and Bundler may add the local platform or platform-specific gem variants while updating. Most lockfiles list only the `ruby` platform; some list explicit Linux, musl, and Darwin platforms.

1. Record the `PLATFORMS` section of `Gemfile.lock` before updating.
2. After every `bundle update` or `bundle lock`, compare `PLATFORMS` with the recorded list. Remove platforms that the update added with `bundle lock --remove-platform <platform>`, and never remove a platform that was already there.
3. Check that each native gem still resolves for every Linux platform the project deploys on: with only `ruby` listed, the lockfile must gain no platform-specific gem entries (`-arm64-darwin`, `-x86_64-linux`, and so on); with explicit Linux platforms listed, each native gem must keep entries for those platforms or have a `ruby` fallback. Fix anything else with `bundle lock --add-platform` or `--remove-platform`.
4. Mention platform changes, and why, in the PR description. For Dockerfile apps, rely on the CI Docker build where the project has one, and report when it does not.

## Development and Test Gems

Development and test gems are those only in the `development` and `test` groups (`bundle outdated --group development`, `bundle outdated --group test`), such as `rubocop` and its plugins, `rspec`, `rack-test`, `webmock`, `vcr`, `fabrication`, `database_cleaner`, `capybara`, `selenium-webdriver`, and `guard`. Never major-bump test helpers tied to a payment gem, such as `stripe-ruby-mock`; keep them on the newest minor compatible with the project's `stripe`, and suggest their majors together with it.

- Raise a development gem's constraint to its new major and run `bundle update <gem>`. Update RuboCop together with its plugins (`rubocop-rspec`, `rubocop-rake`, `rubocop-performance`, and so on).
- After a RuboCop update, run `bundle exec rubocop`, fix new offenses with `bundle exec rubocop -a` and small manual fixes, and resolve renamed or removed cops and plugins in `.rubocop.yml`. If the project keeps a `.rubocop_todo.yml`, regenerate it with `bundle exec rubocop --auto-gen-config` for offenses that need more than a small fix, as the project's AGENTS or CONTRIBUTING describes.

## Ruby Runtime

Ruby is declared in `.ruby-version`, the Gemfile `ruby` line, `ARG RUBY_VERSION` or `FROM ruby:` in a Dockerfile, CI workflow matrices, and `app.json`. Confirm a new version against the [App Platform Ruby buildpack](https://docs.digitalocean.com/products/app-platform/reference/buildpacks/ruby/) for buildpack apps and the official `ruby` Docker image tag for Dockerfile apps. Install it locally with `rvm install <version>` if needed, then reinstall gems with it.

## Major Upgrades

Find runtime majors with `bundle outdated --filter-major`, raise the constraint, and run `bundle update <gem>`. Majors of `stripe` are always suggestions, as the skill describes.
