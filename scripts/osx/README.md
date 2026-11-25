# macOS

Setup scripts for macOS, run after [setup.sh](../setup.sh).

## Scheduled Jobs

[schedule.sh](schedule.sh) links and loads every LaunchAgent in [LaunchAgents](LaunchAgents) and schedules the Saturday wake they need with `sudo pmset repeat`; macOS keeps only one repeating wake schedule, so it replaces any other. Rerun it after adding or changing a LaunchAgent, or on a new Mac.

| LaunchAgent | Schedule | Log |
|---|---|---|
| [com.dblock.cargo-clean-all](LaunchAgents/com.dblock.cargo-clean-all.plist) | Sundays at 3:00. | `~/Library/Logs/cargo-clean-all.log` |
| [com.dblock.mongodb-backup](LaunchAgents/com.dblock.mongodb-backup.plist) | Daily at 21:00. | `~/Library/Logs/mongodb-backup.log` |
| [com.dblock.update-dependencies](LaunchAgents/com.dblock.update-dependencies.plist) | Every other Saturday at 3:00. | `~/Library/Logs/update-dependencies.log` |

## Update Dependencies

[update-dependencies.sh](update-dependencies.sh) runs the [update-dependencies](../../agents/skills/update-dependencies/SKILL.md) skill unattended with Claude Code in auto permission mode, skipping off weeks, and writes each report to `~/Library/Logs/update-dependencies/<date>.md`, with the raw JSON output, including cost, next to it. Test it with `scripts/osx/update-dependencies.sh --dry-run`, which discovers projects and changes nothing, and run an off-week sweep with `--force`.

It uses the Claude Code login from the Keychain. If a scheduled run cannot authenticate, create a long-lived token with `claude setup-token` and provide it as `CLAUDE_CODE_OAUTH_TOKEN` outside this repository.
