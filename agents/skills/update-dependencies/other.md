# Updating Other Ecosystems

Specifics for the [update-dependencies](SKILL.md) sweep in ecosystems other than Ruby and JavaScript. For each, use the project's own wrapper or task runner where it has one (`./gradlew`, `./mvnw`, `make`, `just`), verify versions in the ecosystem's registry, and validate with the commands its AGENTS or CONTRIBUTING gives, defaulting to the ones below. Install missing toolchains before fanning out.

## Rust

- Record `cargo update --dry-run --verbose` (or `cargo outdated` where installed), then run `cargo update` for semver-compatible updates in `Cargo.lock`.
- Raise `Cargo.toml` requirements within the same major with `cargo upgrade` from `cargo-edit` where installed, otherwise by hand; remember that for `0.x` crates a new minor is a major.
- Keep `rust-version` (the MSRV) unless the project documents otherwise, and check that updated dependencies still build on it, for example with `cargo +<msrv> check`. Update `rust-toolchain.toml` pins within their minor.
- Validate with `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, and `cargo test`. Development dependencies are `[dev-dependencies]` and `[build-dependencies]` used only by tests and tooling.

## Python

- Use the project's tool: `uv lock --upgrade` and `uv sync` for `uv.lock`, `poetry update` for `poetry.lock`, `pip-compile --upgrade` for `requirements.in`, or `pip list --outdated` and hand edits for plain `requirements.txt` pins.
- Raise exact pins within their major. Keep `requires-python` unless the project documents otherwise.
- Development dependencies are dependency groups or extras such as `dev`, `test`, and `lint`, and `requirements-dev.txt`.
- Validate with the project's test runner, usually `pytest`, and linters such as `ruff`.

## Java and Kotlin

- Maven: record `./mvnw versions:display-dependency-updates versions:display-plugin-updates`, then update with `versions:use-latest-releases -DallowMajorUpdates=false` and `versions:update-properties -DallowMajorUpdates=false`.
- Gradle: update version catalogs (`gradle/libs.versions.toml`) or build files by hand, or with the `dependencyUpdates` task where the project applies the versions plugin; update the Gradle wrapper within its major with `./gradlew wrapper --gradle-version <version>`.
- Keep the Java release level (`maven.compiler.release`, toolchains) unless the project documents otherwise. Development dependencies are `test`-scoped dependencies and build plugins.
- Validate with `./mvnw verify` or `./gradlew check`.

## Elixir

- Record `mix hex.outdated`, run `mix deps.update --all` within the `mix.exs` requirements, and raise requirements within the same major.
- Development dependencies are those with `only: [:dev, :test]`, such as `credo` and `ex_doc`.
- Validate with `mix format --check-formatted`, `mix credo` where configured, and `mix test`.

## Go

- Record `go list -m -u all`, run `go get -u ./...` for minor and patch updates, then `go mod tidy`. A new major is a new module path (`/v2`), so it is always a major upgrade.
- Update the `go` and `toolchain` directives only within their minor unless the project documents otherwise.
- Validate with `go vet ./...` and `go test ./...`.

## Other Ecosystems

For ecosystems not listed here, such as .NET, CocoaPods, Swift Package Manager, or Composer, use the ecosystem's standard outdated and update commands to apply minor and patch updates within declared constraints. If there is no reliable standard tool, or the project cannot be built and tested locally, leave the ecosystem and report it as not covered rather than editing versions blindly.
