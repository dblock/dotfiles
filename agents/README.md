# Agents

Instructions and skills shared by Claude Code and GitHub Copilot CLI. Each tool loads the same shared instructions and skills, plus a small file of its own overrides.

| File | Purpose | Linked as |
| --- | --- | --- |
| [instructions.md](instructions.md) | Shared development instructions. | `~/.copilot/copilot-instructions.md`; imported by `CLAUDE.md` |
| [claude/CLAUDE.md](claude/CLAUDE.md) | Imports the shared instructions and adds Claude Code overrides. | `~/.claude/CLAUDE.md` |
| [claude/settings.json](claude/settings.json) | Claude Code settings. | `~/.claude/settings.json` |
| [claude/hooks](claude/hooks/README.md) | Claude Code hooks, one folder each, registered in the settings. | `~/.claude/hooks` |
| [copilot/copilot.instructions.md](copilot/copilot.instructions.md) | Copilot CLI overrides, loaded after the shared instructions. | `~/.copilot/instructions/copilot.instructions.md` |
| [skills](skills/README.md) | Shared skills. | `~/.claude/skills/<name>` and `~/.copilot/skills/<name>` |
| [skills/update-dependencies/projects.yml](skills/update-dependencies/projects.yml) | Public include and exclude lists for update-dependencies; private entries go in an untracked `projects.local.yml` next to the link. | `~/.config/update-dependencies/projects.yml` |

Keep `instructions.md` tool-neutral and put tool-specific behavior, such as co-author trailers, in the tool's overrides file. The shared file is not named `AGENTS.md`, because Copilot CLI loads `AGENTS.md` files under the working directory as repository instructions and would load it twice while working in this repository.

## Hooks

See [Hooks](claude/hooks/README.md) for how to add a Claude Code hook.

## Session Names

Both tools name new sessions with the [agent-baby-names](https://github.com/dblock/agent-baby-names) plugin. Its Copilot CLI hook asks the agent to call `rename_session`, so setup enables the session tools when Copilot CLI is installed, limiting session access to the current Copilot process. To enable them without running setup, use:

```sh
copilot config sessionManagementTools.scope in-process
copilot config sessionManagementTools.enabled on
```

## Skills

See [Skills](skills/README.md) for the shared skills and how to add one.

## Setup

[scripts/setup.sh](../scripts/setup.sh) creates the links above. It re-points links that already point into this repository, so moved files are picked up, and leaves other existing files alone. Check what each tool loads with `copilot instruction list` and `/memory` in Claude Code.
