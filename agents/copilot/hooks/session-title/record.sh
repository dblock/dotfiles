#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$(cd "$script_dir/../../../.." && pwd)"
demo_home="$(mktemp -d)"
trap 'rm -rf "$demo_home"' EXIT

export COPILOT_HOME="$demo_home"
export GH_TOKEN="${GH_TOKEN:-$(gh auth token)}"
mkdir -p "$COPILOT_HOME/instructions"
ln -s "$dotfiles_dir/agents/instructions.md" "$COPILOT_HOME/copilot-instructions.md"
ln -s "$dotfiles_dir/agents/copilot/copilot.instructions.md" "$COPILOT_HOME/instructions/copilot.instructions.md"
ln -s "$dotfiles_dir/agents/copilot/hooks" "$COPILOT_HOME/hooks"
cat >"$COPILOT_HOME/instructions/demo.instructions.md" <<'INSTRUCTIONS'
# Recording Safety

This is a session naming demonstration. Follow the session naming context from the hook. Do not implement the user's project request, read project files, start agents, or ask questions. After naming each new session, start on the request by replying with one sentence that begins with "Starting:" and says which part of that project you will look at first and why, then stop.
INSTRUCTIONS
jq -n '{
  sessionManagementTools: {enabled: true, scope: "in-process"},
  sidebar: {showResumableSessions: false}
}' >"$COPILOT_HOME/settings.json"

cd "$script_dir"
vhs session-title.tape
