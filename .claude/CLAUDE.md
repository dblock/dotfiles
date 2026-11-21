# Claude Code Instructions

The shared development instructions are kept in one file used by both Copilot CLI and Claude Code:

@~/source/dotfiles/.copilot/copilot-instructions.md

## Claude-Specific Overrides

These take precedence over the shared instructions above when running as Claude Code.

- In AI-assisted commits, use `Co-Authored-By: Claude <noreply@anthropic.com>` instead of the Copilot co-author trailer. In AI-authored PR descriptions and issue/PR comments, still disclose that the author is an AI (Claude) acting on behalf of `@dblock`.
- The shared instructions refer to a `pr-stack` skill. If no such skill is installed, create and maintain stacks with `git` and `gh` directly, following the same rules, and say that the skill wasn't available.
- After pushing to a PR, wait for its GitHub CI in the background instead of reporting pending checks; this replaces the shared instruction to report pending checks without waiting. Run `gh pr checks <number> --watch` with `run_in_background`, keep working on independent tasks meanwhile, then report the final result for each pushed head and fix failures. Confirm the checks belong to the pushed head, since a watch can return results for an earlier head right after a force-push.
- Shared skills live in `~/source/dotfiles/.copilot/skills` and are linked into `~/.claude/skills` by `scripts/setup.sh`. When a skill links to `copilot-instructions.md`, it means the shared instructions above, which are already loaded.
