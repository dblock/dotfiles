#!/bin/bash
# Runs the update-dependencies skill unattended with Claude Code, every other week, from
# LaunchAgents/com.dblock.update-dependencies.plist. Reports go to ~/Library/Logs/update-dependencies.
#
# Usage: update-dependencies.sh [--force] [--dry-run]
#   --force    Run even in an off week.
#   --dry-run  Discover projects and locate checkouts only, changing nothing (implies --force).

set -euo pipefail

force=false
dry_run=false
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    --dry-run) dry_run=true; force=true ;;
    *) echo "Unknown option: $arg." >&2; exit 2 ;;
  esac
done

# Run every other week: count whole weeks since the Unix epoch, which, unlike ISO week numbers, alternate across
# years with 53 weeks.
week=$(( $(date +%s) / 604800 ))
if ! $force && (( week % 2 != 0 )); then
  echo "$(date '+%F %T'): Skipping off week."
  exit 0
fi

log_dir="$HOME/Library/Logs/update-dependencies"
mkdir -p "$log_dir"
# Allow one sweep at a time; a lock left by a process that is no longer running is stale.
lock="$log_dir/.lock"
if [[ -f "$lock" ]] && kill -0 "$(cat "$lock")" 2>/dev/null; then
  echo "$(date '+%F %T'): Another sweep is running as process $(cat "$lock")." >&2
  exit 1
fi
echo $$ > "$lock"
trap 'rm -f "$lock"' EXIT

# Shows an alert that stays until dismissed, with a button to open a file, unless running in a terminal, which shows
# the error already. It gives up after 12 hours, so a scheduled job never waits for its next run.
alert() {
  local title="$1" message="$2" file="$3"
  [[ -t 2 ]] && return 0
  osascript -e 'on run argv' \
    -e 'set answer to display alert (item 1 of argv) message (item 2 of argv) as critical buttons {"Dismiss", "Open"} default button "Open" giving up after 43200' \
    -e 'if button returned of answer is "Open" then do shell script "open " & quoted form of (item 3 of argv)' \
    -e 'end run' "$title" "$message" "$file" > /dev/null 2>&1 || true
}

notify() {
  osascript -e "display notification \"$2\" with title \"$1\"" > /dev/null 2>&1 || true
}

claude_bin="$(command -v claude || echo "$HOME/.local/bin/claude")"

# Use the Claude subscription login, never an API key that happens to be in the environment.
unset ANTHROPIC_API_KEY
# Headless runs wait for background subagents only 10 idle minutes by default; a sweep takes hours. Long test runs
# that exceed the Bash timeout move to the background, which can end a headless run early.
export CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS="${CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS:-28800000}"
export BASH_DEFAULT_TIMEOUT_MS="${BASH_DEFAULT_TIMEOUT_MS:-600000}"

if $dry_run; then
  report="$log_dir/$(date +%F)-dry-run.md"
  prompt="/update-dependencies Dry run, unattended: nobody can answer questions. Do only Discover Projects and Locate Checkouts, change nothing in any checkout or on GitHub, and report the active, dormant, and inactive counts, the active projects with their checkout paths, and the missing checkouts."
else
  report="$log_dir/$(date +%F).md"
  prompt="/update-dependencies Unattended scheduled run: nobody can answer questions. Sweep active projects only; do not ask about dormant projects, missing checkouts, or authentication, and list them in the report instead. If doctl is not authenticated, continue without App Platform data. Wait for every background subagent and CI watch to finish before writing the final report."
fi

echo "$(date '+%F %T'): Starting sweep, writing $report."
# Version managers loaded by the login shell, such as gvm, redefine cd.
builtin cd "$HOME/source"
status=0
json="${report%.md}.json"
# Auto mode approves routine actions with a safety classifier, and denies, rather than prompts for, anything else.
caffeinate -i "$claude_bin" -p "$prompt" --permission-mode auto --permission-prompts none --output-format json \
  > "$json" || status=$?
jq -r '.result // empty' "$json" > "$report" 2>/dev/null || true
cost="$(jq -r '.total_cost_usd // empty' "$json" 2>/dev/null || true)"
echo "$(date '+%F %T'): Sweep finished with status $status${cost:+, cost \$$cost}."

if (( status == 0 )); then
  notify update-dependencies "Sweep finished${cost:+, cost \$$cost}; report in $report."
else
  alert "Dependency sweep failed" "The sweep exited with status $status." "$report"
fi
exit "$status"
