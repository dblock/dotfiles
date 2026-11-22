# Copilot Skills

Personal skills shared across projects.

| Skill | Purpose |
|---|---|
| [create-project](create-project/SKILL.md) | Create a Ruby gem or JavaScript package through implementation, validation, and a GitHub PR. |
| [update-dependencies](update-dependencies/SKILL.md) | Sweep DigitalOcean-deployed projects (or one named project) from an up-to-date default branch, open a PR per project with minor and patch dependency updates and major development and test gem updates, stack feasible major upgrades on top, and suggest the rest. |

Run [scripts/setup.sh](../../scripts/setup.sh) to symlink skill directories containing `SKILL.md` into `~/.copilot/skills`, preserving existing paths. Run `/skills reload` in Copilot CLI to load newly installed skills.
