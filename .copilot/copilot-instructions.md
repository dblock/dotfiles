# Development Instructions

Apply these defaults across projects while respecting explicit user limits and existing project-specific requirements. Do not restructure an existing repository just to impose new-project defaults. Report conflicts rather than silently changing the requested workflow.

## Repository Layout and Worktrees

Default new main checkouts to `~/source/<repo>/master`, with sibling worktrees such as `~/source/<repo>/implementation`. The parent `~/source/<repo>/` is a container, not a Git checkout. Do not relocate existing checkouts without authorization.

Work on topic branches in the existing checkout by default. Name branches `<username>/<topic>`, using the GitHub login (`dblock` by default). Create branches with `git switch -c <username>/<topic> <base>`, using the intended base branch or prerequisite PR branch. Create separate worktrees only for parallel tasks, using an unused sibling path with `git worktree add -b <username>/<topic> <worktree-path> <base>`; never nest worktrees inside a checkout.

Inspect status, branches, and existing worktrees before switching. Preserve unrelated changes and never switch, overwrite, rebase, or force-push a checkout or branch used by another task. Resolve ownership conflicts with the user rather than discarding work or creating an unnecessary worktree.

## Pull Requests

When working on multiple changes or features, split them into small, focused PRs and stack them rather than combining them into one large PR. The bottom PR targets the intended base branch, and each higher PR branches from and targets the PR branch immediately below it. Implement, validate, commit, and push each lower layer before creating the next; each PR should describe and contain only its own layer's changes. Keep a single small independent change in one PR.

Use the `pr-stack` skill to create and maintain stacks, including native GitHub stack registration where available. Report unsupported native stack operations rather than silently substituting an ordinary dependent-PR chain. Preserve existing stacks and their complete membership after partial merges, and maintain the remaining base/head chain without replaying already-merged changes. Existing review and approval gates still apply; creating or maintaining a stack does not authorize merging it.

Always use rebase merges, regardless of a PR's commit count; do not select squash merges or merge commits. If rebase merging is unavailable, report the constraint rather than silently choosing another method. Keep task-owned PRs to one coherent commit of their own relative to their base, independently of the merge-method preference.

Use topic branches and PRs for development unless the user explicitly authorizes otherwise. Do not merge without an explicit request. Include `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` in AI-assisted commits. In AI-authored PR descriptions and issue/PR comments, disclose that the author is an AI acting on behalf of `@dblock`. Describe scope and actual validation, use closing issue references so PR merges close issues, and do not close implementation issues manually. Verify pushed refs, PR bases/heads, and available CI results; report pending checks honestly without waiting after successful local checks.

## Git Safety and Cleanup

Amend or squash commits on task-owned topic branches without asking for additional authorization to keep PR history coherent. Before rewriting, verify ownership, fetch and record the branch's remote tip, and reconcile remote changes. After validation, push with `--force-with-lease=refs/heads/<branch>:<recorded-sha>`; never plain `--force`, and never force-push `master` or the default branch. Do not rewrite another task's or contributor's work.

After PRs merge, fetch with pruning and verify merged state through GitHub rather than relying solely on `git branch --merged`. Inspect checkouts for uncommitted or untracked work and dependent stacked PRs. Safely switch away from merged branches to the default branch, remove only clean, no-longer-needed task-owned worktrees with `git worktree remove`, and delete their local branches. Use `git branch -D` only after verifying the PR merged and no unmerged work or dependent branches would be lost. Prune stale worktree metadata when applicable and verify cleanup. Never delete the default branch, active PR branches, or dirty worktrees; report blocked cleanup.

## Implementation and Dependencies

Prefer the simplest design that satisfies the agreed behavior and use supported public APIs rather than invented interfaces, dependency mutation, or unnecessary abstraction. Establish the host's real data structures and lifecycle before implementing integrations. Use ecosystem tooling without overwriting existing work.

When selecting or updating runtimes, dependencies, development tools, or GitHub Actions, verify current releases and prefer the latest stable versions; do not copy stale example versions or rely on remembered numbers. Choose older versions only for a documented compatibility requirement, and exclude prereleases unless requested. Keep package-runtime minimums separate from development/release-tool minimums and test both when applicable. Relaxed development-tool engine checks must not weaken real consumer compatibility checks.

## Validation

Run applicable local tests and lint before committing and every development push, including PR updates. Run final targeted checks once and reuse their results for the push if the tested content and configuration are unchanged; rerun affected checks after changes or failures rather than repeatedly running full suites. Include package validation when packaging or public entry points change. Fix failures and report checks that cannot run rather than pushing unverified changes. Documentation-only changes need only existing applicable documentation checks.

