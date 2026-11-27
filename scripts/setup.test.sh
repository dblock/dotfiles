#!/bin/bash
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home"
export COPILOT_HOME="$HOME/.copilot"
export PATH="$tmp/bin:$PATH"
mkdir -p "$tmp/bin" "$COPILOT_HOME"
touch "$HOME/.bashrc"
printf '#!/bin/bash\nexit 1\n' >"$tmp/bin/copilot"
chmod +x "$tmp/bin/copilot"
settings="$COPILOT_HOME/settings.json"
jq -n '{theme: "light", sessionManagementTools: {create: false}}' >"$settings"

bash "$dotfiles_dir/scripts/setup.sh" >/dev/null
jq -e '.theme == "light" and .sessionManagementTools == {
  create: false, scope: "in-process", enabled: true
}' "$settings" >/dev/null
[[ "$(readlink "$HOME/.copilot/instructions/copilot.instructions.md")" == \
  "$dotfiles_dir/agents/copilot/copilot.instructions.md" ]]
[[ "$(readlink "$HOME/.claude/hooks")" == "$dotfiles_dir/agents/claude/hooks" ]]
echo "ok - setup enables the Copilot session tools and preserves unrelated settings"

first="$(cat "$settings")"
bash "$dotfiles_dir/scripts/setup.sh" >/dev/null
[[ "$(cat "$settings")" == "$first" ]]
echo "ok - repeated setup is idempotent"

rm "$settings"
bash "$dotfiles_dir/scripts/setup.sh" >/dev/null
jq -e '.sessionManagementTools == {scope: "in-process", enabled: true}' "$settings" >/dev/null
echo "ok - setup creates missing Copilot settings"
