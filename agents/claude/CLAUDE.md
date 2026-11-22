# Claude Code Instructions

@~/source/dotfiles/agents/instructions.md

## Claude Code

These add to and take precedence over the shared instructions above when running as Claude Code.

- In AI-assisted commits, use the `Co-Authored-By: Claude <noreply@anthropic.com>` trailer. In AI-authored PR descriptions and issue/PR comments, disclose that the author is an AI (Claude) acting on behalf of `@dblock`.
- After pushing to a PR, wait for its GitHub CI in the background instead of reporting pending checks; this replaces the shared instruction to report pending checks without waiting. Run `gh pr checks <number> --watch` with `run_in_background`, keep working on independent tasks meanwhile, then report the final result for each pushed head and fix failures. Confirm the checks belong to the pushed head, since a watch can return results for an earlier head right after a force-push.
- Shared skills live in `~/source/dotfiles/agents/skills` and are linked into `~/.claude/skills` by `scripts/setup.sh`. When a skill links to `instructions.md`, it means the shared instructions above, which are already loaded.
