#!/bin/bash
# Claude Code UserPromptSubmit hook: names a new session "<emoji> <name>" with the shared session-title
# script. Sessions that already have a title, from /rename or --name, are left alone.
#
# Environment:
#   SESSION_TITLE_SCRIPT  shared title script (default: agents/session-title/session-title.sh in these dotfiles)

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
shared="${SESSION_TITLE_SCRIPT:-$script_dir/../../../session-title/session-title.sh}"
export SESSION_TITLE_ASK="${SESSION_TITLE_ASK:-$script_dir/ask-haiku.sh}"

input="$(cat)"
[[ -n "$(jq -r '.session_title // empty' <<<"$input" 2>/dev/null)" ]] && exit 0
title="$(jq -c '{prompt, cwd}' <<<"$input" 2>/dev/null | "$shared")"
[[ -n "$title" ]] || exit 0

jq -n --arg title "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $title}}'
