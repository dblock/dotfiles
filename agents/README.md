# Agents

Instructions and skills shared by Claude Code and GitHub Copilot CLI. Each tool loads the same shared instructions and skills, plus a small file of its own overrides.

| File | Purpose | Linked as |
|---|---|---|
| [instructions.md](instructions.md) | Shared development instructions. | `~/.copilot/copilot-instructions.md`; imported by `CLAUDE.md` |
| [claude/CLAUDE.md](claude/CLAUDE.md) | Imports the shared instructions and adds Claude Code overrides. | `~/.claude/CLAUDE.md` |
| [claude/settings.json](claude/settings.json) | Claude Code settings. | `~/.claude/settings.json` |
| [copilot/copilot.instructions.md](copilot/copilot.instructions.md) | Copilot CLI overrides, loaded after the shared instructions. | `~/.copilot/instructions/copilot.instructions.md` |
| [skills](skills) | Shared skills. | `~/.claude/skills/<name>` and `~/.copilot/skills/<name>` |
| [skills/update-dependencies/projects.yml](skills/update-dependencies/projects.yml) | Public include and exclude lists for update-dependencies; private entries go in an untracked `projects.local.yml` next to the link. | `~/.config/update-dependencies/projects.yml` |

Keep `instructions.md` tool-neutral and put tool-specific behavior, such as co-author trailers, in the tool's overrides file. The shared file is not named `AGENTS.md`, because Copilot CLI loads `AGENTS.md` files under the working directory as repository instructions and would load it twice while working in this repository.

## Skills

| Skill | Purpose |
|---|---|
| [create-project](skills/create-project/SKILL.md) | Create a Ruby gem or JavaScript package through implementation, validation, and a GitHub PR. |
| [github-images](skills/github-images/SKILL.md) | Upload screenshots and other images to GitHub from the terminal and embed them in PR and issue descriptions and comments. |
| [modernize-project](skills/modernize-project/SKILL.md) | Find stale maintained Ruby and JavaScript projects and modernize them in parallel as stacked PRs: GitHub Actions CI on current runtimes, documentation linting, faster CI, current Danger, and dependency updates through update-dependencies, with ecosystem guides in [ruby.md](skills/modernize-project/ruby.md) and [javascript.md](skills/modernize-project/javascript.md). |
| [update-dependencies](skills/update-dependencies/SKILL.md) | Sweep active projects (writable repositories with recent activity, DigitalOcean-deployed apps, and an include list, minus an exclude list in [projects.yml](skills/update-dependencies/projects.yml)), or one named project, from an up-to-date default branch: open a PR per project with minor and patch updates and major development and test dependency updates in every ecosystem, stack feasible major upgrades on top, and suggest the rest, with ecosystem guides in [ruby.md](skills/update-dependencies/ruby.md), [javascript.md](skills/update-dependencies/javascript.md), and [other.md](skills/update-dependencies/other.md). |

To add a skill, create `skills/<name>/SKILL.md` and run [scripts/setup.sh](../scripts/setup.sh). Run `/skills reload` in Copilot CLI to load it; Claude Code picks it up in new sessions.

## Setup

[scripts/setup.sh](../scripts/setup.sh) creates the links above. It re-points links that already point into this repository, so moved files are picked up, and leaves other existing files alone. Check what each tool loads with `copilot instruction list` and `/memory` in Claude Code.