Add focused behavioral tests for introduced or fixed behavior, including meaningful errors and edge cases. Use real CLI subprocess and installed-consumer tests where relevant, not mocks alone. Inspect line and branch coverage when supported; do not inflate coverage with trivial assertions or exclude real runtime code. Report remaining gaps honestly.

For package validation, inspect and install the actual built archive in an owned temporary consumer, exercising public APIs/CLIs and workspace packages as applicable. Preserve pack-once validation when using a provided artifact; exercise artifact overrides provided, unset, and empty, treating empty optional paths consistently as unset. Clean up only artifacts created by the task.

## Documentation

Document actual behavior and current agreed design. Keep Markdown paragraphs on one source line. Use title case for human-readable Markdown headings and YAML workflow, job, and step display names, preserving proper names, acronyms, identifiers, expressions, and URLs.

Keep README focused on installation, minimal working usage, status badges, and documentation links. Separate Usage from Installation; put configuration options, defaults, and examples in Configuration after Usage when needed. Include Contributing links to the project's Markdown documentation except the license, then a License link. Keep project-specific details in CONTRIBUTING, DESIGN, CHANGELOG, and RELEASING where those documents apply.

Keep DESIGN focused on the current design and still-relevant rationale. Remove superseded proposals and implementation diaries; rely on Git history for obsolete details. In AGENTS and CONTRIBUTING, record actionable project-specific invariants and actual install/test/lint/package/coverage commands, not a one-time creation diary. Preserve editable artwork sources, provenance, licenses, and rendering instructions when artwork exists.

Include documentation checks in the normal lint command and CI. Use reviewed vocabulary in `.spellcheck.txt`, exclude intentionally invalid fixtures and generated/vendor files, and fix typos rather than broadly suppressing checks. Use narrowly scoped lint exceptions with concrete reasons.

## Changelogs and Versioning

Add changelog entries for features, improvements, and fixes, including meaningful tooling or documentation improvements; omit minor typos and the initial scaffold. Update an existing entry when appropriate rather than recording every unreleased implementation iteration. Follow the repository's established format; for new projects, use `# Changelog`, `## <version> (Next)`, and `- Your contribution here.`, with entries oldest to newest above the final placeholder. List release sections newest first as `## <version> (YYYY/MM/DD)`. Initial entries predating PRs go first without invented links.

Use linked entries such as `- [#123](https://github.com/<owner>/<repo>/pull/123): Description - [@author](https://github.com/author).` with actual attribution. Before opening a PR, query the latest repository issue or PR number and predict the next shared-sequence number for its entry; immediately verify the assigned number. Correct both label and URL if needed, validate affected checks, and update the task-owned PR using the guarded lease procedure. If prediction is unreliable, add the actual link after PR creation instead of fabricating one.

Before bumping a version, verify whether it has been published; ask if publication status cannot be established. Keep an unreleased version unchanged. For a released version, include the bump in the same PR: features increment minor, resetting patch for `0.x` and preserving patch for `1.x` and later; breaking changes in `0.x` increment minor and reset patch without requesting a major bump. Ask before selecting a major bump for breaking changes in `1.x` or later. Document breaking behavior and migration guidance, and synchronize version declarations, lockfiles, and the Next changelog heading.

## Continuous Integration

Keep GitHub Actions tests, lint, and package validation in separate `test.yml` (`Test`), `lint.yml` (`Lint`), and `package.yml` (`Package`) workflows rather than a generic `ci.yml`. Use least-privilege permissions, dependency caching, and relevant runtime/host compatibility and cross-platform checks.

Use one `matrix.entry` array of explicit combinations as compact inline YAML mappings, for example `- { ruby: '4.0', suite: unit }`, and reference `matrix.entry.ruby` and `matrix.entry.suite`. Do not use matrix `include`/`exclude` or separate axes generating unintended Cartesian products. Cover supported floors and current releases with a minimal useful matrix; verify versions rather than copying the example. Follow [rubocop-prose's matrix style](https://github.com/dblock/rubocop-prose/blob/main/.github/workflows/test.yml#L18).

Maintain configured coverage reporting and applicable Danger checks. Danger runs in PR CI, not as routine standalone local validation; verify its actual PR result and document the distinction.

## Release Safety

Publication, tags/releases, authentication, and trusted-publisher setup each require explicit authorization; documentation and implementation do not grant it. Never overwrite published versions or existing release tags, commit secrets, or request interactive authentication codes in chat. Authorized release automation may have explicitly documented direct-push exceptions; ordinary development still follows the PR workflow.

Validate release tooling with isolated Git remotes and simulated publication, not real registries. Verify and publish the exact validated artifact, then confirm registry state, remote refs, and matching tags/releases. Distinguish publication from delayed registry visibility; report verification limits honestly. Before recovery, inspect existing state and complete only missing steps without republishing or moving tags.
