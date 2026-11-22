# Copilot CLI Instructions

These add to and take precedence over the shared instructions in `~/.copilot/copilot-instructions.md` when running as GitHub Copilot CLI.

- In AI-assisted commits, use the `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer. In AI-authored PR descriptions and issue/PR comments, disclose that the author is an AI (GitHub Copilot) acting on behalf of `@dblock`.
- Shared skills live in `~/source/dotfiles/agents/skills` and are linked into `~/.copilot/skills` by `scripts/setup.sh`. Run `/skills reload` after adding one. When a skill links to `instructions.md`, it means the shared instructions, which are already loaded.
