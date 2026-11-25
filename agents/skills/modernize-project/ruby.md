# Modernizing Ruby Gems

Ruby specifics for each layer of the [modernize-project](SKILL.md) stack. Validate each layer with `bundle exec rake` on the newest and oldest tested Rubies.

## Prepare

Verify the current stable Ruby releases, `ruby/setup-ruby`, and RuboCop and its plugins.

## 1. CI

- Cover the oldest Ruby that still works (usually 2.7, or the gemspec's floor if higher) and current stable releases, plus JRuby where it was tested before and still passes. For gems with framework dependencies, pair each Ruby with a framework version through Gemfile environment variables, for example `{ ruby: '3.4', rails: '8.0' }`. For database-backed tests, prefer one workflow with one job per database service over one workflow per database.
- Use `ruby/setup-ruby` with `bundler-cache: true`, and run `bundle exec rake spec` (or `test`) rather than `rake`, because an old pinned RuboCop usually cannot load on current Ruby.
- Remove `.travis.yml` and dead badges (Travis, Gemnasium, Code Climate).
- Move development dependencies from the gemspec to the Gemfile and drop stale pins such as `rake < 11`, `rake ~> 12`, ancient RuboCop, and Rails 4.
- Common incompatibilities: gems no longer bundled with Ruby (`ostruct`, `logger`, `webrick`, `rackup`, `cgi`, `bigdecimal`, `base64`, `mutex_m`) need explicit Gemfile entries; `$CHILD_STATUS` needs `require 'English'`; frozen globals cannot be stubbed; Rack 3 breaks old HTTP stacks on old Rubies, so pin Rack below 3 for those Rubies only; RSpec 3.0 to 3.3 call `Rake.application.last_comment`, which Rake 11 removed.
- Upstream defaults that make tests vacuous: Grape stopped building `Hashie::Mash` params in 1.0.

## 2. Docs Lint

The model is [mongoid-geospatial#82](https://github.com/mongoid/mongoid-geospatial/pull/82); copy its concrete setup with `gh pr diff`.

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
- Regenerate `.rubocop_todo.yml` so existing Ruby code is not restyled in this PR; fix only typos and examples that do not parse.
- Exclude released CHANGELOG sections from layout checks, since Danger rejects edits to released entries.

## 5. Dependencies

- Gems that do not commit `Gemfile.lock` have nothing to lock: update stale Gemfile constraints, and for gemspec runtime dependencies, check whether the newest releases (including majors) pass the suite. Widening a runtime constraint to allow a new major is a layer of its own; narrowing one or raising its floor is a breaking change to report rather than make.
- RuboCop and its plugins were already moved to current majors in the docs lint layer.
- Newer RuboCop can allow `json` 3, which breaks old ActiveSupport; pin it narrowly, with a comment, for the affected Ruby and Rails combination only.

## Decisions

Typical decisions for the user: `required_ruby_version` against the oldest tested Ruby, and gemspec MFA metadata (`rubygems_mfa_required`).
