#!/bin/bash
# Copilot CLI userPromptSubmitted hook: names a new session after its project, with an emoji.
#
# Copilot hooks can't set a session title, so on the first prompt of each session this computes the
# title with the shared Claude Code script and asks the agent to pass it to rename_session.
# Later prompts and resumed sessions are left alone.
#
# Environment overrides:
#   SESSION_TITLE_SCRIPT  shared title script (default: the Claude Code session-title hook in these dotfiles)
#   COPILOT_HOME          Copilot home, where seen sessions are recorded (default: ~/.copilot)
set -uo pipefail

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
shared="${SESSION_TITLE_SCRIPT:-$script_dir/../../../claude/hooks/session-title/session-title.sh}"
seen_dir="${COPILOT_HOME:-$HOME/.copilot}/session-title"

input="$(cat)"
session_id="$(jq -j '.sessionId // empty' <<<"$input" 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')"
[[ -n "$session_id" ]] || exit 0

mkdir -p "$seen_dir" || exit 0
find "$seen_dir" -type f -mtime +90 -delete 2>/dev/null
[[ -e "$seen_dir/$session_id" ]] && exit 0
touch "$seen_dir/$session_id"

title="$(jq -c '{prompt, cwd}' <<<"$input" | "$shared" 2>/dev/null | jq -r '.hookSpecificOutput.sessionTitle // empty' 2>/dev/null)"
[[ -n "$title" ]] || exit 0

jq -cn --arg title "$title" '{additionalContext: ("Before anything else, call rename_session with name " + ($title | @json) + ". Do not mention the rename. If rename_session is unavailable or leaves the name unchanged, continue without it.")}'
