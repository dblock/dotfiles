# macOS

Setup scripts for macOS, run after [setup.sh](../setup.sh).

## Scheduled Jobs

[schedule.sh](schedule.sh) installs the tools the jobs need with Homebrew (`jq`, `doctl`, `mongosh`, and `mongodb-database-tools`), links and loads every LaunchAgent in [LaunchAgents](LaunchAgents) and schedules a daily 4:55 wake with `sudo pmset repeat`, so jobs run while the Mac would otherwise sleep; launchd runs a job missed during sleep when the Mac wakes, so the wake also starts a Saturday sweep the Mac slept through. macOS keeps only one repeating wake schedule, so it replaces any other. Rerun it after adding or changing a LaunchAgent, or on a new Mac.

| LaunchAgent | Schedule | Log |
| --- | --- | --- |
| [com.dblock.cargo-clean-all](LaunchAgents/com.dblock.cargo-clean-all.plist) | Sundays at 3:00. | `~/Library/Logs/cargo-clean-all.log` |
| [com.dblock.mongodb-backup](LaunchAgents/com.dblock.mongodb-backup.plist) | Daily at 5:00, running [mongodb-backup](../../bash/bin/mongodb-backup) to back up MongoDB clusters to Dropbox, keeping 30 daily and all monthly snapshots. | `~/Library/Logs/mongodb-backup.log` |
| [com.dblock.update-dependencies](LaunchAgents/com.dblock.update-dependencies.plist) | Every other Saturday at 3:00. | `~/Library/Logs/update-dependencies.log` |

## Update Dependencies

[update-dependencies.sh](update-dependencies.sh) runs the [update-dependencies](../../agents/skills/update-dependencies/SKILL.md) skill unattended with Claude Code in auto permission mode, skipping off weeks, and writes each report to `~/Library/Logs/update-dependencies/<date>.md`, with the raw JSON output, including cost, next to it. Test it with `scripts/osx/update-dependencies.sh --dry-run`, which discovers projects and changes nothing, and run an off-week sweep with `--force`.

It uses the Claude Code login from the Keychain. If a scheduled run cannot authenticate, create a long-lived token with `claude setup-token` and provide it as `CLAUDE_CODE_OAUTH_TOKEN` outside this repository.

## MongoDB Backup

[mongodb-backup](../../bash/bin/mongodb-backup) backs up every database of each MongoDB cluster in the DigitalOcean account that `doctl` is authenticated to, into a directory named after the cluster under `~/Dropbox/Personal/DigitalOcean/mongo/backup`. It discovers clusters with `doctl databases list` on each run, so no connection details are stored in this repository or anywhere else. Each cluster directory keeps `daily/YYYY-MM-DD/<db>.dump.gz` for 30 days and `YYYY/<db>/YYYY-MM-<db>.dump.gz` with the last snapshot of each month. Restore a database with `mongorestore --uri=<uri> --gzip --archive=<file>`.

Credentials are a generic password in the login keychain, with the connection string `<host>/?tls=true&authSource=admin&replicaSet=<cluster name>` as its service and your user name as its account, storing `username:password`. Run `mongodb-backup` once from a terminal to be asked for them; the scheduled job fails rather than prompts when they are missing. Find them in Keychain Access by searching for the cluster host, view them with `security find-generic-password -s "<uri>" -w`, and delete them to be asked again with `security delete-generic-password -s "<uri>"`.

On a new Mac, authenticate `doctl` with `doctl auth init`, run `mongodb-backup` once from a terminal to store the credentials (the `doadmin` password is in the DigitalOcean console), and run [schedule.sh](schedule.sh).

When a job fails, it shows an alert that stays until dismissed, with an Open button for the backup error log or the sweep report; it gives up after 12 hours and is skipped when the job runs in a terminal. A finished sweep also posts a notification.
