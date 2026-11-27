#!/bin/bash
# Answers the question on stdin with Claude Haiku through Copilot CLI. It runs in a throwaway Copilot home with no
# tools, so no hooks, instructions, or MCP servers load and no session is saved; sign-in comes from the keychain.
#
# Environment overrides:
#   SESSION_TITLE_COPILOT_MODEL  model to ask (default: claude-haiku-4.5)
set -uo pipefail

question="$(cat)"
home="$(mktemp -d)" || exit 1
trap 'rm -rf "$home"' EXIT
COPILOT_HOME="$home" copilot -p "$question" -s --model "${SESSION_TITLE_COPILOT_MODEL:-claude-haiku-4.5}" \
  --available-tools "" --no-custom-instructions --disable-builtin-mcps --no-auto-update
