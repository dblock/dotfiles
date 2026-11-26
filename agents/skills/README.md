# Skills

Shared skills loaded by Claude Code and GitHub Copilot CLI; see [Agents](../README.md) for how they are linked.

| Skill | Purpose |
| --- | --- |
| [create-project](create-project/SKILL.md) | Create a Ruby gem or JavaScript package through implementation, validation, and a GitHub PR. |
| [explain-with-video](explain-with-video/SKILL.md) | Make a narrated explainer video of a repository or pull request; vendored from [marekkirejczyk/skills](https://github.com/marekkirejczyk/skills), see its [README](explain-with-video/README.md). |
| [github-images](github-images/SKILL.md) | Upload screenshots and other images to GitHub from the terminal and embed them in PR and issue descriptions and comments. |
| [modernize-project](modernize-project/SKILL.md) | Find stale maintained Ruby and JavaScript projects and modernize them in parallel as stacked PRs: GitHub Actions CI on current runtimes, documentation linting, faster CI, current Danger, and dependency updates through update-dependencies, with ecosystem guides in [ruby.md](modernize-project/ruby.md) and [javascript.md](modernize-project/javascript.md). |
| [update-dependencies](update-dependencies/SKILL.md) | Sweep active projects (writable repositories with recent activity, DigitalOcean-deployed apps, and an include list, minus an exclude list in [projects.yml](update-dependencies/projects.yml)), or one named project, from an up-to-date default branch: open a PR per project with minor and patch updates and major development and test dependency updates in every ecosystem, stack feasible major upgrades on top, and suggest the rest, with ecosystem guides in [ruby.md](update-dependencies/ruby.md), [javascript.md](update-dependencies/javascript.md), and [other.md](update-dependencies/other.md). |

To add a skill, create `<name>/SKILL.md` in this folder and run [scripts/setup.sh](../../scripts/setup.sh). Run `/skills reload` in Copilot CLI to load it; Claude Code picks it up in new sessions.
